// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package rrc_7755_outbox

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// PackedUserOperation is an auto generated low-level Go binding around an user-defined struct.
type PackedUserOperation struct {
	Sender             common.Address
	Nonce              *big.Int
	InitCode           []byte
	CallData           []byte
	AccountGasLimits   [32]byte
	PreVerificationGas *big.Int
	GasFees            [32]byte
	PaymasterAndData   []byte
	Signature          []byte
}

// RRC7755OutboxMetaData contains all meta data concerning the RRC7755Outbox contract.
var RRC7755OutboxMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"CANCEL_DELAY_SECONDS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"cancelMessage\",\"inputs\":[{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"receiver\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"payload\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelUserOp\",\"inputs\":[{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"receiver\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"userOp\",\"type\":\"tuple\",\"internalType\":\"structPackedUserOperation\",\"components\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initCode\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"accountGasLimits\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"preVerificationGas\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasFees\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"paymasterAndData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimReward\",\"inputs\":[{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"receiver\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"payload\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"payTo\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimReward\",\"inputs\":[{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"receiver\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"userOp\",\"type\":\"tuple\",\"internalType\":\"structPackedUserOperation\",\"components\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initCode\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"accountGasLimits\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"preVerificationGas\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasFees\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"paymasterAndData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"proof\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"payTo\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getMessageId\",\"inputs\":[{\"name\":\"sourceChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"sender\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"receiver\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"payload\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMessageStatus\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumRRC7755Outbox.CrossChainCallStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getNonce\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getOptionalAttributes\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4[]\",\"internalType\":\"bytes4[]\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getRequesterAndExpiryAndReward\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRequiredAttributes\",\"inputs\":[{\"name\":\"isUserOp\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4[]\",\"internalType\":\"bytes4[]\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getUserOpAttributes\",\"inputs\":[{\"name\":\"userOp\",\"type\":\"tuple\",\"internalType\":\"structPackedUserOperation\",\"components\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initCode\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"accountGasLimits\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"preVerificationGas\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasFees\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"paymasterAndData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getUserOpHash\",\"inputs\":[{\"name\":\"userOp\",\"type\":\"tuple\",\"internalType\":\"structPackedUserOperation\",\"components\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"initCode\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"accountGasLimits\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"preVerificationGas\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"gasFees\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"paymasterAndData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"signature\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"receiver\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"innerValidateProofAndGetReward\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"inboxContractStorageKey\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"proofData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"processAttributes\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"requester\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"requireInbox\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"sendMessage\",\"inputs\":[{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"receiver\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"payload\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"supportsAttribute\",\"inputs\":[{\"name\":\"selector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"event\",\"name\":\"CrossChainCallCanceled\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CrossChainCallCompleted\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"submitter\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MessagePosted\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"sourceChain\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"sender\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"receiver\",\"type\":\"bytes32\",\"indexed\":false,\"internalType\":\"bytes32\"},{\"name\":\"payload\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"indexed\":false,\"internalType\":\"bytes[]\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AttributeNotFound\",\"inputs\":[{\"name\":\"selector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}]},{\"type\":\"error\",\"name\":\"CannotCancelRequestBeforeExpiry\",\"inputs\":[{\"name\":\"currentTimestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"DuplicateAttribute\",\"inputs\":[{\"name\":\"selector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}]},{\"type\":\"error\",\"name\":\"ExpiryTooSoon\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidCaller\",\"inputs\":[{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"expectedCaller\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"InvalidNonce\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidReceiver\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidRequester\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidSender\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidSourceChain\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidStatus\",\"inputs\":[{\"name\":\"expected\",\"type\":\"uint8\",\"internalType\":\"enumRRC7755Outbox.CrossChainCallStatus\"},{\"name\":\"actual\",\"type\":\"uint8\",\"internalType\":\"enumRRC7755Outbox.CrossChainCallStatus\"}]},{\"type\":\"error\",\"name\":\"InvalidValue\",\"inputs\":[{\"name\":\"expected\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"received\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"MissingRequiredAttribute\",\"inputs\":[{\"name\":\"selector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}]},{\"type\":\"error\",\"name\":\"UnsupportedAttribute\",\"inputs\":[{\"name\":\"selector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}]}]",
}

// RRC7755OutboxABI is the input ABI used to generate the binding from.
// Deprecated: Use RRC7755OutboxMetaData.ABI instead.
var RRC7755OutboxABI = RRC7755OutboxMetaData.ABI

// RRC7755Outbox is an auto generated Go binding around an Ethereum contract.
type RRC7755Outbox struct {
	RRC7755OutboxCaller     // Read-only binding to the contract
	RRC7755OutboxTransactor // Write-only binding to the contract
	RRC7755OutboxFilterer   // Log filterer for contract events
}

// RRC7755OutboxCaller is an auto generated read-only Go binding around an Ethereum contract.
type RRC7755OutboxCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RRC7755OutboxTransactor is an auto generated write-only Go binding around an Ethereum contract.
type RRC7755OutboxTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RRC7755OutboxFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type RRC7755OutboxFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RRC7755OutboxSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type RRC7755OutboxSession struct {
	Contract     *RRC7755Outbox    // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// RRC7755OutboxCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type RRC7755OutboxCallerSession struct {
	Contract *RRC7755OutboxCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts        // Call options to use throughout this session
}

// RRC7755OutboxTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type RRC7755OutboxTransactorSession struct {
	Contract     *RRC7755OutboxTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts        // Transaction auth options to use throughout this session
}

