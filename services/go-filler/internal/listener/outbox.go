package listener

//nolint:cognitive-complexity,cyclomatic
import (
	"context"
	"encoding/binary"
	"errors"
	"fmt"
	"math/big"
	"sync"

	"github.com/base-org/RRC-7755-poc/bindings/entrypoint"
	"github.com/base-org/RRC-7755-poc/bindings/rrc_7755_inbox"
	"github.com/base-org/RRC-7755-poc/bindings/rrc_7755_outbox"
	"github.com/base-org/RRC-7755-poc/internal/abi"
	"github.com/base-org/RRC-7755-poc/internal/client"
	"github.com/base-org/RRC-7755-poc/internal/config"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/holiman/uint256"
	"go.uber.org/zap"
)

const gasLimitBuffer float64 = 1.2


type OutboxListener struct {
	config    *config.Config
	logger    *zap.Logger
	clientMgr *client.Manager
}

type combinedMsgPostedPayload struct {
	msgPosted *rrc_7755_outbox.RRC7755OutboxMessagePosted
	chain     *client.ChainClient
}

type MessageAttributes struct {
	Nonce         uint256.Int
	RewardAsset   common.Address
	RewardAmount  uint256.Int
	FinalityDelay uint256.Int
	Expiry        uint256.Int
	Requester     [32]byte
	L2Oracle      common.Address
}

type ParsedMessage struct {
	SourceChain      uint64
	DestinationChain uint64
	Sender           common.Address
	SenderBytes32    [32]byte
	Receiver         common.Address
	Payload          []byte
	Attributes       *MessageAttributes
	RawAttributes    [][]byte

	UserOpAttributes *MessageAttributes
	ParsedUserOp     *abi.PackedUserOperation
}

type Service interface {
	ServiceName() string
	Run(ctx context.Context) error
}

func NewOutboxListener(
	ctx context.Context,
	clientMgr *client.Manager,
	config *config.Config,
	logger *zap.Logger,
) (Service, error) {
	return &OutboxListener{
		config:    config,
		logger:    logger,
		clientMgr: clientMgr,
	}, nil
}

func (l *OutboxListener) ServiceName() string {
	return "OutboxListener"
}

//nolint:cyclomatic,cognitive-complexity
func (l *OutboxListener) Run(ctx context.Context) error {
	var wg sync.WaitGroup

	combinedMsgPostedChan := make(chan combinedMsgPostedPayload, crossChainCallRequestedBufferSize)

	for _, chain := range l.clientMgr.GetAllClients() {
		for _, address := range chain.Config.OutboxAddresses {
			outbox, err := rrc_7755_outbox.NewRRC7755OutboxFilterer(
				address,
				chain.Client,
			)
			if err != nil {
				return fmt.Errorf("[DEBUG] creating outbox contract on chain %d: %w", chain.Config.ChainID, err)
			}

			msgPostedChan := make(chan *rrc_7755_outbox.RRC7755OutboxMessagePosted, crossChainCallRequestedBufferSize)


			// For real-time events, don't set Start block - this will watch from the latest block
			// which avoids the "exceed maximum block range" error
			subscription, err := outbox.WatchMessagePosted(&bind.WatchOpts{Context: ctx}, msgPostedChan, [][32]byte{})
			if err != nil {
				return fmt.Errorf("creating WatchMessagePosted subscription on chain %d: %w", chain.Config.ChainID, err)
			}
			l.logger.Info(
				"Started outbox WatchMessagePosted",
				zap.Uint64("chain_id", chain.Config.ChainID),
				zap.String("outbox_address", address.Hex()),
			)
			defer subscription.Unsubscribe()

			wg.Add(1)
			go func() {
				defer wg.Done()

				for {
					select {
					case m := <-msgPostedChan:
						combinedMsgPostedChan <- combinedMsgPostedPayload{msgPosted: m, chain: chain}
					case <-ctx.Done():
						return
					}
				}
			}()
		}
	}

loop:
	for {
		select {
		case c := <-combinedMsgPostedChan:
			l.logger.Info("Received message posted log", zap.Any("event", c.msgPosted), zap.Uint64("chain_id", c.chain.Config.ChainID))
			err := l.processMessagePosted(ctx, c.chain, c.msgPosted)
			if err != nil {
				l.logger.Error("Processing message posted", zap.Error(err))
			}
		case <-ctx.Done():
			break loop
		}
	}

	wg.Wait()

	return nil
}

