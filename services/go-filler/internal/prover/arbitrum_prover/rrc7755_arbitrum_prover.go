package arbitrum_prover

import (
	"context"
	"fmt"

	"github.com/base-org/RRC-7755-poc/internal/prover/l1_state_prover"
	"github.com/base-org/RRC-7755-poc/internal/prover/storage_prover"
	"github.com/ethereum/go-ethereum/common"
	"go.uber.org/zap"
)

// slotConstant is the constant used in the inbox contract to store
// the mapping of requestHash -> fulfillmentInfo
const slotConstant = "0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00"

// Parameters needed for a full nested cross-L2 storage proof with Arbitrum as the destination chain
type RRC7755Proof struct {
	// These 4 following fields work together with DstL2StateRootProof to certify the L2 state (step 2 in overview.md)

	// The RLP-encoded array of block headers of Arbitrum's L2 block corresponding to the above RBlock
	// Hashing this bytes string should produce the blockhash
	EncodedBlockArray []byte

	// The state of the assertion node after the sequencer machine has finished
	AfterState AssertionState

	// The hash of the previous assertion
	PrevAssertionHash [32]byte

	// The accumulator of the sequencer batch
	SequencerBatchAcc [32]byte

	// Contains L1 block information & the associated proof (step 1 in overview.md)
	// Parameters needed to validate the authenticity of Ethereum's execution client's state root
	StateProofParams l1_state_prover.L1StateProof

	// Contains L2 block information & the associated proof (step 2 in overview.md)
	// Parameters needed to validate the authenticity of the l2Oracle for the destination L2 chain on Eth mainnet
	DstL2StateRootProofParams storage_prover.StorageProofParams

	// Contains proof that the inbox contract indeed contains an entry about a successful fulfillment (step 3 in overview.md)
	// Parameters needed to validate the authenticity of a specified storage location on the destination L2
	DstL2AccountProofParams storage_prover.StorageProofParams
}

// / @notice The status of the sequencer machine
type MachineStatus int

const (
	RUNNING MachineStatus = iota
	FINISHED
	ERRORED
)

// The global state of arbitrum when the AssertionNode was created
type GlobalState struct {
	// An array containing the blockhash of the L2 block and the sendRoot
	Bytes32Vals [2][32]byte
	// An array containing the inbox position and the position in message of the assertion
	U64Vals [2]uint64
}

// The state of the assertion node
// AssertionState represents the state of an Arbitrum assertion
type AssertionState struct {
	// The global state of arbitrum when the AssertionNode was created
	GlobalState GlobalState
	// The status of the sequencer machine
	MachineStatus MachineStatus
	// The end history root of the assertion
	EndHistoryRoot [32]byte
}

// RRC7755ArbitrumProver handles the generation of RRC7755 proofs for Arbitrum
type RRC7755ArbitrumProver struct {
	logger              *zap.Logger
	l1StateProver       *l1_state_prover.L1StateProver
	inboxStorageProver  *storage_prover.InboxStorageProver
	arbitrumStateProver *ArbitrumStateProver
}

// NewRRC7755ArbitrumProver creates a new RRC7755ArbitrumProver instance
func NewRRC7755ArbitrumProver(
	logger *zap.Logger,
	l1Client l1_state_prover.L1Client,
	l2Client storage_prover.L2Client,
	isDevnet bool,
) *RRC7755ArbitrumProver {
	// Create L1 state prover
	l1StateProver := l1_state_prover.NewL1StateProver(logger, l1Client, isDevnet)

	// Create inbox storage prover
	inboxStorageProver := storage_prover.NewInboxStorageProver(logger, l2Client)

	// Create Arbitrum state prover
	arbitrumStateProver := NewArbitrumStateProver(logger)

	return &RRC7755ArbitrumProver{
		logger:              logger,
		l1StateProver:       l1StateProver,
		inboxStorageProver:  inboxStorageProver,
		arbitrumStateProver: arbitrumStateProver,
	}
}

// GenerateProof generates a complete RRC7755 proof for Arbitrum
func (p *RRC7755ArbitrumProver) GenerateProof(
	ctx context.Context,
	contractAddr common.Address,
	requestHash common.Hash,
) (*RRC7755Proof, error) {
	// Step 1: Generate L1 state proof (maps to overview.md step 1)
	l1StateProof, l1Block, err := p.l1StateProver.GenerateL1StateProof(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to generate L1 state proof: %w", err)
	}

	// Step 2: Generate Arbitrum state proof (maps to overview.md step 2)
	arbitrumStateProof, err := p.arbitrumStateProver.GenerateArbitrumStateProof(ctx, l1Block)
	if err != nil {
		return nil, fmt.Errorf("failed to generate arbitrum state proof: %w", err)
	}

	// Step 3: Generate inbox storage proof (maps to overview.md step 3)
	inboxStorageProof, err := p.inboxStorageProver.GetStorageProofForMapKey(
		ctx,
		contractAddr,
		common.HexToHash(slotConstant),
		requestHash,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to generate inbox storage proof: %w", err)
	}

	// Combine all proofs into RRC7755Proof
	proof := &RRC7755Proof{
		EncodedBlockArray:         arbitrumStateProof.EncodedBlockArray,
		AfterState:                arbitrumStateProof.AfterState,
		PrevAssertionHash:         arbitrumStateProof.PrevAssertionHash,
		SequencerBatchAcc:         arbitrumStateProof.SequencerBatchAcc,
		StateProofParams:          *l1StateProof,
		DstL2AccountProofParams:   *inboxStorageProof,
		DstL2StateRootProofParams: arbitrumStateProof.DstL2StateRootProofParams,
	}

	return proof, nil
}
