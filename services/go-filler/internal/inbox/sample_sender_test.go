package inbox

import (
	"context"
	"errors"
	"math/big"
	"testing"

	"github.com/golang/mock/gomock"
	"github.com/stretchr/testify/assert"
	"go.uber.org/zap/zaptest"

	"github.com/base-org/RRC-7755-poc/internal/client"
	"github.com/base-org/RRC-7755-poc/internal/client/mocks"
	"github.com/base-org/RRC-7755-poc/internal/config"
)

func setupTest(t *testing.T) (*TransactionSenderManager, *mocks.MockEthClient, *config.Config) {
	ctrl := gomock.NewController(t)

	cfg := &config.Config{
		Chain: map[string]config.ChainConfig{
			"base-sepolia": {
				ChainID: 84532,
			},
		},
		Wallets: config.WalletConfig{
			FromAddress:      "0x1234567890123456789012345678901234567890",
			PrivateKey:       "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
			RecipientAddress: "0x0000000000000000000000000000000000000000",
		},
	}

	mockClient := mocks.NewMockEthClient(ctrl)
	chainClient := &client.ChainClient{
		Client: mockClient,
		Config: cfg.Chain["base-sepolia"],
	}

	clientMgr := &client.Manager{
		Chains: map[uint64]*client.ChainClient{
			84532: chainClient,
		},
	}

	logger := zaptest.NewLogger(t)
	sender := NewTransactionSenderManager(clientMgr, cfg, logger)

	return sender, mockClient, cfg
}

func TestSendTestTransaction_Success(t *testing.T) {
	sender, mockClient, _ := setupTest(t)

	mockClient.EXPECT().PendingNonceAt(gomock.Any(), gomock.Any()).Return(uint64(1), nil)
	mockClient.EXPECT().SuggestGasPrice(gomock.Any()).Return(big.NewInt(1000000000), nil)
	mockClient.EXPECT().SendTransaction(gomock.Any(), gomock.Any()).Return(nil)

	err := sender.SendTestTransaction(context.Background())
	assert.NoError(t, err)
}

func TestSendTestTransaction_NonceError(t *testing.T) {
	sender, mockClient, _ := setupTest(t)

	mockClient.EXPECT().PendingNonceAt(gomock.Any(), gomock.Any()).Return(uint64(0), errors.New("nonce error"))

	err := sender.SendTestTransaction(context.Background())
	assert.Error(t, err)
	assert.Equal(t, "nonce error", err.Error())
}

func TestSendTestTransaction_GasPriceError(t *testing.T) {
	sender, mockClient, _ := setupTest(t)

	mockClient.EXPECT().PendingNonceAt(gomock.Any(), gomock.Any()).Return(uint64(1), nil)
	mockClient.EXPECT().SuggestGasPrice(gomock.Any()).Return(nil, errors.New("gas price error"))

	err := sender.SendTestTransaction(context.Background())
	assert.Error(t, err)
	assert.Equal(t, "gas price error", err.Error())
}

func TestSendTestTransaction_SendError(t *testing.T) {
	sender, mockClient, _ := setupTest(t)

	mockClient.EXPECT().PendingNonceAt(gomock.Any(), gomock.Any()).Return(uint64(1), nil)
	mockClient.EXPECT().SuggestGasPrice(gomock.Any()).Return(big.NewInt(1000000000), nil)
	mockClient.EXPECT().SendTransaction(gomock.Any(), gomock.Any()).Return(errors.New("send error"))

	err := sender.SendTestTransaction(context.Background())
	assert.Error(t, err)
	assert.Equal(t, "send error", err.Error())
}

func TestSendTestTransaction_InvalidChain(t *testing.T) {
	sender, _, cfg := setupTest(t)

	chainCfg := cfg.Chain["base-sepolia"]
	chainCfg.ChainID = 999999
	cfg.Chain["base-sepolia"] = chainCfg

	err := sender.SendTestTransaction(context.Background())
	assert.Error(t, err)
	assert.Equal(t, "no client found for chain ID 999999", err.Error())
}

func TestHexToPrivateKey(t *testing.T) {
	tests := []struct {
		name    string
		hexKey  string
		wantErr bool
	}{
		{
			name:    "valid private key",
			hexKey:  "b6a1a44261b6b0f390ab6f1261b28301ddede25d22440f1e0304393341620f7e",
			wantErr: false,
		},
		{
			name:    "valid private key with 0x prefix",
			hexKey:  "0xb6a1a44261b6b0f390ab6f1261b28301ddede25d22440f1e0304393341620f7e",
			wantErr: false,
		},
		{
			name:    "invalid private key",
			hexKey:  "invalid",
			wantErr: true,
		},
		{
			name:    "empty private key",
			hexKey:  "",
			wantErr: true,
		},
		{
			name:    "wrong length private key",
			hexKey:  "0x1234",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := hexToPrivateKey(tt.hexKey)
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}
