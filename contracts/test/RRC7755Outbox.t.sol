// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";

import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {RRC7755Base} from "../src/RRC7755Base.sol";
import {RRC7755Outbox} from "../src/RRC7755Outbox.sol";

import {MockOutbox} from "./mocks/MockOutbox.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract RRC7755OutboxTest is BaseTest {
    using GlobalTypes for address;
    using GlobalTypes for bytes;

    struct TestMessage {
        bytes32 sourceChain;
        bytes32 destinationChain;
        bytes32 sender;
        bytes32 receiver;
        PackedUserOperation userOp;
        bytes payload;
        bytes[] attributes;
        bytes[] userOpAttributes;
    }

    MockOutbox outbox;

    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    bytes32 private constant _EXPECTED_ENTRY_POINT = 0x0000000000000000000000000000000071727de22e5e9d8baf0edac6f37da032;

    event MessagePosted(
        bytes32 indexed messageId,
        bytes32 sourceChain,
        bytes32 sender,
        bytes32 destinationChain,
        bytes32 receiver,
        bytes payload,
        bytes[] attributes
    );
    event CrossChainCallCompleted(bytes32 indexed requestHash, address submitter);
    event CrossChainCallCanceled(bytes32 indexed callHash);

    function setUp() public {
        _setUp();
        outbox = new MockOutbox();
        approveAddr = address(outbox);
    }

    function test_getOptionalAttributes() external view {
        bytes4[] memory optionalAttributes = outbox.getOptionalAttributes();
        assertEq(optionalAttributes.length, 3);
        assertEq(optionalAttributes[0], _PRECHECK_ATTRIBUTE_SELECTOR);
        assertEq(optionalAttributes[1], _MAGIC_SPEND_REQUEST_SELECTOR);
        assertEq(optionalAttributes[2], _INBOX_ATTRIBUTE_SELECTOR);
    }

    function test_sendMessage_reverts_ifDuplicateOptionalAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _PRECHECK_ATTRIBUTE_SELECTOR);
        m.attributes = _addAttribute(m.attributes, _PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RRC7755Base.DuplicateAttribute.selector, _PRECHECK_ATTRIBUTE_SELECTOR));
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_incrementsNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount / 2, false);
        uint256 before = outbox.getNonce(ALICE);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        assertEq(outbox.getNonce(ALICE), before + 1);
    }

    function test_sendMessage_reverts_ifInvalidNativeCurrency(uint256 rewardAmount) external fundAlice(rewardAmount) {
        rewardAmount = bound(rewardAmount, 1, type(uint256).max);
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidValue.selector, rewardAmount, 0));
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifNativeCurrencyIncludedUnnecessarily(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        if (rewardAmount < 2) return;

        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidValue.selector, 0, 1));
        outbox.sendMessage{value: 1}(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifExpiryTooSoon(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _setDelay(m.attributes, 10, block.timestamp + 10 - 1);

        vm.prank(ALICE);
        vm.expectRevert(RRC7755Outbox.ExpiryTooSoon.selector);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifInvalidSourceChain(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initUserOpMessageWithInvalidSourceChain(rewardAmount);

        vm.prank(ALICE);
        vm.expectRevert(RRC7755Outbox.InvalidSourceChain.selector);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifInvalidSender(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initUserOpMessageWithInvalidSender(rewardAmount);

        vm.prank(ALICE);
        vm.expectRevert(RRC7755Outbox.InvalidSender.selector);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_setMetadata_erc20Reward(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_setMetadata_withOptionalPrecheckAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, _PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_setMetadata_userOp(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initUserOpMessage(rewardAmount);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes32 messageId =
            outbox.getUserOpHash(abi.decode(m.payload, (PackedUserOperation)), m.receiver, m.destinationChain);
        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RRC7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_reverts_userOp_invalidReceiver(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initUserOpMessage(rewardAmount);

        vm.prank(ALICE);
        vm.expectRevert(RRC7755Outbox.InvalidReceiver.selector);
        outbox.sendMessage(m.destinationChain, bytes32(0), m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifUnsupportedAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        bytes4 selector = 0x11111111;
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes = _addAttribute(m.attributes, selector);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.UnsupportedAttribute.selector, selector));
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingRewardAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[0] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REWARD_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingDelayAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[1] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _DELAY_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifIncorrectNonce(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1000);

        vm.prank(ALICE);
        vm.expectRevert(RRC7755Outbox.InvalidNonce.selector);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingNonceAttribute(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[2] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _NONCE_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifIncorrectRequester(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, FILLER.addressToBytes32());

        vm.prank(ALICE);
        vm.expectRevert(RRC7755Outbox.InvalidRequester.selector);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_reverts_ifMissingRequesterAttribute(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, false);
        m.attributes[3] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR);

        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(RRC7755Outbox.MissingRequiredAttribute.selector, _REQUESTER_ATTRIBUTE_SELECTOR)
        );
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_setStatusToRequested_nativeAssetReward(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Requested);
    }

    function test_sendMessage_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        bytes32 messageId = _deriveMessageId(m);

        vm.prank(ALICE);
        vm.expectEmit(true, false, false, true);
        emit MessagePosted(messageId, m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_sendMessage_pullsERC20FromUserIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalBefore - aliceBalAfter, rewardAmount);
    }

    function test_sendMessage_pullsERC20IntoContractIfUsed(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalAfter - contractBalBefore, rewardAmount);
    }

    function test_processAttributes_reverts_ifInvalidCaller() external {
        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, address(this), address(outbox)));
        outbox.processAttributes(bytes32(0), new bytes[](0), address(outbox), 0, false);
    }

    function test_claimReward_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestAlreadyCompleted(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);
    }

    function test_claimReward_reverts_requestCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        vm.prank(FILLER);
        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);
    }

    function test_claimReward_emitsEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.expectEmit(true, false, false, true);
        emit CrossChainCallCompleted(_deriveMessageId(m), FILLER);
        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);
    }

    function test_claimReward_storesCompletedStatus_pendingState(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Completed);
    }

    function test_claimReward_storesCompletedStatus_pendingStateUserOp(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _submitUserOp(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.userOp, storageProofData, FILLER);

        bytes32 messageId = outbox.getUserOpHash(m.userOp, m.receiver, m.destinationChain);
        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RRC7755Outbox.CrossChainCallStatus.Completed);
    }

    function test_claimReward_sendsNativeAssetRewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, true);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 fillerBalBefore = FILLER.balance;

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        uint256 fillerBalAfter = FILLER.balance;

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsNativeAssetRewardFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalBefore = address(outbox).balance;

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardToFiller(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 fillerBalBefore = mockErc20.balanceOf(FILLER);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        uint256 fillerBalAfter = mockErc20.balanceOf(FILLER);

        assertEq(fillerBalAfter - fillerBalBefore, rewardAmount);
    }

    function test_claimReward_sendsERC20RewardFromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelMessage_reverts_requestDoesNotExist(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_reverts_requestDoesNotExist_submittedUserOp(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        vm.warp(outbox.CANCEL_DELAY_SECONDS() + 1);
        TestMessage memory m = _submitUserOp(rewardAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.None
            )
        );
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_reverts_requestAlreadyCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.Canceled
            )
        );
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_reverts_requestAlreadyCompleted(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _submitRequest(rewardAmount);
        bytes memory storageProofData = abi.encode(true);

        vm.prank(FILLER);
        outbox.claimReward(m.destinationChain, m.receiver, m.payload, m.attributes, storageProofData, FILLER);

        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.InvalidStatus.selector,
                RRC7755Outbox.CrossChainCallStatus.Requested,
                RRC7755Outbox.CrossChainCallStatus.Completed
            )
        );
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_reverts_requestStillActive(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);
        uint256 cancelDelaySeconds = outbox.CANCEL_DELAY_SECONDS();

        vm.warp(this.extractExpiry(m.attributes) + cancelDelaySeconds - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                RRC7755Outbox.CannotCancelRequestBeforeExpiry.selector,
                block.timestamp,
                this.extractExpiry(m.attributes) + cancelDelaySeconds
            )
        );
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_setsStatusAsCanceled(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(_deriveMessageId(m));
        assert(status == RRC7755Outbox.CrossChainCallStatus.Canceled);
    }

    function test_cancelMessage_setsStatusAsCanceled_userOp(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitUserOp(rewardAmount);

        vm.warp(this.extractExpiry(m.userOpAttributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelUserOp(m.destinationChain, m.receiver, m.userOp);

        bytes32 messageId = outbox.getUserOpHash(m.userOp, m.receiver, m.destinationChain);
        RRC7755Outbox.CrossChainCallStatus status = outbox.getMessageStatus(messageId);
        assert(status == RRC7755Outbox.CrossChainCallStatus.Canceled);
    }

    function test_cancelMessage_emitsCanceledEvent(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.expectEmit(true, false, false, false);
        emit CrossChainCallCanceled(_deriveMessageId(m));
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function test_cancelMessage_returnsNativeCurrencyToRequester(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 aliceBalBefore = ALICE.balance;

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 aliceBalAfter = ALICE.balance;

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelMessage_returnsNativeCurrencyFromContract(uint256 rewardAmount)
        external
        fundAlice(rewardAmount)
    {
        TestMessage memory m = _initMessage(rewardAmount, true);

        vm.prank(ALICE);
        outbox.sendMessage{value: rewardAmount}(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalBefore = address(outbox).balance;

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalAfter = address(outbox).balance;

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_cancelMessage_returnsERC20ToRequester(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        uint256 aliceBalBefore = mockErc20.balanceOf(ALICE);

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 aliceBalAfter = mockErc20.balanceOf(ALICE);

        assertEq(aliceBalAfter - aliceBalBefore, rewardAmount);
    }

    function test_cancelMessage_returnsERC20FromContract(uint256 rewardAmount) external fundAlice(rewardAmount) {
        TestMessage memory m = _submitRequest(rewardAmount);

        uint256 contractBalBefore = mockErc20.balanceOf(address(outbox));

        vm.warp(this.extractExpiry(m.attributes) + outbox.CANCEL_DELAY_SECONDS());
        vm.prank(ALICE);
        outbox.cancelMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        uint256 contractBalAfter = mockErc20.balanceOf(address(outbox));

        assertEq(contractBalBefore - contractBalAfter, rewardAmount);
    }

    function test_supportsAttribute_returnsTrue_ifPrecheckAttribute() external view {
        bool supportsPrecheck = outbox.supportsAttribute(_PRECHECK_ATTRIBUTE_SELECTOR);
        assertTrue(supportsPrecheck);
    }

    function test_supportsAttribute_returnsTrue_ifInboxAttribute() external view {
        bool supportsInbox = outbox.supportsAttribute(_INBOX_ATTRIBUTE_SELECTOR);
        assertTrue(supportsInbox);
    }

    function _submitRequest(uint256 rewardAmount) private returns (TestMessage memory) {
        TestMessage memory m = _initMessage(rewardAmount, false);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        return m;
    }

    function _submitUserOp(uint256 rewardAmount) private returns (TestMessage memory) {
        TestMessage memory m = _initUserOpMessage(rewardAmount);

        vm.prank(ALICE);
        outbox.sendMessage(m.destinationChain, m.receiver, m.payload, m.attributes);

        return m;
    }

    function _initMessage(uint256 rewardAmount, bool isNativeAsset) private view returns (TestMessage memory) {
        bytes32 destinationChain = bytes32(block.chainid);
        bytes32 sender = address(outbox).addressToBytes32();
        Call[] memory calls = new Call[](1);
        calls[0] = Call({to: address(outbox).addressToBytes32(), data: "", value: 0});
        bytes[] memory attributes = new bytes[](4);

        if (isNativeAsset) {
            attributes[0] = abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, _NATIVE_ASSET, rewardAmount);
        } else {
            attributes[0] =
                abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        }

        attributes = _setDelay(attributes, 10, block.timestamp + 2 weeks);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 0);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());

        PackedUserOperation memory userOp;

        return TestMessage({
            sourceChain: bytes32(block.chainid),
            destinationChain: destinationChain,
            sender: sender,
            receiver: sender,
            userOp: userOp,
            payload: abi.encode(calls),
            attributes: attributes,
            userOpAttributes: new bytes[](0)
        });
    }

    function _initUserOpMessage(uint256 rewardAmount) private view returns (TestMessage memory) {
        bytes32 destinationChain = bytes32(block.chainid);
        bytes32 sender = address(outbox).addressToBytes32();
        bytes[] memory attributes = new bytes[](7);

        attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);

        attributes = _setDelay(attributes, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 0);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_INBOX_ATTRIBUTE_SELECTOR, address(outbox).addressToBytes32());
        attributes[5] = abi.encodeWithSelector(_MAGIC_SPEND_REQUEST_SELECTOR, _NATIVE_ASSET, 0.0001 ether);
        attributes[6] = abi.encodeWithSelector(
            _SOURCE_CHAIN_ATTRIBUTE_SELECTOR, bytes32(block.chainid), address(outbox).addressToBytes32()
        );

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: address(0),
            nonce: 1,
            initCode: "",
            callData: "",
            accountGasLimits: 0,
            preVerificationGas: 0,
            gasFees: 0,
            paymasterAndData: _encodePaymasterAndData(address(outbox), attributes),
            signature: ""
        });

        return TestMessage({
            sourceChain: bytes32(block.chainid),
            destinationChain: destinationChain,
            sender: sender,
            receiver: _EXPECTED_ENTRY_POINT,
            userOp: userOp,
            payload: abi.encode(userOp),
            attributes: new bytes[](0),
            userOpAttributes: attributes
        });
    }

    function _initUserOpMessageWithInvalidSourceChain(uint256 rewardAmount) private view returns (TestMessage memory) {
        bytes32 destinationChain = bytes32(block.chainid);
        bytes32 sender = address(outbox).addressToBytes32();
        bytes[] memory attributes = new bytes[](7);

        attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);

        attributes = _setDelay(attributes, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 0);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_INBOX_ATTRIBUTE_SELECTOR, address(outbox).addressToBytes32());
        attributes[5] = abi.encodeWithSelector(_MAGIC_SPEND_REQUEST_SELECTOR, _NATIVE_ASSET, 0.0001 ether);
        attributes[6] = abi.encodeWithSelector(_SOURCE_CHAIN_ATTRIBUTE_SELECTOR, 1, address(outbox).addressToBytes32());

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: address(0),
            nonce: 1,
            initCode: "",
            callData: "",
            accountGasLimits: 0,
            preVerificationGas: 0,
            gasFees: 0,
            paymasterAndData: _encodePaymasterAndData(address(outbox), attributes),
            signature: ""
        });

        return TestMessage({
            sourceChain: bytes32(block.chainid),
            destinationChain: destinationChain,
            sender: sender,
            receiver: _EXPECTED_ENTRY_POINT,
            userOp: userOp,
            payload: abi.encode(userOp),
            attributes: new bytes[](0),
            userOpAttributes: attributes
        });
    }

    function _initUserOpMessageWithInvalidSender(uint256 rewardAmount) private view returns (TestMessage memory) {
        bytes32 destinationChain = bytes32(block.chainid);
        bytes32 sender = address(outbox).addressToBytes32();
        bytes[] memory attributes = new bytes[](7);

        attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);

        attributes = _setDelay(attributes, 10, block.timestamp + 11);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 0);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] = abi.encodeWithSelector(_INBOX_ATTRIBUTE_SELECTOR, address(outbox).addressToBytes32());
        attributes[5] = abi.encodeWithSelector(_MAGIC_SPEND_REQUEST_SELECTOR, _NATIVE_ASSET, 0.0001 ether);
        attributes[6] = abi.encodeWithSelector(_SOURCE_CHAIN_ATTRIBUTE_SELECTOR, bytes32(block.chainid), address(this));

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: address(0),
            nonce: 1,
            initCode: "",
            callData: "",
            accountGasLimits: 0,
            preVerificationGas: 0,
            gasFees: 0,
            paymasterAndData: _encodePaymasterAndData(address(outbox), attributes),
            signature: ""
        });

        return TestMessage({
            sourceChain: bytes32(block.chainid),
            destinationChain: destinationChain,
            sender: sender,
            receiver: _EXPECTED_ENTRY_POINT,
            userOp: userOp,
            payload: abi.encode(userOp),
            attributes: new bytes[](0),
            userOpAttributes: attributes
        });
    }

    function _setDelay(bytes[] memory attributes, uint256 delay, uint256 expiry)
        private
        pure
        returns (bytes[] memory)
    {
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, delay, expiry);
        return attributes;
    }

    function extractExpiry(bytes[] calldata attributes) public pure returns (uint256) {
        (, uint256 expiry) = abi.decode(attributes[1][4:], (uint256, uint256));
        return expiry;
    }

    function _addAttribute(bytes[] memory attributes, bytes4 selector) private pure returns (bytes[] memory) {
        bytes[] memory newAttributes = new bytes[](attributes.length + 1);
        for (uint256 i = 0; i < attributes.length; i++) {
            newAttributes[i] = attributes[i];
        }
        newAttributes[attributes.length] = abi.encodeWithSelector(selector);
        return newAttributes;
    }

    function _deriveMessageId(TestMessage memory m) private view returns (bytes32) {
        return outbox.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);
    }

    function _encodePaymasterAndData(address inbox, bytes[] memory attributes) private pure returns (bytes memory) {
        uint128 paymasterVerificationGasLimit = 100000;
        uint128 paymasterPostOpGasLimit = 100000;
        return abi.encodePacked(inbox, paymasterVerificationGasLimit, paymasterPostOpGasLimit, abi.encode(attributes));
    }
}
