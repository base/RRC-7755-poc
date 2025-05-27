// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package rrc_7755_inbox

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

// RRC7755InboxFulfillmentInfo is an auto generated low-level Go binding around an user-defined struct.
type RRC7755InboxFulfillmentInfo struct {
	Timestamp *big.Int
	Fulfiller common.Address
}

// RRC7755InboxMetaData contains all meta data concerning the RRC7755Inbox contract.
var RRC7755InboxMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"paymaster\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"receive\",\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"PAYMASTER\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractPaymaster\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"fulfill\",\"inputs\":[{\"name\":\"sourceChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"sender\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"payload\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"fulfiller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"getFulfillmentInfo\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structRRC7755Inbox.FulfillmentInfo\",\"components\":[{\"name\":\"timestamp\",\"type\":\"uint96\",\"internalType\":\"uint96\"},{\"name\":\"fulfiller\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMessageId\",\"inputs\":[{\"name\":\"sourceChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"sender\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"destinationChain\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"receiver\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"payload\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"attributes\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"storeReceipt\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"fulfiller\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"CallFulfilled\",\"inputs\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"fulfilledBy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AttributeNotFound\",\"inputs\":[{\"name\":\"selector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}]},{\"type\":\"error\",\"name\":\"CallAlreadyFulfilled\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CannotCallPaymaster\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DuplicateAttribute\",\"inputs\":[{\"name\":\"selector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}]},{\"type\":\"error\",\"name\":\"InvalidCaller\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"Reentrancy\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UserOp\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZeroAddress\",\"inputs\":[]}]",
}

// RRC7755InboxABI is the input ABI used to generate the binding from.
// Deprecated: Use RRC7755InboxMetaData.ABI instead.
var RRC7755InboxABI = RRC7755InboxMetaData.ABI

// RRC7755Inbox is an auto generated Go binding around an Ethereum contract.
type RRC7755Inbox struct {
	RRC7755InboxCaller     // Read-only binding to the contract
	RRC7755InboxTransactor // Write-only binding to the contract
	RRC7755InboxFilterer   // Log filterer for contract events
}

// RRC7755InboxCaller is an auto generated read-only Go binding around an Ethereum contract.
type RRC7755InboxCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RRC7755InboxTransactor is an auto generated write-only Go binding around an Ethereum contract.
type RRC7755InboxTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RRC7755InboxFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type RRC7755InboxFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RRC7755InboxSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type RRC7755InboxSession struct {
	Contract     *RRC7755Inbox     // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// RRC7755InboxCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type RRC7755InboxCallerSession struct {
	Contract *RRC7755InboxCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts       // Call options to use throughout this session
}

// RRC7755InboxTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type RRC7755InboxTransactorSession struct {
	Contract     *RRC7755InboxTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts       // Transaction auth options to use throughout this session
}

// RRC7755InboxRaw is an auto generated low-level Go binding around an Ethereum contract.
type RRC7755InboxRaw struct {
	Contract *RRC7755Inbox // Generic contract binding to access the raw methods on
}

// RRC7755InboxCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type RRC7755InboxCallerRaw struct {
	Contract *RRC7755InboxCaller // Generic read-only contract binding to access the raw methods on
}

// RRC7755InboxTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type RRC7755InboxTransactorRaw struct {
	Contract *RRC7755InboxTransactor // Generic write-only contract binding to access the raw methods on
}

