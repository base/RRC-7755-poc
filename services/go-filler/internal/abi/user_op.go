package abi

import (
	_ "embed"
	"errors"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
)

var (
	//go:embed json/user_op.json
	packedUserOperationABIJson string

	//go:embed json/paymaster_data.json
	paymasterDataABIJson string
)

var PackedUserOperationArgs abi.Arguments

var paymasterDataArgs abi.Arguments

type PackedUserOperation struct {
	Sender             common.Address `abi:"sender"`
	Nonce              *big.Int       `abi:"nonce"`
	InitCode           []byte         `abi:"initCode"`
	CallData           []byte         `abi:"callData"`
	AccountGasLimits   [32]byte       `abi:"accountGasLimits"`
	PreVerificationGas *big.Int       `abi:"preVerificationGas"`
	GasFees            [32]byte       `abi:"gasFees"`
	PaymasterAndData   []byte         `abi:"paymasterAndData"`
	Signature          []byte         `abi:"signature"`
}

func init() {
	var err error

	packedUserOperationArg := abi.Argument{}
	err = packedUserOperationArg.UnmarshalJSON([]byte(packedUserOperationABIJson))
	if err != nil {
		panic(fmt.Errorf("initializing PackedUserOperation ABI: %w", err))
	}

	PackedUserOperationArgs = abi.Arguments{packedUserOperationArg}

	paymasterDataArg := abi.Argument{}
	err = paymasterDataArg.UnmarshalJSON([]byte(paymasterDataABIJson))
	if err != nil {
		panic(fmt.Errorf("initializing PaymasterData ABI: %w", err))
	}

	paymasterDataArgs = abi.Arguments{paymasterDataArg}
}

func UnmarshalPackedUserOperation(data []byte) (*PackedUserOperation, error) {
	unpacked, err := PackedUserOperationArgs.Unpack(data)
	if err != nil {
		return nil, fmt.Errorf("unpacking packed user operation: %w", err)
	}

	decoded, ok := abi.ConvertType(unpacked[0], PackedUserOperation{}).(PackedUserOperation)
	if !ok {
		return nil, errors.New("invalid PackedUserOperation")
	}

	return &decoded, nil
}

func (o *PackedUserOperation) GetPaymasterData() ([][]byte, error) {
	paymasterData := o.PaymasterAndData
	if len(paymasterData) < 52 {
		return nil, fmt.Errorf("paymaster data is too short")
	}

	unpacked, err := paymasterDataArgs.Unpack(paymasterData[52:])
	if err != nil {
		return nil, fmt.Errorf("unpacking paymaster data: %w", err)
	}

	decoded, ok := abi.ConvertType(unpacked[0], [][]byte{}).([][]byte)
	if !ok {
		return nil, errors.New("invalid paymaster data")
	}

	return decoded, nil
}
