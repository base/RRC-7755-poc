package client

import (
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
)

// EthClient interface defines the methods we need to mock
type EthClient interface {
	ethereum.ChainReader
	ethereum.GasEstimator
	ethereum.PendingStateReader
	ethereum.GasPricer
	ethereum.TransactionSender
	ethereum.ChainIDReader
	ethereum.ChainStateReader
	bind.ContractFilterer
}