// RRC7755OutboxRaw is an auto generated low-level Go binding around an Ethereum contract.
type RRC7755OutboxRaw struct {
	Contract *RRC7755Outbox // Generic contract binding to access the raw methods on
}

// RRC7755OutboxCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type RRC7755OutboxCallerRaw struct {
	Contract *RRC7755OutboxCaller // Generic read-only contract binding to access the raw methods on
}

// RRC7755OutboxTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type RRC7755OutboxTransactorRaw struct {
	Contract *RRC7755OutboxTransactor // Generic write-only contract binding to access the raw methods on
}

// NewRRC7755Outbox creates a new instance of RRC7755Outbox, bound to a specific deployed contract.
func NewRRC7755Outbox(address common.Address, backend bind.ContractBackend) (*RRC7755Outbox, error) {
	contract, err := bindRRC7755Outbox(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &RRC7755Outbox{RRC7755OutboxCaller: RRC7755OutboxCaller{contract: contract}, RRC7755OutboxTransactor: RRC7755OutboxTransactor{contract: contract}, RRC7755OutboxFilterer: RRC7755OutboxFilterer{contract: contract}}, nil
}

// NewRRC7755OutboxCaller creates a new read-only instance of RRC7755Outbox, bound to a specific deployed contract.
func NewRRC7755OutboxCaller(address common.Address, caller bind.ContractCaller) (*RRC7755OutboxCaller, error) {
	contract, err := bindRRC7755Outbox(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &RRC7755OutboxCaller{contract: contract}, nil
}

// NewRRC7755OutboxTransactor creates a new write-only instance of RRC7755Outbox, bound to a specific deployed contract.
func NewRRC7755OutboxTransactor(address common.Address, transactor bind.ContractTransactor) (*RRC7755OutboxTransactor, error) {
	contract, err := bindRRC7755Outbox(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &RRC7755OutboxTransactor{contract: contract}, nil
}

// NewRRC7755OutboxFilterer creates a new log filterer instance of RRC7755Outbox, bound to a specific deployed contract.
func NewRRC7755OutboxFilterer(address common.Address, filterer bind.ContractFilterer) (*RRC7755OutboxFilterer, error) {
	contract, err := bindRRC7755Outbox(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &RRC7755OutboxFilterer{contract: contract}, nil
}

// bindRRC7755Outbox binds a generic wrapper to an already deployed contract.
func bindRRC7755Outbox(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := RRC7755OutboxMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RRC7755Outbox *RRC7755OutboxRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RRC7755Outbox.Contract.RRC7755OutboxCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RRC7755Outbox *RRC7755OutboxRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.RRC7755OutboxTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RRC7755Outbox *RRC7755OutboxRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.RRC7755OutboxTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RRC7755Outbox *RRC7755OutboxCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RRC7755Outbox.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RRC7755Outbox *RRC7755OutboxTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RRC7755Outbox *RRC7755OutboxTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.contract.Transact(opts, method, params...)
}

// CANCELDELAYSECONDS is a free data retrieval call binding the contract method 0xdf130c43.
//
// Solidity: function CANCEL_DELAY_SECONDS() view returns(uint256)
func (_RRC7755Outbox *RRC7755OutboxCaller) CANCELDELAYSECONDS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "CANCEL_DELAY_SECONDS")
	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err
}

// CANCELDELAYSECONDS is a free data retrieval call binding the contract method 0xdf130c43.
//
// Solidity: function CANCEL_DELAY_SECONDS() view returns(uint256)
func (_RRC7755Outbox *RRC7755OutboxSession) CANCELDELAYSECONDS() (*big.Int, error) {
	return _RRC7755Outbox.Contract.CANCELDELAYSECONDS(&_RRC7755Outbox.CallOpts)
}

// CANCELDELAYSECONDS is a free data retrieval call binding the contract method 0xdf130c43.
//
// Solidity: function CANCEL_DELAY_SECONDS() view returns(uint256)
func (_RRC7755Outbox *RRC7755OutboxCallerSession) CANCELDELAYSECONDS() (*big.Int, error) {
	return _RRC7755Outbox.Contract.CANCELDELAYSECONDS(&_RRC7755Outbox.CallOpts)
}

// GetMessageId is a free data retrieval call binding the contract method 0x002423ca.
//
// Solidity: function getMessageId(bytes32 sourceChain, bytes32 sender, bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) view returns(bytes32)
func (_RRC7755Outbox *RRC7755OutboxCaller) GetMessageId(opts *bind.CallOpts, sourceChain [32]byte, sender [32]byte, destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) ([32]byte, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "getMessageId", sourceChain, sender, destinationChain, receiver, payload, attributes)
	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err
}

// GetMessageId is a free data retrieval call binding the contract method 0x002423ca.
//
// Solidity: function getMessageId(bytes32 sourceChain, bytes32 sender, bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) view returns(bytes32)
func (_RRC7755Outbox *RRC7755OutboxSession) GetMessageId(sourceChain [32]byte, sender [32]byte, destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) ([32]byte, error) {
	return _RRC7755Outbox.Contract.GetMessageId(&_RRC7755Outbox.CallOpts, sourceChain, sender, destinationChain, receiver, payload, attributes)
}

// GetMessageId is a free data retrieval call binding the contract method 0x002423ca.
//
// Solidity: function getMessageId(bytes32 sourceChain, bytes32 sender, bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) view returns(bytes32)
func (_RRC7755Outbox *RRC7755OutboxCallerSession) GetMessageId(sourceChain [32]byte, sender [32]byte, destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) ([32]byte, error) {
	return _RRC7755Outbox.Contract.GetMessageId(&_RRC7755Outbox.CallOpts, sourceChain, sender, destinationChain, receiver, payload, attributes)
}

// GetMessageStatus is a free data retrieval call binding the contract method 0x5075a9d4.
//
// Solidity: function getMessageStatus(bytes32 messageId) view returns(uint8)
func (_RRC7755Outbox *RRC7755OutboxCaller) GetMessageStatus(opts *bind.CallOpts, messageId [32]byte) (uint8, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "getMessageStatus", messageId)
	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err
}

