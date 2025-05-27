package storage_prover

import (
	"context"
	"encoding/hex"
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"go.uber.org/zap"
)

// Define types to match Ethereum JSON-RPC responses for eth_getProof
type AccountResult struct {
	Address      string         `json:"address"`
	AccountProof []string       `json:"accountProof"`
	Balance      string         `json:"balance"`
	CodeHash     string         `json:"codeHash"`
	Nonce        string         `json:"nonce"`
	StorageHash  string         `json:"storageHash"`
	StorageProof []StorageProof `json:"storageProof"`
}

// EthRPCClient defines the interface for Ethereum RPC operations
// This is a subset of rpc.Client interface that we need for storage proofs
type EthRPCClient interface {
	Call(result interface{}, method string, args ...interface{}) error
}

// L2Client defines the interface for interacting with L2
type L2Client interface {
	RPCClient() EthRPCClient
}

// InboxStorageProver handles storage proof operations for the inbox contract
type InboxStorageProver struct {
	logger   *zap.Logger
	l2Client L2Client
}

// NewInboxStorageProver creates a new InboxStorageProver instance
func NewInboxStorageProver(logger *zap.Logger, l2Client L2Client) *InboxStorageProver {
	return &InboxStorageProver{
		logger:   logger,
		l2Client: l2Client,
	}
}

// For example, if a map that looks like
//
//	mapping(bytes32 key => FulfillmentInfo) fulfillmentInfo;
//
// is stored in storage slot 0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00,
// and we want to get the proof for a given key, we can use this function
// by passing in the mapStorageSlot and the mapKey
func (i *InboxStorageProver) GetStorageProofForMapKey(
	ctx context.Context,
	contractAddr common.Address,
	mapStorageSlot common.Hash,
	mapKey common.Hash,
) (*StorageProofParams, error) {
	storageKey, err := CalculateStorageSlot(mapKey, mapStorageSlot)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate storage slot: %w", err)
	}
	return i.GetStorageProofForKey(ctx, contractAddr, storageKey)
}

// GetStorageProof retrieves proof for a given storage slot at a contract address
func (i *InboxStorageProver) GetStorageProofForKey(
	ctx context.Context,
	contractAddr common.Address,
	storageSlot common.Hash,
) (*StorageProofParams, error) {
	// Use our defined types
	proof := new(AccountResult)

	i.logger.Info("Getting storage proof",
		zap.String("contract", contractAddr.Hex()),
		zap.String("storageSlot", storageSlot.Hex()))

	err := i.l2Client.RPCClient().Call(proof, "eth_getProof", contractAddr, []string{storageSlot.Hex()}, "latest")
	if err != nil {
		return nil, fmt.Errorf("failed to get proof from RPC: %w", err)
	}

	if len(proof.StorageProof) == 0 {
		return nil, fmt.Errorf("no storage proof returned")
	}

	// Log raw proof data for debugging
	i.logger.Debug("Raw proof data",
		zap.String("address", proof.Address),
		zap.String("storageHash", proof.StorageHash),
		zap.Int("accountProofLength", len(proof.AccountProof)),
		zap.Int("storageProofLength", len(proof.StorageProof)),
		zap.String("storageKey", proof.StorageProof[0].Key),
		zap.String("storageValue", proof.StorageProof[0].Value))

	// Convert string proofs to byte arrays
	accountProof := make([][]byte, len(proof.AccountProof))
	for i, proofStr := range proof.AccountProof {
		decodedProof, err := safeHexDecode(proofStr)
		if err != nil {
			return nil, fmt.Errorf("failed to decode account proof item %d: %w", i, err)
		}
		accountProof[i] = decodedProof
	}

	storageProofBytes := make([][]byte, len(proof.StorageProof[0].Proof))
	for i, proofStr := range proof.StorageProof[0].Proof {
		decodedProof, err := safeHexDecode(proofStr)
		if err != nil {
			return nil, fmt.Errorf("failed to decode storage proof item %d: %w", i, err)
		}
		storageProofBytes[i] = decodedProof
	}

	// Get storage value from proof
	storageValue, err := getStorageValueFromProof(proof)
	if err != nil {
		return nil, fmt.Errorf("failed to get storage value from proof: %w", err)
	}

	i.logger.Info("Storage proof",
		zap.String("storageSlot", storageSlot.Hex()),
		zap.String("storageValue", storageValue.Hex()),
		zap.Int("accountProofLength", len(accountProof)),
		zap.Int("storageProofLength", len(storageProofBytes)))

	return &StorageProofParams{
		StorageKey:   storageSlot.Hex(),
		StorageValue: storageValue.Hex(),
		AccountProof: formatBytes(accountProof),
		StorageProof: formatBytes(storageProofBytes),
	}, nil
}

// getStorageValueFromProof extracts and decodes the storage value from the proof result
func getStorageValueFromProof(proof *AccountResult) (common.Hash, error) {
	if len(proof.StorageProof) == 0 {
		return common.Hash{}, fmt.Errorf("no storage proof available")
	}

	valueBytes, err := safeHexDecode(proof.StorageProof[0].Value)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to decode storage value: %w", err)
	}

	return common.BytesToHash(valueBytes), nil
}

// safeHexDecode decodes a hex string safely, handling odd-length strings
func safeHexDecode(hexStr string) ([]byte, error) {
	// Remove '0x' prefix if present
	if len(hexStr) >= 2 && hexStr[0:2] == "0x" {
		hexStr = hexStr[2:]
	}

	// Handle odd-length strings by padding with a leading zero
	if len(hexStr)%2 != 0 {
		hexStr = "0" + hexStr
	}

	return hex.DecodeString(hexStr)
}

func formatBytes(data [][]byte) string {
	if len(data) == 0 {
		return "[]"
	}

	hexStrings := make([]string, len(data))
	for i, b := range data {
		hexStrings[i] = hex.EncodeToString(b)
	}

	return fmt.Sprintf("%v", hexStrings)
}
