package config

import (
	"fmt"

	"github.com/ethereum/go-ethereum/common"
)

type ChainConfig struct {
	ChainID uint64 `mapstructure:"chain-id"`

	NodeURL                string `mapstructure:"node-url"`
	NodeInsecureSkipVerify bool   `mapstructure:"node-insecure-skip-verify"`

	OutboxAddresses map[string]common.Address `mapstructure:"outbox-addresses"`

	L2Oracle           common.Address `mapstructure:"l2-oracle"`
	L2OracleStorageKey string         `mapstructure:"l2-oracle-storage-key"`

	InboxAddress      common.Address `mapstructure:"inbox-address"`
	EntrypointAddress common.Address `mapstructure:"entrypoint-address"`
}

func GetChainConfigByID(cfg *Config, id uint64) (ChainConfig, error) {
	for _, chain := range cfg.Chain {
		if chain.ChainID == id {
			return chain, nil
		}
	}
	return ChainConfig{}, fmt.Errorf("chain with id %d not found", id)
}
