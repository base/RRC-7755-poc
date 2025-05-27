package listener

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math/big"
	"testing"

	"github.com/base-org/RRC-7755-poc/bindings/rrc_7755_outbox"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"go.uber.org/zap/zaptest/observer"

	"github.com/base-org/RRC-7755-poc/internal/client"
	"github.com/base-org/RRC-7755-poc/internal/config"
)

// TestData represents the structure of our test fixture
type TestData struct {
	Event struct {
		MessageID        [32]byte `json:"MessageId"`
		SourceChain      [32]byte `json:"SourceChain"`
		Sender           [32]byte `json:"Sender"`
		DestinationChain [32]byte `json:"DestinationChain"`
		Receiver         [32]byte `json:"Receiver"`
		Payload          []byte   `json:"Payload"`
		Value            string   `json:"Value"`
		Attributes       []string `json:"Attributes"`
	} `json:"event"`
	ChainID uint64 `json:"chain_id"`
}

func TestValidateMessagePostedFromFixture(t *testing.T) {
	// Our example event data as a JSON string
	fixtureData := `{
		"event": {
			"MessageId": [100,25,116,140,99,58,241,96,7,127,32,139,190,117,182,155,101,191,171,178,79,18,137,63,96,75,1,165,61,105,20,61],
			"SourceChain": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,74,52],
			"Sender": [0,0,0,0,0,0,0,0,0,0,0,0,37,4,177,195,183,139,39,17,226,78,173,247,234,7,123,12,161,185,24,89],
			"DestinationChain": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,110,238],
			"Receiver": [0,0,0,0,0,0,0,0,0,0,0,0,27,184,218,203,163,11,28,216,44,225,211,215,242,78,22,238,84,154,235,232],
			"Payload": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAA5KNxFGLTcadzbya1+DFQ+QfE6O8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWvMQekAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
			"Attributes": [
				"o2Ll2wAAAAAAAAAAAAAAAO7u7u7u7u7u7u7u7u7u7u7u7u7uAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC15iD0gAA=",
				"hPVQ4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA4QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGfKt5o=",
				"zgP9qwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD",
				"O9lOTAAAAAAAAAAAAAAAAOSjcRRi03Gnc28mtfgxUPkHxOjv",
				"f/ckWgAAAAAAAAAAAAAAAAQrLmxemdTFIb1Jvu1emWUdmwz0"
			]
		},
		"chain_id": 84532
	}`

	var testData TestData
	err := json.Unmarshal([]byte(fixtureData), &testData)
	require.NoError(t, err)

	// Convert string Value to big.Int
	value := new(big.Int)
	value.SetString(testData.Event.Value, decimalBase)

	// Create the event object
	event := &rrc_7755_outbox.RRC7755OutboxMessagePosted{
		MessageId:        testData.Event.MessageID,
		SourceChain:      testData.Event.SourceChain,
		Sender:           testData.Event.Sender,
		DestinationChain: testData.Event.DestinationChain,
		Receiver:         testData.Event.Receiver,
		Payload:          testData.Event.Payload,
		Attributes:       make([][]byte, len(testData.Event.Attributes)),
	}

	// Convert base64 attributes to bytes
	for i, attr := range testData.Event.Attributes {
		decoded, err := base64.StdEncoding.DecodeString(attr)
		require.NoError(t, err)
		event.Attributes[i] = decoded
	}

	// Setup the chain configuration
	l2Oracle := common.HexToAddress("0x042b2e6c5e99d4c521bd49beed5e99651d9b0cf4")
	receiver := common.BytesToAddress(event.Receiver[12:])

	testChain := &client.ChainClient{
		Config: config.ChainConfig{
			ChainID:      testData.ChainID,
			L2Oracle:     l2Oracle,
			NodeURL:      "wss://base-sepolia.example.com",
			InboxAddress: receiver,
		},
	}

	cfg := config.Config{
		Chain: map[string]config.ChainConfig{
			fmt.Sprintf("%d", baseSepolia): {
				ChainID:      baseSepolia,
				InboxAddress: receiver,
			},
			fmt.Sprintf("%d", arbitrumSepolia): {
				ChainID:      arbitrumSepolia,
				L2Oracle:     l2Oracle,
				InboxAddress: receiver,
			},
		},
	}

	// Create the logger
	core, logs := observer.New(zapcore.ErrorLevel)
	logger := zap.New(core)

	// Create the listener
	l := &OutboxListener{
		config:    &cfg,
		logger:    logger,
		clientMgr: newTestClientManager(&cfg),
	}

	// Run the validation
	_, err = l.ValidateMessagePosted(context.Background(), testChain, event)
	require.NoError(t, err)

	// Verify no error logs were produced
	for _, log := range logs.All() {
		assert.NotEqual(t, zap.ErrorLevel, log.Level, "Unexpected error log: %s", log.Message)
	}

	// Debug print all logs
	t.Logf("All logs:")
	for _, log := range logs.All() {
		t.Logf("Level: %v, Message: %s, Fields: %v", log.Level, log.Message, log.Context)
	}
}
