package client

import (
	"context"
	"fmt"

	"github.com/base-org/RRC-7755-poc/internal/config"
)

type ChainClient struct {
	Client EthClient
	Config config.ChainConfig
}

type Manager struct {
	Chains map[uint64]*ChainClient
}

func NewManager(ctx context.Context, cfg *config.Config) (*Manager, error) {
	chains := make(map[uint64]*ChainClient, len(cfg.Chain))

	for name, chainCfg := range cfg.Chain {
		client, err := NewEthClient(ctx, chainCfg)
		if err != nil {
			return nil, fmt.Errorf("creating client for chain %s: %w", name, err)
		}

		chains[chainCfg.ChainID] = &ChainClient{
			Client: client,
			Config: chainCfg,
		}
	}

	return &Manager{
		Chains: chains,
	}, nil
}

func (m *Manager) GetChainClient(chainID uint64) (*ChainClient, error) {
	client, ok := m.Chains[chainID]
	if !ok {
		return nil, fmt.Errorf("no client found for chain ID %d", chainID)
	}
	return client, nil
}

func (m *Manager) GetAllClients() map[uint64]*ChainClient {
	return m.Chains
}