// NewRRC7755Inbox creates a new instance of RRC7755Inbox, bound to a specific deployed contract.
func NewRRC7755Inbox(address common.Address, backend bind.ContractBackend) (*RRC7755Inbox, error) {
	contract, err := bindRRC7755Inbox(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &RRC7755Inbox{RRC7755InboxCaller: RRC7755InboxCaller{contract: contract}, RRC7755InboxTransactor: RRC7755InboxTransactor{contract: contract}, RRC7755InboxFilterer: RRC7755InboxFilterer{contract: contract}}, nil
}

// NewRRC7755InboxCaller creates a new read-only instance of RRC7755Inbox, bound to a specific deployed contract.
func NewRRC7755InboxCaller(address common.Address, caller bind.ContractCaller) (*RRC7755InboxCaller, error) {
	contract, err := bindRRC7755Inbox(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &RRC7755InboxCaller{contract: contract}, nil
}

// NewRRC7755InboxTransactor creates a new write-only instance of RRC7755Inbox, bound to a specific deployed contract.
func NewRRC7755InboxTransactor(address common.Address, transactor bind.ContractTransactor) (*RRC7755InboxTransactor, error) {
	contract, err := bindRRC7755Inbox(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &RRC7755InboxTransactor{contract: contract}, nil
}

// NewRRC7755InboxFilterer creates a new log filterer instance of RRC7755Inbox, bound to a specific deployed contract.
func NewRRC7755InboxFilterer(address common.Address, filterer bind.ContractFilterer) (*RRC7755InboxFilterer, error) {
	contract, err := bindRRC7755Inbox(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &RRC7755InboxFilterer{contract: contract}, nil
}

// bindRRC7755Inbox binds a generic wrapper to an already deployed contract.
func bindRRC7755Inbox(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := RRC7755InboxMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RRC7755Inbox *RRC7755InboxRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RRC7755Inbox.Contract.RRC7755InboxCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RRC7755Inbox *RRC7755InboxRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.RRC7755InboxTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RRC7755Inbox *RRC7755InboxRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.RRC7755InboxTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RRC7755Inbox *RRC7755InboxCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RRC7755Inbox.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RRC7755Inbox *RRC7755InboxTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RRC7755Inbox *RRC7755InboxTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.contract.Transact(opts, method, params...)
}

// PAYMASTER is a free data retrieval call binding the contract method 0x82c78fb8.
//
// Solidity: function PAYMASTER() view returns(address)
func (_RRC7755Inbox *RRC7755InboxCaller) PAYMASTER(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RRC7755Inbox.contract.Call(opts, &out, "PAYMASTER")
	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err
}

// PAYMASTER is a free data retrieval call binding the contract method 0x82c78fb8.
//
// Solidity: function PAYMASTER() view returns(address)
func (_RRC7755Inbox *RRC7755InboxSession) PAYMASTER() (common.Address, error) {
	return _RRC7755Inbox.Contract.PAYMASTER(&_RRC7755Inbox.CallOpts)
}

// PAYMASTER is a free data retrieval call binding the contract method 0x82c78fb8.
//
// Solidity: function PAYMASTER() view returns(address)
func (_RRC7755Inbox *RRC7755InboxCallerSession) PAYMASTER() (common.Address, error) {
	return _RRC7755Inbox.Contract.PAYMASTER(&_RRC7755Inbox.CallOpts)
}

// GetFulfillmentInfo is a free data retrieval call binding the contract method 0x67142b21.
//
// Solidity: function getFulfillmentInfo(bytes32 messageId) view returns((uint96,address))
func (_RRC7755Inbox *RRC7755InboxCaller) GetFulfillmentInfo(opts *bind.CallOpts, messageId [32]byte) (RRC7755InboxFulfillmentInfo, error) {
	var out []interface{}
	err := _RRC7755Inbox.contract.Call(opts, &out, "getFulfillmentInfo", messageId)
	if err != nil {
		return *new(RRC7755InboxFulfillmentInfo), err
	}

	out0 := *abi.ConvertType(out[0], new(RRC7755InboxFulfillmentInfo)).(*RRC7755InboxFulfillmentInfo)

	return out0, err
}

// GetFulfillmentInfo is a free data retrieval call binding the contract method 0x67142b21.
//
// Solidity: function getFulfillmentInfo(bytes32 messageId) view returns((uint96,address))
func (_RRC7755Inbox *RRC7755InboxSession) GetFulfillmentInfo(messageId [32]byte) (RRC7755InboxFulfillmentInfo, error) {
	return _RRC7755Inbox.Contract.GetFulfillmentInfo(&_RRC7755Inbox.CallOpts, messageId)
}

// GetFulfillmentInfo is a free data retrieval call binding the contract method 0x67142b21.
//
// Solidity: function getFulfillmentInfo(bytes32 messageId) view returns((uint96,address))
func (_RRC7755Inbox *RRC7755InboxCallerSession) GetFulfillmentInfo(messageId [32]byte) (RRC7755InboxFulfillmentInfo, error) {
	return _RRC7755Inbox.Contract.GetFulfillmentInfo(&_RRC7755Inbox.CallOpts, messageId)
}

// GetMessageId is a free data retrieval call binding the contract method 0x002423ca.
//
// Solidity: function getMessageId(bytes32 sourceChain, bytes32 sender, bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) view returns(bytes32)
func (_RRC7755Inbox *RRC7755InboxCaller) GetMessageId(opts *bind.CallOpts, sourceChain [32]byte, sender [32]byte, destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) ([32]byte, error) {
	var out []interface{}
	err := _RRC7755Inbox.contract.Call(opts, &out, "getMessageId", sourceChain, sender, destinationChain, receiver, payload, attributes)
	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err
}

// GetMessageId is a free data retrieval call binding the contract method 0x002423ca.
//
// Solidity: function getMessageId(bytes32 sourceChain, bytes32 sender, bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) view returns(bytes32)
func (_RRC7755Inbox *RRC7755InboxSession) GetMessageId(sourceChain [32]byte, sender [32]byte, destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) ([32]byte, error) {
	return _RRC7755Inbox.Contract.GetMessageId(&_RRC7755Inbox.CallOpts, sourceChain, sender, destinationChain, receiver, payload, attributes)
}

// GetMessageId is a free data retrieval call binding the contract method 0x002423ca.
//
// Solidity: function getMessageId(bytes32 sourceChain, bytes32 sender, bytes32 destinationChain, bytes32 receiver, bytes payload, bytes[] attributes) view returns(bytes32)
func (_RRC7755Inbox *RRC7755InboxCallerSession) GetMessageId(sourceChain [32]byte, sender [32]byte, destinationChain [32]byte, receiver [32]byte, payload []byte, attributes [][]byte) ([32]byte, error) {
	return _RRC7755Inbox.Contract.GetMessageId(&_RRC7755Inbox.CallOpts, sourceChain, sender, destinationChain, receiver, payload, attributes)
}

// Fulfill is a paid mutator transaction binding the contract method 0xabdfebbe.
//
// Solidity: function fulfill(bytes32 sourceChain, bytes32 sender, bytes payload, bytes[] attributes, address fulfiller) payable returns()
func (_RRC7755Inbox *RRC7755InboxTransactor) Fulfill(opts *bind.TransactOpts, sourceChain [32]byte, sender [32]byte, payload []byte, attributes [][]byte, fulfiller common.Address) (*types.Transaction, error) {
	return _RRC7755Inbox.contract.Transact(opts, "fulfill", sourceChain, sender, payload, attributes, fulfiller)
}

// Fulfill is a paid mutator transaction binding the contract method 0xabdfebbe.
//
// Solidity: function fulfill(bytes32 sourceChain, bytes32 sender, bytes payload, bytes[] attributes, address fulfiller) payable returns()
func (_RRC7755Inbox *RRC7755InboxSession) Fulfill(sourceChain [32]byte, sender [32]byte, payload []byte, attributes [][]byte, fulfiller common.Address) (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.Fulfill(&_RRC7755Inbox.TransactOpts, sourceChain, sender, payload, attributes, fulfiller)
}

// Fulfill is a paid mutator transaction binding the contract method 0xabdfebbe.
//
// Solidity: function fulfill(bytes32 sourceChain, bytes32 sender, bytes payload, bytes[] attributes, address fulfiller) payable returns()
func (_RRC7755Inbox *RRC7755InboxTransactorSession) Fulfill(sourceChain [32]byte, sender [32]byte, payload []byte, attributes [][]byte, fulfiller common.Address) (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.Fulfill(&_RRC7755Inbox.TransactOpts, sourceChain, sender, payload, attributes, fulfiller)
}

// StoreReceipt is a paid mutator transaction binding the contract method 0x9b3d91a7.
//
// Solidity: function storeReceipt(bytes32 messageId, address fulfiller) returns()
func (_RRC7755Inbox *RRC7755InboxTransactor) StoreReceipt(opts *bind.TransactOpts, messageId [32]byte, fulfiller common.Address) (*types.Transaction, error) {
	return _RRC7755Inbox.contract.Transact(opts, "storeReceipt", messageId, fulfiller)
}

// StoreReceipt is a paid mutator transaction binding the contract method 0x9b3d91a7.
//
// Solidity: function storeReceipt(bytes32 messageId, address fulfiller) returns()
func (_RRC7755Inbox *RRC7755InboxSession) StoreReceipt(messageId [32]byte, fulfiller common.Address) (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.StoreReceipt(&_RRC7755Inbox.TransactOpts, messageId, fulfiller)
}

// StoreReceipt is a paid mutator transaction binding the contract method 0x9b3d91a7.
//
// Solidity: function storeReceipt(bytes32 messageId, address fulfiller) returns()
func (_RRC7755Inbox *RRC7755InboxTransactorSession) StoreReceipt(messageId [32]byte, fulfiller common.Address) (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.StoreReceipt(&_RRC7755Inbox.TransactOpts, messageId, fulfiller)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_RRC7755Inbox *RRC7755InboxTransactor) Receive(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RRC7755Inbox.contract.RawTransact(opts, nil) // calldata is disallowed for receive function
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_RRC7755Inbox *RRC7755InboxSession) Receive() (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.Receive(&_RRC7755Inbox.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_RRC7755Inbox *RRC7755InboxTransactorSession) Receive() (*types.Transaction, error) {
	return _RRC7755Inbox.Contract.Receive(&_RRC7755Inbox.TransactOpts)
}

// RRC7755InboxCallFulfilledIterator is returned from FilterCallFulfilled and is used to iterate over the raw logs and unpacked data for CallFulfilled events raised by the RRC7755Inbox contract.
type RRC7755InboxCallFulfilledIterator struct {
	Event *RRC7755InboxCallFulfilled // Event containing the contract specifics and raw log

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
func (it *RRC7755InboxCallFulfilledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RRC7755InboxCallFulfilled)
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
		it.Event = new(RRC7755InboxCallFulfilled)
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
func (it *RRC7755InboxCallFulfilledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RRC7755InboxCallFulfilledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RRC7755InboxCallFulfilled represents a CallFulfilled event raised by the RRC7755Inbox contract.
type RRC7755InboxCallFulfilled struct {
	MessageId   [32]byte
	FulfilledBy common.Address
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterCallFulfilled is a free log retrieval operation binding the contract event 0xbcc2510e72762680ebba29abe0b7a57fe3edb99c2f194660c5148544e1e31d3b.
//
// Solidity: event CallFulfilled(bytes32 indexed messageId, address indexed fulfilledBy)
func (_RRC7755Inbox *RRC7755InboxFilterer) FilterCallFulfilled(opts *bind.FilterOpts, messageId [][32]byte, fulfilledBy []common.Address) (*RRC7755InboxCallFulfilledIterator, error) {
	var messageIdRule []interface{}
	for _, messageIdItem := range messageId {
		messageIdRule = append(messageIdRule, messageIdItem)
	}
	var fulfilledByRule []interface{}
	for _, fulfilledByItem := range fulfilledBy {
		fulfilledByRule = append(fulfilledByRule, fulfilledByItem)
	}

	logs, sub, err := _RRC7755Inbox.contract.FilterLogs(opts, "CallFulfilled", messageIdRule, fulfilledByRule)
	if err != nil {
		return nil, err
	}
	return &RRC7755InboxCallFulfilledIterator{contract: _RRC7755Inbox.contract, event: "CallFulfilled", logs: logs, sub: sub}, nil
}

// WatchCallFulfilled is a free log subscription operation binding the contract event 0xbcc2510e72762680ebba29abe0b7a57fe3edb99c2f194660c5148544e1e31d3b.
//
// Solidity: event CallFulfilled(bytes32 indexed messageId, address indexed fulfilledBy)
func (_RRC7755Inbox *RRC7755InboxFilterer) WatchCallFulfilled(opts *bind.WatchOpts, sink chan<- *RRC7755InboxCallFulfilled, messageId [][32]byte, fulfilledBy []common.Address) (event.Subscription, error) {
	var messageIdRule []interface{}
	for _, messageIdItem := range messageId {
		messageIdRule = append(messageIdRule, messageIdItem)
	}
	var fulfilledByRule []interface{}
	for _, fulfilledByItem := range fulfilledBy {
		fulfilledByRule = append(fulfilledByRule, fulfilledByItem)
	}

	logs, sub, err := _RRC7755Inbox.contract.WatchLogs(opts, "CallFulfilled", messageIdRule, fulfilledByRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RRC7755InboxCallFulfilled)
				if err := _RRC7755Inbox.contract.UnpackLog(event, "CallFulfilled", log); err != nil {
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

// ParseCallFulfilled is a log parse operation binding the contract event 0xbcc2510e72762680ebba29abe0b7a57fe3edb99c2f194660c5148544e1e31d3b.
//
// Solidity: event CallFulfilled(bytes32 indexed messageId, address indexed fulfilledBy)
func (_RRC7755Inbox *RRC7755InboxFilterer) ParseCallFulfilled(log types.Log) (*RRC7755InboxCallFulfilled, error) {
	event := new(RRC7755InboxCallFulfilled)
	if err := _RRC7755Inbox.contract.UnpackLog(event, "CallFulfilled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