// GetMessageStatus is a free data retrieval call binding the contract method 0x5075a9d4.
//
// Solidity: function getMessageStatus(bytes32 messageId) view returns(uint8)
func (_RRC7755Outbox *RRC7755OutboxSession) GetMessageStatus(messageId [32]byte) (uint8, error) {
	return _RRC7755Outbox.Contract.GetMessageStatus(&_RRC7755Outbox.CallOpts, messageId)
}

// GetMessageStatus is a free data retrieval call binding the contract method 0x5075a9d4.
//
// Solidity: function getMessageStatus(bytes32 messageId) view returns(uint8)
func (_RRC7755Outbox *RRC7755OutboxCallerSession) GetMessageStatus(messageId [32]byte) (uint8, error) {
	return _RRC7755Outbox.Contract.GetMessageStatus(&_RRC7755Outbox.CallOpts, messageId)
}

// GetNonce is a free data retrieval call binding the contract method 0x2d0335ab.
//
// Solidity: function getNonce(address account) view returns(uint256)
func (_RRC7755Outbox *RRC7755OutboxCaller) GetNonce(opts *bind.CallOpts, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "getNonce", account)
	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err
}

// GetNonce is a free data retrieval call binding the contract method 0x2d0335ab.
//
// Solidity: function getNonce(address account) view returns(uint256)
func (_RRC7755Outbox *RRC7755OutboxSession) GetNonce(account common.Address) (*big.Int, error) {
	return _RRC7755Outbox.Contract.GetNonce(&_RRC7755Outbox.CallOpts, account)
}

// GetNonce is a free data retrieval call binding the contract method 0x2d0335ab.
//
// Solidity: function getNonce(address account) view returns(uint256)
func (_RRC7755Outbox *RRC7755OutboxCallerSession) GetNonce(account common.Address) (*big.Int, error) {
	return _RRC7755Outbox.Contract.GetNonce(&_RRC7755Outbox.CallOpts, account)
}

// GetOptionalAttributes is a free data retrieval call binding the contract method 0x1ec3f40f.
//
// Solidity: function getOptionalAttributes() pure returns(bytes4[])
func (_RRC7755Outbox *RRC7755OutboxCaller) GetOptionalAttributes(opts *bind.CallOpts) ([][4]byte, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "getOptionalAttributes")
	if err != nil {
		return *new([][4]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([][4]byte)).(*[][4]byte)

	return out0, err
}

// GetOptionalAttributes is a free data retrieval call binding the contract method 0x1ec3f40f.
//
// Solidity: function getOptionalAttributes() pure returns(bytes4[])
func (_RRC7755Outbox *RRC7755OutboxSession) GetOptionalAttributes() ([][4]byte, error) {
	return _RRC7755Outbox.Contract.GetOptionalAttributes(&_RRC7755Outbox.CallOpts)
}

// GetOptionalAttributes is a free data retrieval call binding the contract method 0x1ec3f40f.
//
// Solidity: function getOptionalAttributes() pure returns(bytes4[])
func (_RRC7755Outbox *RRC7755OutboxCallerSession) GetOptionalAttributes() ([][4]byte, error) {
	return _RRC7755Outbox.Contract.GetOptionalAttributes(&_RRC7755Outbox.CallOpts)
}

// GetRequesterAndExpiryAndReward is a free data retrieval call binding the contract method 0x11e5a80e.
//
// Solidity: function getRequesterAndExpiryAndReward(bytes32 messageId, bytes[] attributes) view returns(bytes32, uint256, bytes32, uint256)
func (_RRC7755Outbox *RRC7755OutboxCaller) GetRequesterAndExpiryAndReward(opts *bind.CallOpts, messageId [32]byte, attributes [][]byte) ([32]byte, *big.Int, [32]byte, *big.Int, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "getRequesterAndExpiryAndReward", messageId, attributes)
	if err != nil {
		return *new([32]byte), *new(*big.Int), *new([32]byte), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	out2 := *abi.ConvertType(out[2], new([32]byte)).(*[32]byte)
	out3 := *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return out0, out1, out2, out3, err
}

// GetRequesterAndExpiryAndReward is a free data retrieval call binding the contract method 0x11e5a80e.
//
// Solidity: function getRequesterAndExpiryAndReward(bytes32 messageId, bytes[] attributes) view returns(bytes32, uint256, bytes32, uint256)
func (_RRC7755Outbox *RRC7755OutboxSession) GetRequesterAndExpiryAndReward(messageId [32]byte, attributes [][]byte) ([32]byte, *big.Int, [32]byte, *big.Int, error) {
	return _RRC7755Outbox.Contract.GetRequesterAndExpiryAndReward(&_RRC7755Outbox.CallOpts, messageId, attributes)
}

