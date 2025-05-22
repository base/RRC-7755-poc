package abi

import (
	_ "embed"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi"
)

var CallsArgs abi.Arguments

//go:embed json/calls.json
var callsABIJson string

type Call struct {
	To    [32]byte `abi:"to"`
	Data  []byte   `abi:"data"`
	Value *big.Int `abi:"value"`
}

func init() {
	callArg := abi.Argument{}
	err := callArg.UnmarshalJSON([]byte(callsABIJson))
	if err != nil {
		panic(fmt.Errorf("initializing CallsArgs: %w", err))
	}

	CallsArgs = abi.Arguments{callArg}
}

func UnmarshalCalls(data []byte) ([]Call, error) {
	unpacked, err := CallsArgs.Unpack(data)
	if err != nil {
		return nil, fmt.Errorf("unpacking calls: %w", err)
	}

	var calls []Call
	err = CallsArgs.Copy(&calls, unpacked)
	if err != nil {
		return nil, fmt.Errorf("copying calls: %w", err)
	}

	return calls, nil
}
