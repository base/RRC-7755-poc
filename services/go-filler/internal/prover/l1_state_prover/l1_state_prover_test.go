package l1_state_prover

import (
	"context"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"go.uber.org/zap"
)

// MockL1Client is a mock implementation of L1Client interface
type MockL1Client struct {
	mock.Mock
}

func (m *MockL1Client) BlockByNumber(ctx context.Context, number *big.Int) (*types.Block, error) {
	args := m.Called(ctx, number)
	return args.Get(0).(*types.Block), args.Error(1)
}

type L1StateProverTestSuite struct {
	suite.Suite
	logger       *zap.Logger
	mockL1Client *MockL1Client
	mockBlock    *types.Block
	require      *require.Assertions
}

func (s *L1StateProverTestSuite) SetupTest() {
	s.require = require.New(s.T())

	// Create a test logger
	s.logger, _ = zap.NewDevelopment()

	// Create mock L1 client
	s.mockL1Client = new(MockL1Client)

	// Create a mock block that can be used across tests
	header := &types.Header{
		Number:     big.NewInt(12345),
		Time:       uint64(time.Now().Unix()),
		Root:       common.HexToHash("0x1234567890"),
		ParentHash: common.HexToHash("0x0987654321"),
	}
	s.mockBlock = types.NewBlockWithHeader(header)
}

func (s *L1StateProverTestSuite) TearDownTest() {
	s.mockL1Client.AssertExpectations(s.T())
}

func (s *L1StateProverTestSuite) TestDevnetModeGeneratesMockProof() {
	// Set up expectations
	s.mockL1Client.On("BlockByNumber", mock.Anything, (*big.Int)(nil)).Return(s.mockBlock, nil)

	// Create L1StateProver instance
	prover := NewL1StateProver(s.logger, s.mockL1Client, true)

	// Generate proof
	proof, resultBlock, err := prover.GenerateL1StateProof(context.Background())

	// Assertions using require
	s.require.NoError(err)
	s.require.NotNil(proof)
	s.require.Equal(s.mockBlock, resultBlock)
	s.require.Equal(s.mockBlock.Root().Hex(), proof.ExecutionStateRoot)
	s.require.Equal(s.mockBlock.Time(), proof.BeaconTimestamp)
	s.require.Len(proof.StateRootProof, 1) // Mock proof should have one element
}

func (s *L1StateProverTestSuite) TestProductionModeReturnsError() {
	// Create L1StateProver instance with production mode
	prover := NewL1StateProver(s.logger, s.mockL1Client, false)

	// Generate proof
	proof, block, err := prover.GenerateL1StateProof(context.Background())

	// Assertions using require
	s.require.Error(err)
	s.require.Nil(proof)
	s.require.Nil(block)
	s.require.Contains(err.Error(), "production beacon chain proof generation not implemented")

	// Verify no calls were made to the mock
	s.mockL1Client.AssertNotCalled(s.T(), "BlockByNumber")
}

func TestL1StateProverSuite(t *testing.T) {
	suite.Run(t, new(L1StateProverTestSuite))
}