// GetRequesterAndExpiryAndReward is a free data retrieval call binding the contract method 0x11e5a80e.
//
// Solidity: function getRequesterAndExpiryAndReward(bytes32 messageId, bytes[] attributes) view returns(bytes32, uint256, bytes32, uint256)
func (_RRC7755Outbox *RRC7755OutboxCallerSession) GetRequesterAndExpiryAndReward(messageId [32]byte, attributes [][]byte) ([32]byte, *big.Int, [32]byte, *big.Int, error) {
	return _RRC7755Outbox.Contract.GetRequesterAndExpiryAndReward(&_RRC7755Outbox.CallOpts, messageId, attributes)
}

// GetRequiredAttributes is a free data retrieval call binding the contract method 0x050634f5.
//
// Solidity: function getRequiredAttributes(bool isUserOp) pure returns(bytes4[])
func (_RRC7755Outbox *RRC7755OutboxCaller) GetRequiredAttributes(opts *bind.CallOpts, isUserOp bool) ([][4]byte, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "getRequiredAttributes", isUserOp)
	if err != nil {
		return *new([][4]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([][4]byte)).(*[][4]byte)

	return out0, err
}

// GetRequiredAttributes is a free data retrieval call binding the contract method 0x050634f5.
//
// Solidity: function getRequiredAttributes(bool isUserOp) pure returns(bytes4[])
func (_RRC7755Outbox *RRC7755OutboxSession) GetRequiredAttributes(isUserOp bool) ([][4]byte, error) {
	return _RRC7755Outbox.Contract.GetRequiredAttributes(&_RRC7755Outbox.CallOpts, isUserOp)
}

// GetRequiredAttributes is a free data retrieval call binding the contract method 0x050634f5.
//
// Solidity: function getRequiredAttributes(bool isUserOp) pure returns(bytes4[])
func (_RRC7755Outbox *RRC7755OutboxCallerSession) GetRequiredAttributes(isUserOp bool) ([][4]byte, error) {
	return _RRC7755Outbox.Contract.GetRequiredAttributes(&_RRC7755Outbox.CallOpts, isUserOp)
}

// GetUserOpAttributes is a free data retrieval call binding the contract method 0x894d5bb6.
//
// Solidity: function getUserOpAttributes((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp) pure returns(bytes[])
func (_RRC7755Outbox *RRC7755OutboxCaller) GetUserOpAttributes(opts *bind.CallOpts, userOp PackedUserOperation) ([][]byte, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "getUserOpAttributes", userOp)
	if err != nil {
		return *new([][]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([][]byte)).(*[][]byte)

	return out0, err
}

// GetUserOpAttributes is a free data retrieval call binding the contract method 0x894d5bb6.
//
// Solidity: function getUserOpAttributes((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp) pure returns(bytes[])
func (_RRC7755Outbox *RRC7755OutboxSession) GetUserOpAttributes(userOp PackedUserOperation) ([][]byte, error) {
	return _RRC7755Outbox.Contract.GetUserOpAttributes(&_RRC7755Outbox.CallOpts, userOp)
}

// GetUserOpAttributes is a free data retrieval call binding the contract method 0x894d5bb6.
//
// Solidity: function getUserOpAttributes((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp) pure returns(bytes[])
func (_RRC7755Outbox *RRC7755OutboxCallerSession) GetUserOpAttributes(userOp PackedUserOperation) ([][]byte, error) {
	return _RRC7755Outbox.Contract.GetUserOpAttributes(&_RRC7755Outbox.CallOpts, userOp)
}

// GetUserOpHash is a free data retrieval call binding the contract method 0x7ba8d5f2.
//
// Solidity: function getUserOpHash((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp, bytes32 receiver, bytes32 destinationChain) pure returns(bytes32)
func (_RRC7755Outbox *RRC7755OutboxCaller) GetUserOpHash(opts *bind.CallOpts, userOp PackedUserOperation, receiver [32]byte, destinationChain [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "getUserOpHash", userOp, receiver, destinationChain)
	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err
}

// GetUserOpHash is a free data retrieval call binding the contract method 0x7ba8d5f2.
//
// Solidity: function getUserOpHash((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp, bytes32 receiver, bytes32 destinationChain) pure returns(bytes32)
func (_RRC7755Outbox *RRC7755OutboxSession) GetUserOpHash(userOp PackedUserOperation, receiver [32]byte, destinationChain [32]byte) ([32]byte, error) {
	return _RRC7755Outbox.Contract.GetUserOpHash(&_RRC7755Outbox.CallOpts, userOp, receiver, destinationChain)
}

// GetUserOpHash is a free data retrieval call binding the contract method 0x7ba8d5f2.
//
// Solidity: function getUserOpHash((address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp, bytes32 receiver, bytes32 destinationChain) pure returns(bytes32)
func (_RRC7755Outbox *RRC7755OutboxCallerSession) GetUserOpHash(userOp PackedUserOperation, receiver [32]byte, destinationChain [32]byte) ([32]byte, error) {
	return _RRC7755Outbox.Contract.GetUserOpHash(&_RRC7755Outbox.CallOpts, userOp, receiver, destinationChain)
}

