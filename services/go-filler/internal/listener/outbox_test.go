package listener

import (
	"context"
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/holiman/uint256"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"go.uber.org/zap/zaptest/observer"

	"github.com/base-org/RRC-7755-poc/bindings/rrc_7755_outbox"
	"github.com/base-org/RRC-7755-poc/internal/client"
	"github.com/base-org/RRC-7755-poc/internal/config"
)

const (
	// Chain IDs
	testSourceChainID = uint64(84532)  // Base Sepolia
	testDestChainID   = uint64(421614) // Arbitrum Sepolia

	// Byte sizes
	attributeSize      = 36 // 4 bytes selector + 32 bytes data
	delayAttributeSize = 68 // 4 bytes selector + 32 bytes finality + 32 bytes expiry
)

// Split TestValidateMessagePosted into smaller functions to reduce cognitive complexity
func TestValidateMessagePosted(t *testing.T) {
	// Setup test data
	testData := setupTestData()

	for _, tt := range testData {
		t.Run(tt.name, func(t *testing.T) {
			runValidationTest(t, tt)
		})
	}
}

type testCase struct {
	name    string
	event   *rrc_7755_outbox.RRC7755OutboxMessagePosted
	chain   *client.ChainClient
	config  *config.Config
	wantErr string
}

func setupTestData() []testCase {
	// Setup common test values to match the example
	sourceChainID := testSourceChainID
	destChainID := testDestChainID
	sender := common.HexToAddress("0x2504b1c3b78b2711e24eadf7ea077b0ca1b91859")
	receiver := common.HexToAddress("0x1bb8dacba30b1cd82ce1d3d7f24e16ee549aebe8")
	l2Oracle := common.HexToAddress("0x042b2e6c5e99d4c521bd49beed5e99651d9b0cf4")
	rewardAsset := common.HexToAddress("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
	payload := "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAA5KNxFGLTcadzbya1+DFQ+QfE6O8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWvMQekAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
	payloadBytes, _ := base64.StdEncoding.DecodeString(payload)

	// Convert test values to uint256
	testValueUint256, _ := uint256.FromBig(new(big.Int).SetUint64(testValue))
	nonce3 := uint256.NewInt(3)
	finality225 := uint256.NewInt(225)
	expiry6832538 := uint256.NewInt(6832538)

	// Helper to create attribute bytes to match the example
	createNonceAttr := func(nonce *uint256.Int) []byte {
		attr := make([]byte, attributeSize)
		binary.BigEndian.PutUint32(attr[0:], nonceAttributeSelector)
		nonceBytes := nonce.Bytes32()
		copy(attr[4:], nonceBytes[:])
		return attr
	}

	createRewardAttr := func(asset common.Address, amount *uint256.Int) []byte {
		attr := make([]byte, attributeExtendedSize)
		binary.BigEndian.PutUint32(attr[0:], rewardAttributeSelector)
		// Right align the address in first 32 bytes
		assetPadded := make([]byte, bytes32Size)
		copy(assetPadded[12:], asset.Bytes())
		copy(attr[4:36], assetPadded)
		amountBytes := amount.Bytes32()
		copy(attr[36:], amountBytes[:])
		return attr
	}

	createDelayAttr := func(finality, expiry *uint256.Int) []byte {
		attr := make([]byte, delayAttributeSize)
		binary.BigEndian.PutUint32(attr[0:], delayAttributeSelector)
		finalityBytes := finality.Bytes32()
		expiryBytes := expiry.Bytes32()
		copy(attr[4:36], finalityBytes[:])
		copy(attr[36:68], expiryBytes[:])
		return attr
	}

	createRequesterAttr := func(requester [32]byte) []byte {
		attr := make([]byte, attributeSize)
		binary.BigEndian.PutUint32(attr[0:], requesterAttributeSelector)
		copy(attr[4:], requester[:])
		return attr
	}

	createL2OracleAttr := func(oracle common.Address) []byte {
		attr := make([]byte, attributeSize)
		binary.BigEndian.PutUint32(attr[0:], l2OracleAttributeSelector)
		copy(attr[4+12:], oracle[:])
		return attr
	}

	tests := []testCase{
		{
			name: "valid message with all attributes",
			chain: &client.ChainClient{
				Config: config.ChainConfig{
					ChainID:      sourceChainID,
					L2Oracle:     l2Oracle,
					NodeURL:      "wss://base-sepolia.example.com",
					InboxAddress: receiver,
				},
			},
			config: &config.Config{
				Chain: map[string]config.ChainConfig{
					fmt.Sprintf("%d", sourceChainID): {
						ChainID:      sourceChainID,
						InboxAddress: receiver,
					},
					fmt.Sprintf("%d", destChainID): {
						ChainID:      destChainID,
						L2Oracle:     l2Oracle,
						InboxAddress: receiver,
					},
				},
			},
			event: createTestMessage(
				sourceChainID,
				destChainID,
				sender,
				receiver,
				payloadBytes,
				[][]byte{
					createRewardAttr(rewardAsset, testValueUint256),
					createDelayAttr(finality225, expiry6832538),
					createNonceAttr(nonce3),
					createRequesterAttr([32]byte{}),
					createL2OracleAttr(l2Oracle),
				},
			),
		},
		{
			name: "invalid l2 oracle",
			chain: &client.ChainClient{
				Config: config.ChainConfig{
					ChainID:      sourceChainID,
					L2Oracle:     l2Oracle,
					NodeURL:      "wss://base-sepolia.example.com",
					InboxAddress: receiver,
				},
			},
			config: &config.Config{
				Chain: map[string]config.ChainConfig{
					fmt.Sprintf("%d", sourceChainID): {
						ChainID:      sourceChainID,
						InboxAddress: receiver,
					},
					fmt.Sprintf("%d", destChainID): {
						ChainID:      destChainID,
						InboxAddress: receiver,
						L2Oracle:     l2Oracle,
					},
				},
			},
			event: createTestMessage(
				sourceChainID,
				destChainID,
				sender,
				receiver,
				payloadBytes,
				[][]byte{
					createL2OracleAttr(common.HexToAddress("0x1234567890123456789012345678901234567890")),
				},
			),
			wantErr: "l2 oracle mismatch",
		},
		// Add more test cases as needed
	}

	return tests
}

func newTestClientManager(cfg *config.Config) *client.Manager {
	chains := make(map[uint64]*client.ChainClient, len(cfg.Chain))

	for _, chainCfg := range cfg.Chain {
		chains[chainCfg.ChainID] = &client.ChainClient{
			Config: chainCfg,
		}
	}

	return &client.Manager{
		Chains: chains,
	}
}

func runValidationTest(t *testing.T, tt testCase) {
	core, logs := observer.New(zapcore.ErrorLevel)
	logger := zap.New(core)

	l := &OutboxListener{
		config:    tt.config,
		logger:    logger,
		clientMgr: newTestClientManager(tt.config),
	}

	parsed, err := l.ValidateMessagePosted(context.Background(), tt.chain, tt.event)

	if tt.wantErr != "" {
		require.Error(t, err)
		require.ErrorContains(t, err, tt.wantErr)
		require.Nil(t, parsed)
	} else {
		require.NoError(t, err)
		require.NotNil(t, parsed)
	}

	// Debug print all logs
	t.Logf("All logs:")
	for _, log := range logs.All() {
		t.Logf("Level: %v, Message: %s, Fields: %v", log.Level, log.Message, log.Context)
	}

	// Add right after creating the test event
	t.Logf("Test case %s - Created event:", tt.name)
	t.Logf("  Source Chain: %d", tt.event.SourceChain[24:])
	t.Logf("  Attributes length: %d", len(tt.event.Attributes))
	for i, attr := range tt.event.Attributes {
		t.Logf("  Attribute[%d] length: %d, selector: 0x%x", i, len(attr), binary.BigEndian.Uint32(attr[:4]))
	}
}

// Helper function to create test messages
func createTestMessage(
	sourceChain uint64,
	destChain uint64,
	sender common.Address,
	receiver common.Address,
	payload []byte,
	attributes [][]byte,
) *rrc_7755_outbox.RRC7755OutboxMessagePosted {
	var sourceChainBytes [32]byte
	var destChainBytes [32]byte
	var senderBytes [32]byte
	var receiverBytes [32]byte

	// Convert uint64 to bytes32 (right-aligned)
	binary.BigEndian.PutUint64(sourceChainBytes[24:], sourceChain)
	binary.BigEndian.PutUint64(destChainBytes[24:], destChain)

	// Add debug print
	fmt.Printf("Source Chain: input=%d, bytes=%x\n", sourceChain, sourceChainBytes)
	fmt.Printf("Dest Chain: input=%d, bytes=%x\n", destChain, destChainBytes)

	// Convert addresses to bytes32 (right-aligned)
	copy(senderBytes[12:], sender[:])
	copy(receiverBytes[12:], receiver[:])

	return &rrc_7755_outbox.RRC7755OutboxMessagePosted{
		SourceChain:      sourceChainBytes,
		DestinationChain: destChainBytes,
		Sender:           senderBytes,
		Receiver:         receiverBytes,
		Payload:          payload,
		Attributes:       attributes,
	}
}
