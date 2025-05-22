package inbox

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"strings"

	"github.com/base-org/RRC-7755-poc/internal/client"
	"github.com/base-org/RRC-7755-poc/internal/config"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"go.uber.org/zap"
)

type TransactionSenderManager struct {
	clientMgr *client.Manager
	cfg       *config.Config
	logger    *zap.Logger
}

func NewTransactionSenderManager(
	clientMgr *client.Manager,
	cfg *config.Config,
	logger *zap.Logger,
) *TransactionSenderManager {
	return &TransactionSenderManager{
		clientMgr: clientMgr,
		cfg:       cfg,
		logger:    logger,
	}
}

func hexToPrivateKey(hexkey string) (*ecdsa.PrivateKey, error) {
	return crypto.HexToECDSA(strings.TrimPrefix(hexkey, "0x"))
}

// SendTestTransaction sends a test transaction to the specified chain
func (m *TransactionSenderManager) SendTestTransaction(ctx context.Context) error {
	m.logger.Info("Sending test transaction")
	cfg := m.cfg
	chain, err := m.clientMgr.GetChainClient(cfg.Chain["base-sepolia"].ChainID)
	if err != nil {
		return err
	}
	nonce, err := chain.Client.PendingNonceAt(ctx, cfg.Wallets.GetFromAddress())
	if err != nil {
		m.logger.Error("Failed to get nonce", zap.Error(err))
		return err
	}

	gasPrice, err := chain.Client.SuggestGasPrice(ctx)
	if err != nil {
		m.logger.Error("Failed to get gas price", zap.Error(err))
		return err
	}

	// sample transaction
	tx := types.NewTransaction(
		nonce,
		cfg.Wallets.GetRecipientAddress(),
		big.NewInt(10000000000), // 0.00000001 ETH in wei
		21000,                   // Standard ETH transfer gas limit
		gasPrice,
		nil, // No data for simple ETH transfer
	)

	privateKey, err := hexToPrivateKey(cfg.Wallets.PrivateKey)
	if err != nil {
		return fmt.Errorf("invalid private key: %w", err)
	}

	m.logger.Info("Signing transaction")
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(big.NewInt(int64(cfg.Chain["base-sepolia"].ChainID))), privateKey)
	if err != nil {
		m.logger.Error("Failed to sign transaction", zap.Error(err))
		return err
	}

	m.logger.Info("Sending transaction")
	err = chain.Client.SendTransaction(ctx, signedTx)
	if err != nil {
		m.logger.Error("Failed to send transaction", zap.Error(err))
		return err
	}

	m.logger.Info("Transaction sent successfully", zap.String("txHash", signedTx.Hash().String()))

	return nil
}