// InnerValidateProofAndGetReward is a free data retrieval call binding the contract method 0x0ce8ec28.
//
// Solidity: function innerValidateProofAndGetReward(bytes32 messageId, bytes32 destinationChain, bytes inboxContractStorageKey, bytes[] attributes, bytes proofData, address caller) view returns(bytes32, uint256)
func (_RRC7755Outbox *RRC7755OutboxCaller) InnerValidateProofAndGetReward(opts *bind.CallOpts, messageId [32]byte, destinationChain [32]byte, inboxContractStorageKey []byte, attributes [][]byte, proofData []byte, caller common.Address) ([32]byte, *big.Int, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "innerValidateProofAndGetReward", messageId, destinationChain, inboxContractStorageKey, attributes, proofData, caller)
	if err != nil {
		return *new([32]byte), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return out0, out1, err
}

// InnerValidateProofAndGetReward is a free data retrieval call binding the contract method 0x0ce8ec28.
//
// Solidity: function innerValidateProofAndGetReward(bytes32 messageId, bytes32 destinationChain, bytes inboxContractStorageKey, bytes[] attributes, bytes proofData, address caller) view returns(bytes32, uint256)
func (_RRC7755Outbox *RRC7755OutboxSession) InnerValidateProofAndGetReward(messageId [32]byte, destinationChain [32]byte, inboxContractStorageKey []byte, attributes [][]byte, proofData []byte, caller common.Address) ([32]byte, *big.Int, error) {
	return _RRC7755Outbox.Contract.InnerValidateProofAndGetReward(&_RRC7755Outbox.CallOpts, messageId, destinationChain, inboxContractStorageKey, attributes, proofData, caller)
}

// InnerValidateProofAndGetReward is a free data retrieval call binding the contract method 0x0ce8ec28.
//
// Solidity: function innerValidateProofAndGetReward(bytes32 messageId, bytes32 destinationChain, bytes inboxContractStorageKey, bytes[] attributes, bytes proofData, address caller) view returns(bytes32, uint256)
func (_RRC7755Outbox *RRC7755OutboxCallerSession) InnerValidateProofAndGetReward(messageId [32]byte, destinationChain [32]byte, inboxContractStorageKey []byte, attributes [][]byte, proofData []byte, caller common.Address) ([32]byte, *big.Int, error) {
	return _RRC7755Outbox.Contract.InnerValidateProofAndGetReward(&_RRC7755Outbox.CallOpts, messageId, destinationChain, inboxContractStorageKey, attributes, proofData, caller)
}

// SupportsAttribute is a free data retrieval call binding the contract method 0xdc680a0f.
//
// Solidity: function supportsAttribute(bytes4 selector) pure returns(bool)
func (_RRC7755Outbox *RRC7755OutboxCaller) SupportsAttribute(opts *bind.CallOpts, selector [4]byte) (bool, error) {
	var out []interface{}
	err := _RRC7755Outbox.contract.Call(opts, &out, "supportsAttribute", selector)
	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err
}

// SupportsAttribute is a free data retrieval call binding the contract method 0xdc680a0f.
//
// Solidity: function supportsAttribute(bytes4 selector) pure returns(bool)
func (_RRC7755Outbox *RRC7755OutboxSession) SupportsAttribute(selector [4]byte) (bool, error) {
	return _RRC7755Outbox.Contract.SupportsAttribute(&_RRC7755Outbox.CallOpts, selector)
}

// SupportsAttribute is a free data retrieval call binding the contract method 0xdc680a0f.
//
// Solidity: function supportsAttribute(bytes4 selector) pure returns(bool)
func (_RRC7755Outbox *RRC7755OutboxCallerSession) SupportsAttribute(selector [4]byte) (bool, error) {
	return _RRC7755Outbox.Contract.SupportsAttribute(&_RRC7755Outbox.CallOpts, selector)
}

// CancelMessage is a paid mutator transaction binding the contract method 0x24afce1c.
//
// Solidity: function cancelMessage(bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactor) CancelMessage(opts *bind.TransactOpts, destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) (*types.Transaction, error) {
	return _RRC7755Outbox.contract.Transact(opts, "cancelMessage", destinationChain, receiver, payload, attributes)
}

// CancelMessage is a paid mutator transaction binding the contract method 0x24afce1c.
//
// Solidity: function cancelMessage(bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) returns()
func (_RRC7755Outbox *RRC7755OutboxSession) CancelMessage(destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.CancelMessage(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, payload, attributes)
}

// CancelMessage is a paid mutator transaction binding the contract method 0x24afce1c.
//
// Solidity: function cancelMessage(bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactorSession) CancelMessage(destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.CancelMessage(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, payload, attributes)
}

// CancelUserOp is a paid mutator transaction binding the contract method 0xf1584add.
//
// Solidity: function cancelUserOp(bytes32 destinationChain, bytes32 receiver, (address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactor) CancelUserOp(opts *bind.TransactOpts, destinationChain [32]byte, receiver [32]byte, userOp PackedUserOperation) (*types.Transaction, error) {
	return _RRC7755Outbox.contract.Transact(opts, "cancelUserOp", destinationChain, receiver, userOp)
}

// CancelUserOp is a paid mutator transaction binding the contract method 0xf1584add.
//
// Solidity: function cancelUserOp(bytes32 destinationChain, bytes32 receiver, (address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp) returns()
func (_RRC7755Outbox *RRC7755OutboxSession) CancelUserOp(destinationChain [32]byte, receiver [32]byte, userOp PackedUserOperation) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.CancelUserOp(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, userOp)
}

