package storage_prover

import (
	"fmt"

	ethabi "github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

// StorageProofParams contains parameters for storage proofs
// Moved from inbox_storage_proofs.go to common.go

type StorageProofParams struct {
	StorageKey   string
	StorageValue string
	AccountProof string
	StorageProof string
}

// StorageProof contains the key, value, and proof for storage
// Moved from inbox_storage_proofs.go to common.go

type StorageProof struct {
	Key   string   `json:"key"`
	Value string   `json:"value"`
	Proof []string `json:"proof"`
}

// CalculateStorageSlot calculates the storage slot for a given requestHash and slotConstant.
func CalculateStorageSlot(requestHash, slotConstant common.Hash) (common.Hash, error) {
	arguments := ethabi.Arguments{
		{
			Type: ethabi.Type{
				T:    ethabi.FixedBytesTy,
				Size: 32,
			},
		},
		{
			Type: ethabi.Type{
				T:    ethabi.FixedBytesTy,
				Size: 32,
			},
		},
	}

	encodedData, err := arguments.Pack(requestHash, slotConstant)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to ABI encode storage slot parameters: %w", err)
	}

	return crypto.Keccak256Hash(encodedData), nil
}
