package storage_prover

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"github.com/base-org/RRC-7755-poc/internal/prover/mocks"
	"github.com/ethereum/go-ethereum/common"
	"github.com/golang/mock/gomock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

type InboxStorageProverTestSuite struct {
	suite.Suite
	ctrl    *gomock.Controller
	mockRPC *mocks.MockEthRPCClient
	logger  *zap.Logger
	prover  *InboxStorageProver
	ctx     context.Context

	// Sample data for tests
	sampleContractAddr   common.Address
	sampleRequestHash    common.Hash
	sampleStorageKey     common.Hash
	sampleStorageSlot    common.Hash
	sampleAccountResult  AccountResult
	expectedStorageProof []string
}

func TestInboxStorageProverSuite(t *testing.T) {
	suite.Run(t, new(InboxStorageProverTestSuite))
}

func (s *InboxStorageProverTestSuite) SetupTest() {
	s.ctrl = gomock.NewController(s.T())
	s.mockRPC = mocks.NewMockEthRPCClient(s.ctrl)
	s.logger = zaptest.NewLogger(s.T())
	s.prover = NewInboxStorageProver(s.logger, &mockL2Client{rpcClient: s.mockRPC})
	s.ctx = context.Background()

	// Initialize sample data
	s.sampleContractAddr = common.HexToAddress("0xcf278dd7069e9fc7aed00e18274dfd7102e95351")
	s.sampleRequestHash = common.HexToHash("0x86a798714c57faaa50bc649a07dc45013c4931d4c630d5a316f5975f02704586")
	s.sampleStorageKey = common.HexToHash("0xc8d3d25a93f51f19c8ccc231e6bd32c5e3cde64a1e819275035a770b9bf96282")
	s.sampleStorageSlot = common.HexToHash("0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00")

	// Initialize expected storage proof
	s.expectedStorageProof = []string{
		"0xf8d180a064ac856028686eb1a14c793150690c06ae10b86d483b636862594bd14e3242bc80808080a0890d06a4933bf655e2696075c1b42f18ddcfbd8225b0f7f9e2c8a71e38caaf3980a05ba662047a4ea50714bfa845351186e4ffb6c2d94bd68bc6f2e35603a0ee293aa0f21792d7f0547ac8d78a7b8e7ee46eb787ac28dc14e4ef418b18bb8bc7e8db37a0143547079b13cf81c1b9247992b2b0a13b4a807e50c8737f178ffe013b95d3f8a0a8add1b7b21c59e037532fe175e091073f5132168834ab0ef4da80d7a1e7722d8080808080",
		"0xf85180808080808080808080a0498d9c2850b4dbabc8eadc537c019d8379d475faea01bc350851a89241e61290a005b0aceefb21748231965fb1716c97403ace46d84254253d0322f8733946cb2a8080808080",
		"0xf843a02026cdbb4fbb9d4c6d6f1b4e8fe4562ddb26fb5fba0bf20e125707b210f3ab5fa1a0e4a3711462d371a7736f26b5f83150f907c4e8ef000000000000000067d2a8ee",
	}

	// Initialize sample account result
	s.sampleAccountResult = AccountResult{
		Address:     s.sampleContractAddr.Hex(),
		Balance:     "0x51f7d",
		CodeHash:    "0x2249ab3489d21e26c55cc3236eaa9ea25cec0dcefdc86b7e424b6fa859a6c599",
		Nonce:       "0x1",
		StorageHash: "0xea368b18f5ce23c11ef5409bd612e9389dd34d97bd581981bf99ab8dbda41883",
		AccountProof: []string{
			"0xf90211a01643f30c6975912b99246fe648654aefeb0ef560685615c13758ce99bc7a5acf",
			// ... other account proofs ...
		},
		StorageProof: []StorageProof{
			{
				Key:   s.sampleStorageKey.Hex(),
				Value: "0xe4a3711462d371a7736f26b5f83150f907c4e8ef000000000000000067d2a8ee",
				Proof: s.expectedStorageProof,
			},
		},
	}
}

func (s *InboxStorageProverTestSuite) TearDownTest() {
	s.ctrl.Finish()
}

type mockL2Client struct {
	rpcClient EthRPCClient
}

func (m *mockL2Client) RPCClient() EthRPCClient {
	return m.rpcClient
}

func (s *InboxStorageProverTestSuite) TestCalculateStorageSlot() {
	// Test case from Solidity execution:
	// bytes32 messageId = 0x86a798714c57faaa50bc649a07dc45013c4931d4c630d5a316f5975f02704586;
	// bytes32 slot = 0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00;
	// bytes32 derivedSlot = keccak256(abi.encode(messageId, slot));
	// Expected result: 0xc8d3d25a93f51f19c8ccc231e6bd32c5e3cde64a1e819275035a770b9bf96282

	messageId := common.HexToHash("0x86a798714c57faaa50bc649a07dc45013c4931d4c630d5a316f5975f02704586")
	slot := common.HexToHash("0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00")
	expectedDerivedSlot := common.HexToHash("0xc8d3d25a93f51f19c8ccc231e6bd32c5e3cde64a1e819275035a770b9bf96282")

	calculatedSlot, err := CalculateStorageSlot(messageId, slot)
	s.NoError(err, "Storage slot calculation should not return an error")
	s.Equal(expectedDerivedSlot, calculatedSlot, "Calculated slot should match expected result from Solidity")
}