// CancelUserOp is a paid mutator transaction binding the contract method 0xf1584add.
//
// Solidity: function cancelUserOp(bytes32 destinationChain, bytes32 receiver, (address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactorSession) CancelUserOp(destinationChain [32]byte, receiver [32]byte, userOp PackedUserOperation) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.CancelUserOp(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, userOp)
}

// ClaimReward is a paid mutator transaction binding the contract method 0x2673fa9c.
//
// Solidity: function claimReward(bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes, bytes proof, address payTo) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactor) ClaimReward(opts *bind.TransactOpts, destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte, proof []byte, payTo common.Address) (*types.Transaction, error) {
	return _RRC7755Outbox.contract.Transact(opts, "claimReward", destinationChain, receiver, payload, attributes, proof, payTo)
}

// ClaimReward is a paid mutator transaction binding the contract method 0x2673fa9c.
//
// Solidity: function claimReward(bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes, bytes proof, address payTo) returns()
func (_RRC7755Outbox *RRC7755OutboxSession) ClaimReward(destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte, proof []byte, payTo common.Address) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.ClaimReward(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, payload, attributes, proof, payTo)
}

// ClaimReward is a paid mutator transaction binding the contract method 0x2673fa9c.
//
// Solidity: function claimReward(bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes, bytes proof, address payTo) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactorSession) ClaimReward(destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte, proof []byte, payTo common.Address) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.ClaimReward(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, payload, attributes, proof, payTo)
}

// ClaimReward0 is a paid mutator transaction binding the contract method 0x87f64a45.
//
// Solidity: function claimReward(bytes32 destinationChain, bytes32 receiver, (address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp, bytes proof, address payTo) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactor) ClaimReward0(opts *bind.TransactOpts, destinationChain [32]byte, receiver [32]byte, userOp PackedUserOperation, proof []byte, payTo common.Address) (*types.Transaction, error) {
	return _RRC7755Outbox.contract.Transact(opts, "claimReward0", destinationChain, receiver, userOp, proof, payTo)
}

// ClaimReward0 is a paid mutator transaction binding the contract method 0x87f64a45.
//
// Solidity: function claimReward(bytes32 destinationChain, bytes32 receiver, (address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp, bytes proof, address payTo) returns()
func (_RRC7755Outbox *RRC7755OutboxSession) ClaimReward0(destinationChain [32]byte, receiver [32]byte, userOp PackedUserOperation, proof []byte, payTo common.Address) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.ClaimReward0(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, userOp, proof, payTo)
}

// ClaimReward0 is a paid mutator transaction binding the contract method 0x87f64a45.
//
// Solidity: function claimReward(bytes32 destinationChain, bytes32 receiver, (address,uint256,bytes,bytes,bytes32,uint256,bytes32,bytes,bytes) userOp, bytes proof, address payTo) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactorSession) ClaimReward0(destinationChain [32]byte, receiver [32]byte, userOp PackedUserOperation, proof []byte, payTo common.Address) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.ClaimReward0(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, userOp, proof, payTo)
}

// ProcessAttributes is a paid mutator transaction binding the contract method 0x554dd512.
//
// Solidity: function processAttributes(bytes32 messageId, bytes[] attributes, address requester, uint256 value, bool requireInbox) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactor) ProcessAttributes(opts *bind.TransactOpts, messageId [32]byte, attributes [][]byte, requester common.Address, value *big.Int, requireInbox bool) (*types.Transaction, error) {
	return _RRC7755Outbox.contract.Transact(opts, "processAttributes", messageId, attributes, requester, value, requireInbox)
}

// ProcessAttributes is a paid mutator transaction binding the contract method 0x554dd512.
//
// Solidity: function processAttributes(bytes32 messageId, bytes[] attributes, address requester, uint256 value, bool requireInbox) returns()
func (_RRC7755Outbox *RRC7755OutboxSession) ProcessAttributes(messageId [32]byte, attributes [][]byte, requester common.Address, value *big.Int, requireInbox bool) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.ProcessAttributes(&_RRC7755Outbox.TransactOpts, messageId, attributes, requester, value, requireInbox)
}

// ProcessAttributes is a paid mutator transaction binding the contract method 0x554dd512.
//
// Solidity: function processAttributes(bytes32 messageId, bytes[] attributes, address requester, uint256 value, bool requireInbox) returns()
func (_RRC7755Outbox *RRC7755OutboxTransactorSession) ProcessAttributes(messageId [32]byte, attributes [][]byte, requester common.Address, value *big.Int, requireInbox bool) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.ProcessAttributes(&_RRC7755Outbox.TransactOpts, messageId, attributes, requester, value, requireInbox)
}

// SendMessage is a paid mutator transaction binding the contract method 0xfff34eb9.
//
// Solidity: function sendMessage(bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) payable returns(bytes32)
func (_RRC7755Outbox *RRC7755OutboxTransactor) SendMessage(opts *bind.TransactOpts, destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) (*types.Transaction, error) {
	return _RRC7755Outbox.contract.Transact(opts, "sendMessage", destinationChain, receiver, payload, attributes)
}

// SendMessage is a paid mutator transaction binding the contract method 0xfff34eb9.
//
// Solidity: function sendMessage(bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) payable returns(bytes32)
func (_RRC7755Outbox *RRC7755OutboxSession) SendMessage(destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.SendMessage(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, payload, attributes)
}

