package arbitrum_prover

import (
	"context"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

type ArbitrumStateProverTestSuite struct {
	suite.Suite
	logger *zap.Logger
	prover *ArbitrumStateProver
	ctx    context.Context
}

func TestArbitrumStateProverSuite(t *testing.T) {
	suite.Run(t, new(ArbitrumStateProverTestSuite))
}

func (s *ArbitrumStateProverTestSuite) SetupTest() {
	s.logger = zaptest.NewLogger(s.T())
	s.prover = NewArbitrumStateProver(s.logger)
	s.ctx = context.Background()
}

func (s *ArbitrumStateProverTestSuite) TestNewArbitrumStateProver() {
	require.NotNil(s.T(), s.prover)
	require.Equal(s.T(), s.logger, s.prover.logger)
}

func (s *ArbitrumStateProverTestSuite) TestGenerateArbitrumStateProof_Success() {
	// Setup
	header := &types.Header{
		Number:     common.Big0,
		ParentHash: common.Hash{},
		Root:       common.Hash{},
	}
	block := types.NewBlockWithHeader(header)

	// Execute
	result, err := s.prover.GenerateArbitrumStateProof(s.ctx, block)

	// Verify
	require.NoError(s.T(), err)
	require.NotNil(s.T(), result)

	// Basic structure validation
	require.NotNil(s.T(), result.EncodedBlockArray)
	require.NotNil(s.T(), result.AfterState)

	// Validate array lengths and initialization
	require.Len(s.T(), result.AfterState.GlobalState.Bytes32Vals, 2)
	require.Len(s.T(), result.AfterState.GlobalState.U64Vals, 2)

	// Validate machine status
	require.Equal(s.T(), MachineStatus(FINISHED), result.AfterState.MachineStatus)

	// Validate all components are initialized (even if zero)
	require.NotNil(s.T(), result.DstL2StateRootProofParams)
	require.NotNil(s.T(), result.EncodedBlockArray)
	require.Equal(s.T(), [32]byte{}, result.AfterState.EndHistoryRoot)
}

func (s *ArbitrumStateProverTestSuite) TestGenerateArbitrumStateProof_NilBlock() {
	// Execute
	result, err := s.prover.GenerateArbitrumStateProof(s.ctx, nil)

	// Verify
	require.Error(s.T(), err)
	require.Nil(s.T(), result)
	require.Contains(s.T(), err.Error(), "l1Block cannot be nil")
}

func (s *ArbitrumStateProverTestSuite) TestGenerateArbitrumStateProof_MockValues() {
	// Setup
	header := &types.Header{
		Number:     common.Big0,
		ParentHash: common.HexToHash("0x1234"),
		Root:       common.HexToHash("0x5678"),
	}
	block := types.NewBlockWithHeader(header)

	// Execute
	result, err := s.prover.GenerateArbitrumStateProof(s.ctx, block)

	// Verify
	require.NoError(s.T(), err)
	require.NotNil(s.T(), result)

	// Test specific mock values
	require.Empty(s.T(), result.EncodedBlockArray)
	require.Equal(s.T(), MachineStatus(FINISHED), result.AfterState.MachineStatus)
	require.Equal(s.T(), [32]byte{}, result.PrevAssertionHash)
	require.Equal(s.T(), [32]byte{}, result.SequencerBatchAcc)

	// Verify GlobalState structure
	require.Len(s.T(), result.AfterState.GlobalState.Bytes32Vals, 2)
	require.Len(s.T(), result.AfterState.GlobalState.U64Vals, 2)
}