func (l *OutboxListener) processMessagePosted(
	ctx context.Context,
	sourceChain *client.ChainClient,
	event *rrc_7755_outbox.RRC7755OutboxMessagePosted,
) error {
	parsed, err := l.ValidateMessagePosted(ctx, sourceChain, event)
	if err != nil {
		l.logger.Error("Validating message posted", zap.Error(err))
		return err
	}

	var (
		call       ethereum.CallMsg
		attributes *MessageAttributes
	)
	destChain := l.clientMgr.GetAllClients()[parsed.DestinationChain]

	if parsed.ParsedUserOp == nil {
		call, err = l.createCallMsg(parsed)
		if err != nil {
			l.logger.Error("Creating EOA call message", zap.Error(err))
			return fmt.Errorf("creating EOA call message: %w", err)
		}

		attributes = parsed.Attributes
	} else {
		call, err = l.createUserOpCallMsg(parsed)
		if err != nil {
			l.logger.Error("Creating user op call message", zap.Error(err))
			return fmt.Errorf("creating user op call message: %w", err)
		}

		attributes = parsed.UserOpAttributes
	}

	l.logger.Info("Formed call message", zap.Any("call", call))

	gasLimitAndPrice, err := l.getGasLimitAndPrice(ctx, destChain, call)
	if err != nil {
		l.logger.Error("Getting gas limit and price", zap.Error(err))
		return fmt.Errorf("getting gas limit and price: %w", err)
	}

	if err := l.validateReward(call, attributes, gasLimitAndPrice); err != nil {
		l.logger.Error("Validating reward", zap.Error(err))
		return fmt.Errorf("validating reward: %w", err)
	}

	if err := l.SendTransaction(ctx, destChain, call, gasLimitAndPrice); err != nil {
		l.logger.Error("Sending transaction", zap.Error(err))
		return fmt.Errorf("sending transaction: %w", err)
	}

	return nil
}

type GasLimitAndPrice struct {
	GasPrice *big.Int
	GasLimit *big.Int
}

func (l *OutboxListener) getGasLimitAndPrice(
	ctx context.Context,
	destChain *client.ChainClient,
	call ethereum.CallMsg,
) (GasLimitAndPrice, error) {
	// Estimate gas first
	estimatedGas, err := destChain.Client.EstimateGas(ctx, call)
	if err != nil {
		return GasLimitAndPrice{}, fmt.Errorf("estimating gas: %w", err)
	}

	// Add some buffer to the gas estimate
	gasLimitFloat := new(big.Float).SetUint64(estimatedGas)
	gasLimitFloat.Mul(gasLimitFloat, big.NewFloat(gasLimitBuffer))
	// truncate the gas limit to the nearest integer
	gasLimit, _ := gasLimitFloat.Int(nil)

	gasPrice, err := destChain.Client.SuggestGasPrice(ctx)
	if err != nil {
		return GasLimitAndPrice{}, fmt.Errorf("getting gas price: %w", err)
	}

	l.logger.Info(
		"Got gas limit and price",
		zap.String("gas_limit", gasLimit.String()),
		zap.String("gas_price", gasPrice.String()),
	)

	return GasLimitAndPrice{
		GasPrice: gasPrice,
		GasLimit: gasLimit,
	}, nil
}