// SendMessage is a paid mutator transaction binding the contract method 0xfff34eb9.
//
// Solidity: function sendMessage(bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) payable returns(bytes32)
func (_RRC7755Outbox *RRC7755OutboxTransactorSession) SendMessage(destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) (*types.Transaction, error) {
	return _RRC7755Outbox.Contract.SendMessage(&_RRC7755Outbox.TransactOpts, destinationChain, receiver, payload, attributes)
}

// RRC7755OutboxCrossChainCallCanceledIterator is returned from FilterCrossChainCallCanceled and is used to iterate over the raw logs and unpacked data for CrossChainCallCanceled events raised by the RRC7755Outbox contract.
type RRC7755OutboxCrossChainCallCanceledIterator struct {
	Event *RRC7755OutboxCrossChainCallCanceled // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RRC7755OutboxCrossChainCallCanceledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RRC7755OutboxCrossChainCallCanceled)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RRC7755OutboxCrossChainCallCanceled)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RRC7755OutboxCrossChainCallCanceledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RRC7755OutboxCrossChainCallCanceledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RRC7755OutboxCrossChainCallCanceled represents a CrossChainCallCanceled event raised by the RRC7755Outbox contract.
type RRC7755OutboxCrossChainCallCanceled struct {
	MessageId [32]byte
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterCrossChainCallCanceled is a free log retrieval operation binding the contract event 0x1be39b5d9d7a848f6e4636bfaf521d9a6b7a351a73c7d0e945b79ffc7e169346.
//
// Solidity: event CrossChainCallCanceled(bytes32 indexed messageId)
func (_RRC7755Outbox *RRC7755OutboxFilterer) FilterCrossChainCallCanceled(opts *bind.FilterOpts, messageId [][32]byte) (*RRC7755OutboxCrossChainCallCanceledIterator, error) {
	var messageIdRule []interface{}
	for _, messageIdItem := range messageId {
		messageIdRule = append(messageIdRule, messageIdItem)
	}

	logs, sub, err := _RRC7755Outbox.contract.FilterLogs(opts, "CrossChainCallCanceled", messageIdRule)
	if err != nil {
		return nil, err
	}
	return &RRC7755OutboxCrossChainCallCanceledIterator{contract: _RRC7755Outbox.contract, event: "CrossChainCallCanceled", logs: logs, sub: sub}, nil
}

// WatchCrossChainCallCanceled is a free log subscription operation binding the contract event 0x1be39b5d9d7a848f6e4636bfaf521d9a6b7a351a73c7d0e945b79ffc7e169346.
//
// Solidity: event CrossChainCallCanceled(bytes32 indexed messageId)
func (_RRC7755Outbox *RRC7755OutboxFilterer) WatchCrossChainCallCanceled(opts *bind.WatchOpts, sink chan<- *RRC7755OutboxCrossChainCallCanceled, messageId [][32]byte) (event.Subscription, error) {
	var messageIdRule []interface{}
	for _, messageIdItem := range messageId {
		messageIdRule = append(messageIdRule, messageIdItem)
	}

	logs, sub, err := _RRC7755Outbox.contract.WatchLogs(opts, "CrossChainCallCanceled", messageIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RRC7755OutboxCrossChainCallCanceled)
				if err := _RRC7755Outbox.contract.UnpackLog(event, "CrossChainCallCanceled", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCrossChainCallCanceled is a log parse operation binding the contract event 0x1be39b5d9d7a848f6e4636bfaf521d9a6b7a351a73c7d0e945b79ffc7e169346.
//
// Solidity: event CrossChainCallCanceled(bytes32 indexed messageId)
func (_RRC7755Outbox *RRC7755OutboxFilterer) ParseCrossChainCallCanceled(log types.Log) (*RRC7755OutboxCrossChainCallCanceled, error) {
	event := new(RRC7755OutboxCrossChainCallCanceled)
	if err := _RRC7755Outbox.contract.UnpackLog(event, "CrossChainCallCanceled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RRC7755OutboxCrossChainCallCompletedIterator is returned from FilterCrossChainCallCompleted and is used to iterate over the raw logs and unpacked data for CrossChainCallCompleted events raised by the RRC7755Outbox contract.
type RRC7755OutboxCrossChainCallCompletedIterator struct {
	Event *RRC7755OutboxCrossChainCallCompleted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RRC7755OutboxCrossChainCallCompletedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RRC7755OutboxCrossChainCallCompleted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RRC7755OutboxCrossChainCallCompleted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RRC7755OutboxCrossChainCallCompletedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RRC7755OutboxCrossChainCallCompletedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RRC7755OutboxCrossChainCallCompleted represents a CrossChainCallCompleted event raised by the RRC7755Outbox contract.
type RRC7755OutboxCrossChainCallCompleted struct {
	MessageId [32]byte
	Submitter common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterCrossChainCallCompleted is a free log retrieval operation binding the contract event 0xcdfa980156c3785ecdc674a3131566e601d6e2b8025f31d3c8d6318c5f1c87a5.
//
// Solidity: event CrossChainCallCompleted(bytes32 indexed messageId, address submitter)
func (_RRC7755Outbox *RRC7755OutboxFilterer) FilterCrossChainCallCompleted(opts *bind.FilterOpts, messageId [][32]byte) (*RRC7755OutboxCrossChainCallCompletedIterator, error) {
	var messageIdRule []interface{}
	for _, messageIdItem := range messageId {
		messageIdRule = append(messageIdRule, messageIdItem)
	}

	logs, sub, err := _RRC7755Outbox.contract.FilterLogs(opts, "CrossChainCallCompleted", messageIdRule)
	if err != nil {
		return nil, err
	}
	return &RRC7755OutboxCrossChainCallCompletedIterator{contract: _RRC7755Outbox.contract, event: "CrossChainCallCompleted", logs: logs, sub: sub}, nil
}

// WatchCrossChainCallCompleted is a free log subscription operation binding the contract event 0xcdfa980156c3785ecdc674a3131566e601d6e2b8025f31d3c8d6318c5f1c87a5.
//
// Solidity: event CrossChainCallCompleted(bytes32 indexed messageId, address submitter)
func (_RRC7755Outbox *RRC7755OutboxFilterer) WatchCrossChainCallCompleted(opts *bind.WatchOpts, sink chan<- *RRC7755OutboxCrossChainCallCompleted, messageId [][32]byte) (event.Subscription, error) {
	var messageIdRule []interface{}
	for _, messageIdItem := range messageId {
		messageIdRule = append(messageIdRule, messageIdItem)
	}

	logs, sub, err := _RRC7755Outbox.contract.WatchLogs(opts, "CrossChainCallCompleted", messageIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RRC7755OutboxCrossChainCallCompleted)
				if err := _RRC7755Outbox.contract.UnpackLog(event, "CrossChainCallCompleted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCrossChainCallCompleted is a log parse operation binding the contract event 0xcdfa980156c3785ecdc674a3131566e601d6e2b8025f31d3c8d6318c5f1c87a5.
//
// Solidity: event CrossChainCallCompleted(bytes32 indexed messageId, address submitter)
func (_RRC7755Outbox *RRC7755OutboxFilterer) ParseCrossChainCallCompleted(log types.Log) (*RRC7755OutboxCrossChainCallCompleted, error) {
	event := new(RRC7755OutboxCrossChainCallCompleted)
	if err := _RRC7755Outbox.contract.UnpackLog(event, "CrossChainCallCompleted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RRC7755OutboxMessagePostedIterator is returned from FilterMessagePosted and is used to iterate over the raw logs and unpacked data for MessagePosted events raised by the RRC7755Outbox contract.
type RRC7755OutboxMessagePostedIterator struct {
	Event *RRC7755OutboxMessagePosted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RRC7755OutboxMessagePostedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RRC7755OutboxMessagePosted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RRC7755OutboxMessagePosted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RRC7755OutboxMessagePostedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RRC7755OutboxMessagePostedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RRC7755OutboxMessagePosted represents a MessagePosted event raised by the RRC7755Outbox contract.
type RRC7755OutboxMessagePosted struct {
	MessageId        [32]byte
	SourceChain      [32]byte
	Sender           [32]byte
	DestinationChain [32]byte
	Receiver         [32]byte
	Payload          []byte
	Attributes       [][]byte
	Raw              types.Log // Blockchain specific contextual infos
}

// FilterMessagePosted is a free log retrieval operation binding the contract event 0x8c3e2b6a5f9f3998732307b6e6be96b5c909d7801671bffa843457af80ccc21f.
//
// Solidity: event MessagePosted(bytes32 indexed messageId, bytes32 sourceChain, bytes32 sender, bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes)
func (_RRC7755Outbox *RRC7755OutboxFilterer) FilterMessagePosted(opts *bind.FilterOpts, messageId [][32]byte) (*RRC7755OutboxMessagePostedIterator, error) {
	var messageIdRule []interface{}
	for _, messageIdItem := range messageId {
		messageIdRule = append(messageIdRule, messageIdItem)
	}

	logs, sub, err := _RRC7755Outbox.contract.FilterLogs(opts, "MessagePosted", messageIdRule)
	if err != nil {
		return nil, err
	}
	return &RRC7755OutboxMessagePostedIterator{contract: _RRC7755Outbox.contract, event: "MessagePosted", logs: logs, sub: sub}, nil
}

// WatchMessagePosted is a free log subscription operation binding the contract event 0x8c3e2b6a5f9f3998732307b6e6be96b5c909d7801671bffa843457af80ccc21f.
//
// Solidity: event MessagePosted(bytes32 indexed messageId, bytes32 sourceChain, bytes32 sender, bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes)
func (_RRC7755Outbox *RRC7755OutboxFilterer) WatchMessagePosted(opts *bind.WatchOpts, sink chan<- *RRC7755OutboxMessagePosted, messageId [][32]byte) (event.Subscription, error) {
	var messageIdRule []interface{}
	for _, messageIdItem := range messageId {
		messageIdRule = append(messageIdRule, messageIdItem)
	}

	logs, sub, err := _RRC7755Outbox.contract.WatchLogs(opts, "MessagePosted", messageIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RRC7755OutboxMessagePosted)
				if err := _RRC7755Outbox.contract.UnpackLog(event, "MessagePosted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMessagePosted is a log parse operation binding the contract event 0x8c3e2b6a5f9f3998732307b6e6be96b5c909d7801671bffa843457af80ccc21f.
//
// Solidity: event MessagePosted(bytes32 indexed messageId, bytes32 sourceChain, bytes32 sender, bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes)
func (_RRC7755Outbox *RRC7755OutboxFilterer) ParseMessagePosted(log types.Log) (*RRC7755OutboxMessagePosted, error) {
	event := new(RRC7755OutboxMessagePosted)
	if err := _RRC7755Outbox.contract.UnpackLog(event, "MessagePosted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
