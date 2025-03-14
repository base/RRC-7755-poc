// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";
import {RLPWriter} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPWriter.sol";

import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {RRC7755Inbox} from "../src/RRC7755Inbox.sol";

import {MockPrecheck} from "./mocks/MockPrecheck.sol";
import {MockTarget} from "./mocks/MockTarget.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract RRC7755InboxTest is BaseTest {
    using GlobalTypes for address;
    using RLPWriter for uint256;

    struct TestMessage {
        bytes32 messageId;
        bytes32 sourceChain;
        bytes32 sender;
        bytes payload;
        bytes[] attributes;
    }

    EntryPoint entryPoint;
    RRC7755Inbox inbox;
    MockPrecheck precheck;
    MockTarget target;
    Paymaster paymaster;

    event PaymasterDeployed(address indexed sender, address indexed paymaster);
    event CallFulfilled(bytes32 indexed requestHash, address indexed fulfilledBy);

    function setUp() public {
        entryPoint = new EntryPoint();

        uint256 deployerNonce = vm.getNonce(address(this));
        address inboxAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(this), (deployerNonce + 1).writeUint())
                    )
                )
            )
        );

        paymaster = new Paymaster(address(entryPoint), inboxAddress);
        inbox = new RRC7755Inbox(address(paymaster));
        precheck = new MockPrecheck();
        target = new MockTarget();
        approveAddr = address(inbox);
        _setUp();
    }

    function test_deployment_reverts_zeroAddress() external {
        vm.expectRevert(RRC7755Inbox.ZeroAddress.selector);
        new RRC7755Inbox(address(0));
    }

    function test_deployment_setsPaymaster() external view {
        assertEq(address(inbox.PAYMASTER()), address(paymaster));
    }

    function test_fulfill_reverts_userOp() external {
        TestMessage memory m = _initMessage(false, true);

        vm.expectRevert(RRC7755Inbox.UserOp.selector);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_storesFulfillment_withSuccessfulPrecheck() external {
        TestMessage memory m = _initMessage(true, false);

        vm.prank(FILLER, FILLER);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        RRC7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_fulfill_reverts_failedPrecheck() external {
        TestMessage memory m = _initMessage(true, false);

        vm.expectRevert();
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_reverts_callAlreadyFulfilled() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(FILLER);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        vm.prank(FILLER);
        vm.expectRevert(RRC7755Inbox.CallAlreadyFulfilled.selector);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_callsTargetContract(uint256 inputNum) external {
        TestMessage memory m = _initMessage(false, false);

        _appendCall(
            m,
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.target.selector, inputNum),
                value: 0
            })
        );

        vm.prank(FILLER);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        assertEq(target.number(), inputNum);
    }

    function test_fulfill_sendsEth(uint256 amount) external {
        TestMessage memory m = _initMessage(false, false);

        _appendCall(m, Call({to: ALICE.addressToBytes32(), data: "", value: amount}));

        vm.deal(FILLER, amount);
        vm.prank(FILLER);
        inbox.fulfill{value: amount}(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        assertEq(ALICE.balance, amount);
    }

    function test_fulfill_reverts_ifTargetContractReverts() external {
        TestMessage memory m = _initMessage(false, false);

        _appendCall(
            m,
            Call({
                to: address(target).addressToBytes32(),
                data: abi.encodeWithSelector(target.shouldFail.selector),
                value: 0
            })
        );

        vm.prank(FILLER);
        vm.expectRevert(MockTarget.MockError.selector);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_storesFulfillment() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(FILLER);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);

        RRC7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function test_fulfill_emitsEvent() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(FILLER);
        vm.expectEmit(true, true, false, false);
        emit CallFulfilled({requestHash: m.messageId, fulfilledBy: FILLER});
        inbox.fulfill(m.sourceChain, m.sender, m.payload, m.attributes, FILLER);
    }

    function test_fulfill_paymasterRequest(uint256 amount) external fundAlice(amount) {
        vm.startPrank(ALICE);
        mockErc20.approve(address(paymaster), amount);
        paymaster.magicSpendDeposit(address(mockErc20), amount);
        vm.stopPrank();

        TestMessage memory m = _initMessage(false, false);
        bytes[] memory attributes = new bytes[](1);
        attributes[0] = abi.encodeWithSelector(_MAGIC_SPEND_REQUEST_SELECTOR, address(mockErc20), amount);

        vm.prank(ALICE);
        inbox.fulfill(m.sourceChain, m.sender, m.payload, attributes, FILLER);

        assertEq(mockErc20.balanceOf(address(inbox)), amount);
    }

    function test_fulfill_reverts_ifCallDesignatesPaymaster() external {
        TestMessage memory m = _initMessage(false, false);
        Call[] memory calls = new Call[](1);
        calls[0] = Call({to: address(paymaster).addressToBytes32(), data: "", value: 0});

        vm.prank(FILLER);
        vm.expectRevert(RRC7755Inbox.CannotCallPaymaster.selector);
        inbox.fulfill(m.sourceChain, m.sender, abi.encode(calls), m.attributes, FILLER);
    }

    function test_storeReceipt_reverts_invalidCaller() external {
        vm.expectRevert(RRC7755Inbox.InvalidCaller.selector);
        inbox.storeReceipt(bytes32(0), FILLER);
    }

    function test_storeReceipt_storesFulfillmentInfo() external {
        TestMessage memory m = _initMessage(false, false);

        vm.prank(address(paymaster));
        inbox.storeReceipt(m.messageId, FILLER);

        RRC7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(m.messageId);

        assertEq(info.fulfiller, FILLER);
        assertEq(info.timestamp, block.timestamp);
    }

    function _initMessage(bool isPrecheck, bool isUserOp) private view returns (TestMessage memory) {
        bytes32 sourceChain = bytes32(block.chainid);
        bytes32 sender = address(this).addressToBytes32();
        bytes memory payload = abi.encode(new Call[](0));
        bytes[] memory attributes = new bytes[](isPrecheck ? 5 : 4);

        attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, bytes32(0), uint256(0));
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());

        if (isPrecheck) {
            attributes[4] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR, address(precheck));
        }

        return TestMessage({
            messageId: inbox.getMessageId(
                sourceChain, sender, bytes32(block.chainid), address(inbox).addressToBytes32(), payload, attributes
            ),
            sourceChain: sourceChain,
            sender: sender,
            payload: payload,
            attributes: isUserOp ? new bytes[](0) : attributes
        });
    }

    function _appendCall(TestMessage memory m, Call memory call) private pure {
        Call[] memory currentCalls = abi.decode(m.payload, (Call[]));
        Call[] memory newCalls = new Call[](currentCalls.length + 1);
        for (uint256 i; i < currentCalls.length; i++) {
            newCalls[i] = currentCalls[i];
        }
        newCalls[currentCalls.length] = Call({to: call.to, value: call.value, data: call.data});
        m.payload = abi.encode(newCalls);
    }
}
