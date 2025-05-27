package l1_state_prover

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"go.uber.org/zap"
)

// L1Client defines the interface for interacting with L1
type L1Client interface {
	BlockByNumber(ctx context.Context, number *big.Int) (*types.Block, error)
}

// L1StateProver handles L1 state proof operations
type L1StateProver struct {
	logger   *zap.Logger
	l1Client L1Client
	isDevnet bool
}

// NewL1StateProver creates a new L1StateProver instance
func NewL1StateProver(logger *zap.Logger, l1Client L1Client, isDevnet bool) *L1StateProver {
	return &L1StateProver{
		logger:   logger,
		l1Client: l1Client,
		isDevnet: isDevnet,
	}
}

// ArbitrumProof represents the proof data for Arbitrum's L1 state
type L1StateProof struct {
	BeaconRoot         string
	BeaconTimestamp    uint64
	ExecutionStateRoot string
	StateRootProof     []string
}

func (p *L1StateProver) GenerateL1StateProof(
	ctx context.Context,
) (*L1StateProof, *types.Block, error) {
	if p.isDevnet {
		l1Block, err := p.l1Client.BlockByNumber(ctx, nil)
		if err != nil {
			return nil, nil, fmt.Errorf("failed to get L1 block: %w", err)
		}
		l1BlockNumber := l1Block.NumberU64()
		executionStateRoot := l1Block.Root()

		// In devnet, we use mock state root proof
		stateRootProof := []string{"mock_proof"}
		beaconRoot := crypto.Keccak256Hash(executionStateRoot.Bytes()).Hex()
		beaconTimestamp := l1Block.Time()

		p.logger.Info("Generated L1 state proof for devnet",
			zap.Uint64("blockNumber", l1BlockNumber),
			zap.String("executionStateRoot", executionStateRoot.Hex()),
			zap.String("beaconRoot", beaconRoot),
			zap.Uint64("timestamp", beaconTimestamp))

		return &L1StateProof{
			BeaconRoot:         beaconRoot,
			BeaconTimestamp:    beaconTimestamp,
			ExecutionStateRoot: executionStateRoot.Hex(),
			StateRootProof:     stateRootProof,
		}, l1Block, nil
	} else {
		// In production, get these from your beacon chain client
		// Implementation depends on your beacon chain client
		return nil, nil, fmt.Errorf("production beacon chain proof generation not implemented")
	}
}