func (s *InboxStorageProverTestSuite) TestGetStorageProof() {
	s.Run("successful proof retrieval", func() {
		// Set up mock expectations with real data
		s.mockRPC.EXPECT().
			Call(gomock.Any(), "eth_getProof", gomock.Any(), gomock.Any(), "latest").
			DoAndReturn(func(result interface{}, method string, args ...interface{}) error {
				if proof, ok := result.(*AccountResult); ok {
					*proof = s.sampleAccountResult
				}
				return nil
			})

		result, err := s.prover.GetStorageProofForMapKey(s.ctx, s.sampleContractAddr, s.sampleStorageSlot, s.sampleRequestHash)
		s.NoError(err)
		s.NotNil(result)

		// Verify the formatted results
		s.Equal(s.sampleStorageKey.Hex(), result.StorageKey)
		s.Equal("0xe4a3711462d371a7736f26b5f83150f907c4e8ef000000000000000067d2a8ee", result.StorageValue)

		// Verify the formatted proofs - remove "0x" prefix for comparison
		expectedProofStr := fmt.Sprintf("%v", []string{
			strings.TrimPrefix(s.expectedStorageProof[0], "0x"),
			strings.TrimPrefix(s.expectedStorageProof[1], "0x"),
			strings.TrimPrefix(s.expectedStorageProof[2], "0x"),
		})
		s.Equal(expectedProofStr, result.StorageProof)

		// Verify account proof is properly formatted
		expectedAccountProof := fmt.Sprintf("%v", []string{
			strings.TrimPrefix(s.sampleAccountResult.AccountProof[0], "0x"),
		})
		s.Equal(expectedAccountProof, result.AccountProof)
	})

	s.Run("RPC call fails", func() {
		contractAddr := common.HexToAddress("0x...")
		requestHash := common.HexToHash("0x...")

		s.mockRPC.EXPECT().
			Call(gomock.Any(), "eth_getProof", gomock.Any(), gomock.Any(), "latest").
			Return(assert.AnError)

		result, err := s.prover.GetStorageProofForKey(s.ctx, contractAddr, requestHash)
		s.Error(err)
		s.Nil(result)
		s.ErrorContains(err, "failed to get proof from RPC")
	})
}

func (s *InboxStorageProverTestSuite) TestGetStorageProofForKey() {
	s.Run("successful proof retrieval", func() {
		// Set up mock expectations with real data
		s.mockRPC.EXPECT().
			Call(gomock.Any(), "eth_getProof", gomock.Any(), gomock.Any(), "latest").
			DoAndReturn(func(result interface{}, method string, args ...interface{}) error {
				if proof, ok := result.(*AccountResult); ok {
					*proof = s.sampleAccountResult
				}
				return nil
			})

		_, err := s.prover.GetStorageProofForKey(s.ctx, s.sampleContractAddr, s.sampleStorageKey)
		s.NoError(err)
	})

	s.Run("empty storage proof", func() {
		contractAddr := common.HexToAddress("0x...")
		storageKey := common.HexToHash("0x...")

		s.mockRPC.EXPECT().
			Call(gomock.Any(), "eth_getProof", gomock.Any(), gomock.Any(), "latest").
			DoAndReturn(func(result interface{}, method string, args ...interface{}) error {
				if proof, ok := result.(*AccountResult); ok {
					*proof = AccountResult{
						Address:      contractAddr.Hex(),
						StorageHash:  "0x0",
						StorageProof: []StorageProof{},
					}
				}
				return nil
			})

		result, err := s.prover.GetStorageProofForKey(s.ctx, contractAddr, storageKey)
		s.Error(err)
		s.Nil(result)
		s.ErrorContains(err, "no storage proof returned")
	})

	s.Run("invalid hex in storage proof", func() {
		contractAddr := common.HexToAddress("0x...")
		storageKey := common.HexToHash("0x...")

		s.mockRPC.EXPECT().
			Call(gomock.Any(), "eth_getProof", gomock.Any(), gomock.Any(), "latest").
			DoAndReturn(func(result interface{}, method string, args ...interface{}) error {
				if proof, ok := result.(*AccountResult); ok {
					*proof = AccountResult{
						Address:      contractAddr.Hex(),
						StorageHash:  "0x0",
						AccountProof: []string{"0x1234"},
						StorageProof: []StorageProof{{
							Key:   "0x0",
							Value: "0x0",
							Proof: []string{"invalid hex"},
						}},
					}
				}
				return nil
			})

		result, err := s.prover.GetStorageProofForKey(s.ctx, contractAddr, storageKey)
		s.Error(err)
		s.Nil(result)
		s.ErrorContains(err, "failed to decode storage proof")
	})

	s.Run("invalid storage value", func() {
		contractAddr := common.HexToAddress("0x...")
		storageKey := common.HexToHash("0x...")

		s.mockRPC.EXPECT().
			Call(gomock.Any(), "eth_getProof", gomock.Any(), gomock.Any(), "latest").
			DoAndReturn(func(result interface{}, method string, args ...interface{}) error {
				if proof, ok := result.(*AccountResult); ok {
					*proof = AccountResult{
						Address:      contractAddr.Hex(),
						StorageHash:  "0x0",
						AccountProof: []string{"0x1234"},
						StorageProof: []StorageProof{{
							Key:   "0x0",
							Value: "invalid hex",
							Proof: []string{"0x1234"},
						}},
					}
				}
				return nil
			})

		result, err := s.prover.GetStorageProofForKey(s.ctx, contractAddr, storageKey)
		s.Error(err)
		s.Nil(result)
		s.ErrorContains(err, "failed to decode storage value")
	})
}