func (l *OutboxListener) SendTransaction(
	ctx context.Context,
	destChain *client.ChainClient,
	call ethereum.CallMsg,
	gasLimitAndPrice GasLimitAndPrice,
) error {
	l.logger.Info("Starting transaction creation",
		zap.String("from", call.From.Hex()),
		zap.String("to", call.To.Hex()),
		zap.String("value", call.Value.String()),
		zap.Uint64("chain_id", destChain.Config.ChainID))

	nonce, err := destChain.Client.PendingNonceAt(ctx, common.HexToAddress(l.config.Wallets.FromAddress))
	if err != nil {
		return fmt.Errorf("getting nonce: %w", err)
	}
	l.logger.Info("Got nonce", zap.Uint64("nonce", nonce))

	l.logger.Info("Creating transaction",
		zap.Uint64("nonce", nonce),
		zap.Stringer("gas_price", gasLimitAndPrice.GasPrice),
		zap.Stringer("gas_limit", gasLimitAndPrice.GasLimit),
		zap.Binary("data", call.Data),
	)

	tx := types.NewTransaction(
		nonce,
		*call.To,
		call.Value,
		gasLimitAndPrice.GasLimit.Uint64(),
		gasLimitAndPrice.GasPrice,
		call.Data,
	)
	l.logger.Info("Created unsigned transaction", zap.String("hash", tx.Hash().Hex()))

	// Strip "0x" prefix if present
	privKeyStr := l.config.Wallets.PrivateKey
	if len(privKeyStr) >= 2 && privKeyStr[:2] == "0x" {
		privKeyStr = privKeyStr[2:]
	}

	privateKey, err := crypto.HexToECDSA(privKeyStr)
	if err != nil {
		return fmt.Errorf("parsing private key: %w", err)
	}
	l.logger.Info("Parsed private key")

	signedTx, err := types.SignTx(
		tx,
		types.NewEIP155Signer(big.NewInt(int64(destChain.Config.ChainID))),
		privateKey,
	)
	if err != nil {
		return fmt.Errorf("signing transaction: %w", err)
	}
	l.logger.Info("Signed transaction", zap.String("hash", signedTx.Hash().Hex()))

	if err := destChain.Client.SendTransaction(ctx, signedTx); err != nil {
		l.logger.Error("Sending transaction", zap.Error(err))
		return fmt.Errorf("sending transaction: %w", err)
	}

	l.logger.Info("Transaction sent successfully",
		zap.String("hash", signedTx.Hash().Hex()),
		zap.Uint64("nonce", nonce),
		zap.Stringer("gas_price", gasLimitAndPrice.GasPrice),
		zap.Stringer("gas_limit", gasLimitAndPrice.GasLimit),
	)
	return nil
}

func (l *OutboxListener) ValidateMessagePosted(
	ctx context.Context,
	sourceChain *client.ChainClient,
	event *rrc_7755_outbox.RRC7755OutboxMessagePosted,
) (*ParsedMessage, error) {
	parsed := l.parseMessage(event)

	if len(event.Attributes) == 0 {
		packedUserOperation, err := abi.UnmarshalPackedUserOperation(event.Payload)
		if err != nil {
			return nil, fmt.Errorf("unmarshalling packed user operation: %w", err)
		}

		paymasterData, err := packedUserOperation.GetPaymasterData()
		if err != nil {
			return nil, fmt.Errorf("getting paymaster data: %w", err)
		}

		userOpAttributes, err := parseAttributes(paymasterData)
		if err != nil {
			return nil, fmt.Errorf("parsing attributes: %w", err)
		}

		parsed.UserOpAttributes = userOpAttributes
		parsed.ParsedUserOp = packedUserOperation
	} else {
		attributes, err := parseAttributes(event.Attributes)
		if err != nil {
			return nil, fmt.Errorf("parsing attributes: %w", err)
		}

		parsed.Attributes = attributes

		l.logger.Info("Parsed attributes", zap.Any("attributes", attributes))
	}

	destChain, ok := l.clientMgr.GetAllClients()[parsed.DestinationChain]
	if !ok {
		return nil, fmt.Errorf("destination chain is not configured: %d", parsed.DestinationChain)
	}

	if err := validateAddresses(sourceChain, destChain, parsed); err != nil {
		return nil, fmt.Errorf("validating addresses: %w", err)
	}

	// TODO: validate prover

	l.logParsedMessage(parsed)

	return parsed, nil
}

func (l *OutboxListener) parseMessage(event *rrc_7755_outbox.RRC7755OutboxMessagePosted) *ParsedMessage {
	sourceChainBytes := make([]byte, uint64Size)
	destChainBytes := make([]byte, uint64Size)
	copy(sourceChainBytes, event.SourceChain[uint64Offset:])
	copy(destChainBytes, event.DestinationChain[uint64Offset:])

	var senderBytes32 [32]byte
	copy(senderBytes32[:], event.Sender[addressOffset:])

	return &ParsedMessage{
		SourceChain:      binary.BigEndian.Uint64(sourceChainBytes),
		DestinationChain: binary.BigEndian.Uint64(destChainBytes),
		Sender:           common.BytesToAddress(senderBytes32[:]),
		SenderBytes32:    senderBytes32,
		Receiver:         common.BytesToAddress(event.Receiver[addressOffset:]),
		Payload:          event.Payload,
		RawAttributes:    event.Attributes,
	}
}

