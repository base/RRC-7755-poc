package arbitrum_prover

import (
	"context"
	"fmt"
	"math/big"
	"testing"

	"github.com/base-org/RRC-7755-poc/internal/prover/mocks"
	"github.com/base-org/RRC-7755-poc/internal/prover/storage_prover"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/golang/mock/gomock"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

// testL2Client is a simple implementation of L2Client for testing
type testL2Client struct {
	rpcClient storage_prover.EthRPCClient
}

func (c *testL2Client) RPCClient() storage_prover.EthRPCClient {
	return c.rpcClient
}

type RRC7755ArbitrumProverTestSuite struct {
	suite.Suite
	ctrl         *gomock.Controller
	logger       *zap.Logger
	l1Client     *mocks.MockL1Client
	l2Client     *testL2Client
	ethRPCClient *mocks.MockEthRPCClient
	prover       *RRC7755ArbitrumProver
	ctx          context.Context
	mockBlock    *types.Block
}

func TestRRC7755ArbitrumProverSuite(t *testing.T) {
	suite.Run(t, new(RRC7755ArbitrumProverTestSuite))
}

func (s *RRC7755ArbitrumProverTestSuite) SetupTest() {
	s.ctrl = gomock.NewController(s.T())
	s.logger = zaptest.NewLogger(s.T())
	s.l1Client = mocks.NewMockL1Client(s.ctrl)
	s.ethRPCClient = mocks.NewMockEthRPCClient(s.ctrl)
	s.l2Client = &testL2Client{rpcClient: s.ethRPCClient}
	s.ctx = context.Background()

	// Create a mock block for testing
	header := &types.Header{
		Number:     common.Big0,
		ParentHash: common.HexToHash("0x1234"),
		Root:       common.HexToHash("0x5678"),
	}
	s.mockBlock = types.NewBlockWithHeader(header)

	s.prover = NewRRC7755ArbitrumProver(
		s.logger,
		s.l1Client,
		s.l2Client,
		true, // isDevnet
	)
}

func (s *RRC7755ArbitrumProverTestSuite) TearDownTest() {
	s.ctrl.Finish()
}

func (s *RRC7755ArbitrumProverTestSuite) TestNewRRC7755ArbitrumProver() {
	require.NotNil(s.T(), s.prover)
	require.Equal(s.T(), s.logger, s.prover.logger)
	require.NotNil(s.T(), s.prover.l1StateProver)
	require.NotNil(s.T(), s.prover.inboxStorageProver)
	require.NotNil(s.T(), s.prover.arbitrumStateProver)
}

func (s *RRC7755ArbitrumProverTestSuite) TestGenerateProof_Success() {
	// TODO
}

func (s *RRC7755ArbitrumProverTestSuite) TestGenerateProof_L1StateProofError() {
	// Setup
	contractAddr := common.HexToAddress("0x1234")
	requestHash := common.HexToHash("0x5678")
	expectedErr := fmt.Errorf("l1 state proof error")

	// Setup mock expectations
	s.l1Client.EXPECT().BlockByNumber(s.ctx, (*big.Int)(nil)).Return(nil, expectedErr)

	// Execute
	result, err := s.prover.GenerateProof(s.ctx, contractAddr, requestHash)

	// Verify
	require.Error(s.T(), err)
	require.Nil(s.T(), result)
	require.Contains(s.T(), err.Error(), "failed to generate L1 state proof")
}

func (s *RRC7755ArbitrumProverTestSuite) TestGenerateProof_StorageProofError() {
	// Setup
	contractAddr := common.HexToAddress("0x1234")
	requestHash := common.HexToHash("0x5678")
	expectedErr := fmt.Errorf("storage proof error")

	// Setup mock expectations
	s.l1Client.EXPECT().BlockByNumber(s.ctx, (*big.Int)(nil)).Return(s.mockBlock, nil)
	s.ethRPCClient.EXPECT().Call(
		gomock.Any(),
		"eth_getProof",
		gomock.Any(),
	).Return(expectedErr)

	// Execute
	result, err := s.prover.GenerateProof(s.ctx, contractAddr, requestHash)

	// Verify
	require.Error(s.T(), err)
	require.Nil(s.T(), result)
	require.Contains(s.T(), err.Error(), "failed to generate inbox storage proof")
}

func (s *RRC7755ArbitrumProverTestSuite) TestGenerateProof_ArbitrumStateProofError() {
	// TODO
}