func validateAddresses(sourceChain *client.ChainClient, destChain *client.ChainClient, parsed *ParsedMessage) error {
	// Validate chain IDs and receiver
	if sourceChain.Config.ChainID != parsed.SourceChain {
		return fmt.Errorf("source chain mismatch, want: %d, got: %d", sourceChain.Config.ChainID, parsed.SourceChain)
	}

	if parsed.ParsedUserOp == nil {
		if destChain.Config.InboxAddress != parsed.Receiver {
			return fmt.Errorf(
				"EOA call receiver address mismatch, want: %s, got: %s",
				destChain.Config.InboxAddress.Hex(),
				parsed.Receiver.Hex(),
			)
		}

		if destChain.Config.L2Oracle != parsed.Attributes.L2Oracle {
			return fmt.Errorf(
				"EOA call l2 oracle mismatch, want: %s, got: %s",
				destChain.Config.L2Oracle.Hex(),
				parsed.Attributes.L2Oracle.Hex(),
			)
		}
	} else {
		if destChain.Config.EntrypointAddress != parsed.Receiver {
			return fmt.Errorf(
				"account abstraction receiver address mismatch, want: %s, got: %s",
				destChain.Config.EntrypointAddress.Hex(),
				parsed.Receiver.Hex(),
			)
		}

		if destChain.Config.L2Oracle != parsed.UserOpAttributes.L2Oracle {
			return fmt.Errorf(
				"account abstraction l2 oracle mismatch, want: %s, got: %s",
				destChain.Config.L2Oracle.Hex(),
				parsed.UserOpAttributes.L2Oracle.Hex(),
			)
		}
	}

	return nil
}

func parseAttributes(attributes [][]byte) (*MessageAttributes, error) {
	parsed := &MessageAttributes{}

	for _, attr := range attributes {
		if len(attr) < selectorSize {
			// ignore current attribute if it's too short
			continue
		}

		selector := binary.BigEndian.Uint32(attr[:selectorSize])
		switch selector {
		case nonceAttributeSelector:
			if len(attr) < attributeBaseSize {
				return nil, errors.New("nonce attribute too short")
			}
			parsed.Nonce.SetBytes32(attr[selectorSize:attributeBaseSize])

		case rewardAttributeSelector:
			if len(attr) < attributeExtendedSize {
				return nil, errors.New("reward attribute too short")
			}
			parsed.RewardAsset.SetBytes(attr[selectorSize:attributeBaseSize])
			parsed.RewardAmount.SetBytes32(attr[attributeBaseSize:attributeExtendedSize])

		case delayAttributeSelector:
			if len(attr) < attributeExtendedSize {
				return nil, errors.New("delay attribute too short")
			}
			parsed.FinalityDelay.SetBytes32(attr[selectorSize:attributeBaseSize])
			parsed.Expiry.SetBytes32(attr[attributeBaseSize:attributeExtendedSize])

		case requesterAttributeSelector:
			if len(attr) < attributeBaseSize {
				return nil, errors.New("requester attribute too short")
			}
			copy(parsed.Requester[:], attr[selectorSize:attributeBaseSize])

		case l2OracleAttributeSelector:
			if len(attr) < attributeBaseSize {
				return nil, errors.New("l2Oracle attribute too short")
			}
			parsed.L2Oracle.SetBytes(attr[selectorSize:attributeBaseSize])
		}
	}

	return parsed, nil
}

func (l *OutboxListener) logParsedMessage(parsed *ParsedMessage) {
	var attrs *MessageAttributes
	if parsed.Attributes != nil {
		attrs = parsed.Attributes
	} else if parsed.UserOpAttributes != nil {
		attrs = parsed.UserOpAttributes
	} else {
		l.logger.Error("No attributes found in parsed message")
		return
	}

	nonceStr := attrs.Nonce.Dec()
	rewardAmountStr := attrs.RewardAmount.Dec()
	finalityDelayStr := attrs.FinalityDelay.Dec()
	expiryStr := attrs.Expiry.Dec()

	l.logger.Info("Parsed message",
		zap.Uint64("source_chain", parsed.SourceChain),
		zap.Uint64("destination_chain", parsed.DestinationChain),
		zap.String("sender", parsed.Sender.Hex()),
		zap.String("receiver", parsed.Receiver.Hex()),
		zap.Binary("payload", parsed.Payload),
		zap.String("nonce", nonceStr),
		zap.Binary("reward_asset", attrs.RewardAsset[:]),
		zap.String("reward_amount", rewardAmountStr),
		zap.String("finality_delay", finalityDelayStr),
		zap.String("expiry", expiryStr),
		zap.Binary("requester", attrs.Requester[:]),
		zap.Binary("l2_oracle", attrs.L2Oracle[:]),
		zap.Any("user_op", parsed.ParsedUserOp),
	)
}

func (l *OutboxListener) validateReward(
	call ethereum.CallMsg,
	attributes *MessageAttributes,
	gasLimitAndPrice GasLimitAndPrice,
) error {
	if attributes.RewardAsset != common.HexToAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE") {
		return errors.New("reward asset is not ETH")
	}

	estimatedGasUsed := new(big.Int).Mul(gasLimitAndPrice.GasLimit, gasLimitAndPrice.GasPrice)

	totalAmount := call.Value.Add(call.Value, estimatedGasUsed)
	if totalAmount.Cmp(attributes.RewardAmount.ToBig()) >= 0 {
		return fmt.Errorf(
			"reward amount is not enough, required minimum: %d, provided: %d",
			totalAmount,
			attributes.RewardAmount.ToBig(),
		)
	}

	l.logger.Info(
		"Valid reward",
		zap.Stringer("total_amount_required", totalAmount),
		zap.Stringer("reward_amount", attributes.RewardAmount.ToBig()),
		zap.Stringer("reward_asset", attributes.RewardAsset),
		zap.Any("call", call),
		zap.Any("attributes", attributes),
	)

	return nil
}

func (l *OutboxListener) createCallMsg(parsed *ParsedMessage) (ethereum.CallMsg, error) {
	inboxAbi, err := rrc_7755_inbox.RRC7755InboxMetaData.GetAbi()
	if err != nil {
		return ethereum.CallMsg{}, fmt.Errorf("getting ABI: %w", err)
	}

	var sourceChainBytes [32]byte
	binary.BigEndian.PutUint64(sourceChainBytes[24:], parsed.SourceChain)

	data, err := inboxAbi.Pack(
		"fulfill",
		sourceChainBytes,
		parsed.SenderBytes32,
		parsed.Payload,
		parsed.RawAttributes,
		l.config.Wallets.GetFromAddress(),
	)
	if err != nil {
		return ethereum.CallMsg{}, fmt.Errorf("packing fulfill data: %w", err)
	}

	requiredValue := big.NewInt(0)

	calls, err := abi.UnmarshalCalls(parsed.Payload)
	if err != nil {
		return ethereum.CallMsg{}, fmt.Errorf("unmarshalling calls: %w", err)
	}

	for _, call := range calls {
		requiredValue.Add(requiredValue, call.Value)
	}

	return ethereum.CallMsg{
		From:  l.config.Wallets.GetFromAddress(),
		To:    &parsed.Receiver,
		Data:  data,
		Value: requiredValue,
	}, nil
}

func (l *OutboxListener) createUserOpCallMsg(parsed *ParsedMessage) (ethereum.CallMsg, error) {
	entrypointAbi, err := entrypoint.EntrypointMetaData.GetAbi()
	if err != nil {
		return ethereum.CallMsg{}, fmt.Errorf("getting ABI: %w", err)
	}

	var sourceChainBytes [32]byte
	binary.BigEndian.PutUint64(sourceChainBytes[24:], parsed.SourceChain)

	data, err := entrypointAbi.Pack(
		"handleOps",
		[]abi.PackedUserOperation{*parsed.ParsedUserOp},
		l.config.Wallets.GetFromAddress(),
	)
	if err != nil {
		return ethereum.CallMsg{}, fmt.Errorf("packing handleOps data: %w", err)
	}

	return ethereum.CallMsg{
		From:  l.config.Wallets.GetFromAddress(),
		To:    &parsed.Receiver,
		Data:  data,
		Value: big.NewInt(0),
	}, nil
}
