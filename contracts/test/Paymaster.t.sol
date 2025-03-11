// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EntryPoint, IEntryPoint, PackedUserOperation, UserOperationLib} from "account-abstraction/core/EntryPoint.sol";
import {IPaymaster} from "account-abstraction/interfaces/IPaymaster.sol";
import {Vm} from "forge-std/Vm.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {RLPWriter} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPWriter.sol";

import {BaseTest} from "./BaseTest.t.sol";
import {MockAccount} from "./mocks/MockAccount.sol";
import {MockEndpoint} from "./mocks/MockEndpoint.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {RRC7755Inbox} from "../src/RRC7755Inbox.sol";
import {MockUserOpPrecheck} from "./mocks/MockUserOpPrecheck.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";

contract PaymasterTest is BaseTest, MockEndpoint {
    using UserOperationLib for PackedUserOperation;
    using GlobalTypes for address;
    using RLPWriter for uint256;

    address constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IEntryPoint entryPoint;
    MockAccount mockAccount;
    RRC7755Inbox inbox;
    Paymaster paymaster;
    address precheckAddress;

    Vm.Wallet signer = vm.createWallet(block.timestamp);
    Vm.Wallet otherSigner = vm.createWallet(1000);

    event ClaimAddressSet(address indexed fulfiller, address indexed claimAddress);

    function setUp() external {
        entryPoint = IEntryPoint(new EntryPoint());
        mockAccount = new MockAccount();

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
        require(address(inbox) == inboxAddress, "Pre-derived inbox address mismatch");

        approveAddr = address(paymaster);
        precheckAddress = address(new MockUserOpPrecheck());

        _setUp();
    }

    modifier fundPaymaster(address account, uint256 amount) {
        vm.prank(account);
        (bool success,) = payable(paymaster).call{value: amount}("");
        assertTrue(success);
        _;
    }

    modifier fundPaymasterTokens(address account, uint256 amount) {
        vm.prank(account);
        paymaster.magicSpendDeposit(address(mockErc20), amount);
        _;
    }

    modifier fundPaymasterBoth(address account, uint256 amount) {
        vm.prank(account);
        (bool success,) = payable(paymaster).call{value: amount}("");
        assertTrue(success);
        vm.prank(account);
        paymaster.magicSpendDeposit(address(mockErc20), amount);
        _;
    }

    function test_deployment_reverts_zeroAddressEntryPoint() external {
        vm.expectRevert(Paymaster.ZeroAddress.selector);
        new Paymaster(address(0), address(inbox));
    }

    function test_deployment_reverts_zeroAddressInbox() external {
        vm.expectRevert(Paymaster.ZeroAddress.selector);
        new Paymaster(address(entryPoint), address(0));
    }

    function test_receive_incrementsMagicSpendBalance(uint256 amount) external fundAccount(signer.addr, amount) {
        uint256 initialBalance = paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS);

        vm.prank(signer.addr);
        (bool success,) = payable(paymaster).call{value: amount}("");
        assertTrue(success);

        assertEq(paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS), initialBalance + amount);
    }

    function test_magicSpendDeposit_reverts_ifEthValueDoesNotMatchAmount(uint256 amount) external {
        vm.assume(amount > 0);
        vm.expectRevert(abi.encodeWithSelector(Paymaster.InvalidValue.selector, amount, 0));
        paymaster.magicSpendDeposit(_ETH_ADDRESS, amount);
    }

    function test_magicSpendDeposit_incrementsEthMagicSpendBalance(uint256 amount)
        external
        fundAccount(signer.addr, amount)
    {
        uint256 initialBalance = paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS);

        vm.prank(signer.addr);
        paymaster.magicSpendDeposit{value: amount}(_ETH_ADDRESS, amount);

        assertEq(paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS), initialBalance + amount);
    }

    function test_magicSpendDeposit_reverts_ifValueIncludedForTokenDeposit(uint256 amount)
        external
        fundAccount(signer.addr, amount)
    {
        vm.assume(amount > 0);

        vm.prank(signer.addr);
        vm.expectRevert(abi.encodeWithSelector(Paymaster.InvalidValue.selector, 0, amount));
        paymaster.magicSpendDeposit{value: amount}(address(mockErc20), amount);
    }

    function test_magicSpendDeposit_incrementsTokenMagicSpendBalance(uint256 amount)
        external
        fundAccount(signer.addr, amount)
    {
        uint256 initialBalance = paymaster.getMagicSpendBalance(signer.addr, address(mockErc20));

        vm.prank(signer.addr);
        paymaster.magicSpendDeposit(address(mockErc20), amount);

        assertEq(paymaster.getMagicSpendBalance(signer.addr, address(mockErc20)), initialBalance + amount);
    }

    function test_magicSpendDeposit_transfersTokensFromSender(uint256 amount)
        external
        fundAccount(signer.addr, amount)
    {
        uint256 initialBalance = mockErc20.balanceOf(signer.addr);

        vm.prank(signer.addr);
        paymaster.magicSpendDeposit(address(mockErc20), amount);

        assertEq(mockErc20.balanceOf(signer.addr), initialBalance - amount);
    }

    function test_magicSpendDeposit_transfersTokensToPaymaster(uint256 amount)
        external
        fundAccount(signer.addr, amount)
    {
        uint256 initialBalance = mockErc20.balanceOf(address(paymaster));

        vm.prank(signer.addr);
        paymaster.magicSpendDeposit(address(mockErc20), amount);

        assertEq(mockErc20.balanceOf(address(paymaster)), initialBalance + amount);
    }

    function test_entryPointDeposit_incrementsMagicSpendBalance(uint256 amount)
        external
        fundAccount(signer.addr, amount)
    {
        uint256 initialBalance = paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS);

        vm.prank(signer.addr);
        paymaster.entryPointDeposit{value: amount}(0);

        assertEq(paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS), initialBalance + amount);
    }

    function test_entryPointDeposit_revertsIfInsufficientBalance(uint256 amount) external {
        vm.assume(amount > 0);

        vm.expectRevert(
            abi.encodeWithSelector(Paymaster.InsufficientMagicSpendBalance.selector, signer.addr, 0, amount)
        );
        vm.prank(signer.addr);
        paymaster.entryPointDeposit(amount);
    }

    function test_entryPointDeposit_decrementsMagicSpendBalance(uint256 amount)
        external
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        uint256 initialBalance = paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS);

        vm.prank(signer.addr);
        paymaster.entryPointDeposit(amount);

        assertEq(paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS), initialBalance - amount);
    }

    function test_entryPointDeposit_incrementsGasBalance(uint256 amount)
        external
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        uint256 initialBalance = paymaster.getGasBalance(signer.addr);

        vm.prank(signer.addr);
        paymaster.entryPointDeposit(amount);

        assertEq(paymaster.getGasBalance(signer.addr), initialBalance + amount);
    }

    function test_entryPointDeposit_routesToEntryPoint(uint256 amount) public fundAccount(signer.addr, amount) {
        uint256 initialBalance = address(entryPoint).balance;

        vm.prank(signer.addr);
        paymaster.entryPointDeposit{value: amount}(amount);

        assertEq(address(entryPoint).balance, initialBalance + amount);
    }

    function test_entryPointDeposit_storesBalanceInEntryPointOnBehalfOfPaymaster(uint256 amount)
        public
        fundAccount(signer.addr, amount)
    {
        uint256 initialBalance = entryPoint.balanceOf(address(paymaster));

        vm.prank(signer.addr);
        paymaster.entryPointDeposit{value: amount}(amount);

        assertEq(entryPoint.balanceOf(address(paymaster)), initialBalance + amount);
    }

    function test_withdrawTo_revertsIfWithdrawAddressIsZeroAddress() public {
        vm.prank(signer.addr);
        vm.expectRevert(Paymaster.ZeroAddress.selector);
        paymaster.withdrawTo(_ETH_ADDRESS, payable(address(0)), 1);
    }

    function test_withdrawTo_revertsIfInsufficientBalance(address payable withdrawAddress, uint256 amount) public {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        vm.prank(signer.addr);
        vm.expectRevert(
            abi.encodeWithSelector(Paymaster.InsufficientMagicSpendBalance.selector, signer.addr, 0, amount)
        );
        paymaster.withdrawTo(_ETH_ADDRESS, withdrawAddress, amount);
    }

    function test_withdrawTo_decrementsMagicSpendBalance(address payable withdrawAddress, uint256 amount)
        external
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        uint256 initialBalance = paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS);

        vm.prank(signer.addr);
        paymaster.withdrawTo(_ETH_ADDRESS, withdrawAddress, amount);

        assertEq(paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS), initialBalance - amount);
    }

    function test_withdrawTo_withdrawsFromPaymaster(address payable withdrawAddress, uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        uint256 initialBalance = address(paymaster).balance;

        vm.prank(signer.addr);
        paymaster.withdrawTo(_ETH_ADDRESS, withdrawAddress, amount);

        assertEq(address(paymaster).balance, initialBalance - amount);
    }

    function test_withdrawTo_sendsFundsToWithdrawAddress(address payable withdrawAddress, uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        uint256 initialBalance = withdrawAddress.balance;

        vm.prank(signer.addr);
        paymaster.withdrawTo(_ETH_ADDRESS, withdrawAddress, amount);

        assertEq(withdrawAddress.balance, initialBalance + amount);
    }

    function test_withdrawTo_withdrawsTokensFromPaymaster(address payable withdrawAddress, uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymasterTokens(signer.addr, amount)
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        uint256 initialBalance = mockErc20.balanceOf(address(paymaster));

        vm.prank(signer.addr);
        paymaster.withdrawTo(address(mockErc20), withdrawAddress, amount);

        assertEq(mockErc20.balanceOf(address(paymaster)), initialBalance - amount);
    }

    function test_withdrawTo_sendsTokensToWithdrawAddress(address payable withdrawAddress, uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymasterTokens(signer.addr, amount)
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        uint256 initialBalance = mockErc20.balanceOf(withdrawAddress);

        vm.prank(signer.addr);
        paymaster.withdrawTo(address(mockErc20), withdrawAddress, amount);

        assertEq(mockErc20.balanceOf(withdrawAddress), initialBalance + amount);
    }

    function test_fulfillerWithdraw_revertsIfNotCalledByInbox() external {
        vm.expectRevert(Paymaster.InvalidCaller.selector);
        paymaster.fulfillerWithdraw(signer.addr, _ETH_ADDRESS, 1);
    }

    function test_fulfillerWithdraw_revertsIfInsufficientBalance(uint256 amount)
        external
        fundAccount(signer.addr, amount)
        fundPaymasterTokens(signer.addr, amount)
    {
        vm.assume(amount < type(uint256).max);
        uint256 requestedAmount = amount + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Paymaster.InsufficientMagicSpendBalance.selector, signer.addr, amount, requestedAmount
            )
        );
        vm.prank(address(inbox));
        paymaster.fulfillerWithdraw(signer.addr, address(mockErc20), requestedAmount);
    }

    function test_fulfillerWithdraw_decreasesMagicSpendBalance(uint256 amount)
        external
        fundAccount(signer.addr, amount)
        fundPaymasterTokens(signer.addr, amount)
    {
        assertEq(paymaster.getMagicSpendBalance(signer.addr, address(mockErc20)), amount);

        vm.prank(address(inbox));
        paymaster.fulfillerWithdraw(signer.addr, address(mockErc20), amount);

        assertEq(paymaster.getMagicSpendBalance(signer.addr, address(mockErc20)), 0);
    }

    function test_fulfillerWithdraw_withdrawsTokensFromPaymaster(uint256 amount)
        external
        fundAccount(signer.addr, amount)
        fundPaymasterTokens(signer.addr, amount)
    {
        assertEq(mockErc20.balanceOf(address(paymaster)), amount);

        vm.prank(address(inbox));
        paymaster.fulfillerWithdraw(signer.addr, address(mockErc20), amount);

        assertEq(mockErc20.balanceOf(address(paymaster)), 0);
    }

    function test_fulfillerWithdraw_withdrawsTokensToInbox(uint256 amount)
        external
        fundAccount(signer.addr, amount)
        fundPaymasterTokens(signer.addr, amount)
    {
        assertEq(mockErc20.balanceOf(address(inbox)), 0);

        vm.prank(address(inbox));
        paymaster.fulfillerWithdraw(signer.addr, address(mockErc20), amount);

        assertEq(mockErc20.balanceOf(address(inbox)), amount);
    }

    function test_entryPointWithdrawTo_revertsIfWithdrawAddressIsZeroAddress() public {
        vm.prank(signer.addr);
        vm.expectRevert(Paymaster.ZeroAddress.selector);
        paymaster.entryPointWithdrawTo(payable(address(0)), 1);
    }

    function test_entryPointWithdrawTo_revertsIfInsufficientBalance(address payable withdrawAddress, uint256 amount)
        public
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        vm.prank(signer.addr);
        vm.expectRevert(abi.encodeWithSelector(Paymaster.InsufficientGasBalance.selector, signer.addr, 0, amount));
        paymaster.entryPointWithdrawTo(withdrawAddress, amount);
    }

    function test_entryPointWithdrawTo_decrementsGasBalance(address payable withdrawAddress, uint256 amount)
        external
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        _deposit(amount);

        uint256 initialBalance = paymaster.getGasBalance(signer.addr);

        vm.prank(signer.addr);
        paymaster.entryPointWithdrawTo(withdrawAddress, amount);

        assertEq(paymaster.getGasBalance(signer.addr), initialBalance - amount);
    }

    function test_entryPointWithdrawTo_decrementsTotalTrackedGasBalance(address payable withdrawAddress, uint256 amount)
        external
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        _deposit(amount);

        uint256 initialBalance = paymaster.totalTrackedGasBalance();

        vm.prank(signer.addr);
        paymaster.entryPointWithdrawTo(withdrawAddress, amount);

        assertEq(paymaster.totalTrackedGasBalance(), initialBalance - amount);
    }

    function test_entryPointWithdrawTo_withdrawsFromEntryPoint(address payable withdrawAddress, uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        _deposit(amount);

        uint256 initialBalance = address(entryPoint).balance;

        vm.prank(signer.addr);
        paymaster.entryPointWithdrawTo(withdrawAddress, amount);

        assertEq(address(entryPoint).balance, initialBalance - amount);
    }

    function test_entryPointWithdrawTo_sendsFundsToWithdrawAddress(address payable withdrawAddress, uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(amount > 0);
        _isValidWithdrawAddress(withdrawAddress);

        _deposit(amount);

        uint256 initialBalance = withdrawAddress.balance;

        vm.prank(signer.addr);
        paymaster.entryPointWithdrawTo(withdrawAddress, amount);

        assertEq(withdrawAddress.balance, initialBalance + amount);
    }

    function test_setClaimAddress_setsClaimAddress(address newClaimAddress) public {
        address startClaimAddress = paymaster.fulfillerClaimAddress(signer.addr);

        vm.prank(signer.addr);
        paymaster.setClaimAddress(newClaimAddress);

        assertEq(startClaimAddress, address(0));
        assertEq(paymaster.fulfillerClaimAddress(signer.addr), newClaimAddress);
    }

    function test_setClaimAddress_emitsClaimAddressSetEvent() public {
        address newClaimAddress = address(0x123);

        vm.expectEmit(true, true, true, false);
        emit ClaimAddressSet(signer.addr, newClaimAddress);

        vm.prank(signer.addr);
        paymaster.setClaimAddress(newClaimAddress);
    }

    function test_validatePaymasterUserOp_revertsIfNotCalledByEntryPoint(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) public {
        vm.expectRevert(Paymaster.NotEntryPoint.selector);
        paymaster.validatePaymasterUserOp(userOp, userOpHash, maxCost);
    }

    function test_validatePaymasterUserOp_revertsIfFulfillerDoesNotHaveEnoughMagicSpendBalance(uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, amount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        _deposit(amount);

        vm.assume(maxCost <= amount && amount <= type(uint256).max - maxCost);

        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA33 reverted",
                abi.encodeWithSelector(Paymaster.InsufficientMagicSpendBalance.selector, signer.addr, 0, amount)
            )
        );
        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));
    }

    function test_validatePaymasterUserOp_revertsIfFulfillerHasInsufficientGasBalance(uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, amount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(maxCost <= amount && amount <= type(uint256).max - maxCost);

        _deposit(maxCost);

        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA33 reverted",
                abi.encodeWithSelector(Paymaster.InsufficientGasBalance.selector, otherSigner.addr, 0, maxCost)
            )
        );
        vm.prank(otherSigner.addr, otherSigner.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));
    }

    function test_validatePaymasterUserOp_revertsIfFulfillerHasInsufficientGasBalanceOnSecondTry(
        uint256 amount,
        uint256 ethAmount
    ) public fundAccount(signer.addr, amount) fundPaymaster(signer.addr, amount) {
        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost * 2 && ethAmount + maxCost * 2 < amount);
        _deposit(maxCost);

        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));

        userOps = _generateUserOps(_ETH_ADDRESS, ethAmount, address(0), 1);
        maxCost = this.calculateMaxCost(userOps[0]);
        _deposit(maxCost);

        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOpWithRevert.selector,
                0,
                "AA33 reverted",
                abi.encodeWithSelector(Paymaster.InsufficientGasBalance.selector, otherSigner.addr, 0, maxCost)
            )
        );
        vm.prank(otherSigner.addr, otherSigner.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));
    }

    function test_validatePaymasterUserOp_tracksGasBalance(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        assertEq(paymaster.getGasBalance(signer.addr), address(entryPoint).balance);
        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);

        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));

        assertEq(paymaster.getGasBalance(signer.addr), address(entryPoint).balance);
    }

    function test_validatePaymasterUserOp_revertsIfPrecheckFails(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, ethAmount, precheckAddress, 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);

        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.FailedOpWithRevert.selector, 0, "AA33 reverted", ""));
        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));
    }

    function test_validatePaymasterUserOp_storesExecutionReceipt(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);

        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));

        // assertEq(paymaster.requestHash(), entryPoint.getUserOpHash(userOps[0]));
        // assertEq(paymaster.fulfiller(), address(signer.addr));
        RRC7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(entryPoint.getUserOpHash(userOps[0]));
        assertEq(info.fulfiller, address(signer.addr));
    }

    function test_validatePaymasterUserOp_doesNotStoreExecutionReceiptIfOpFails(uint256 amount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        uint256 ethAmount = 0;
        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);

        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));

        // assertEq(paymaster.requestHash(), bytes32(0));
        // assertEq(paymaster.fulfiller(), address(0));
        RRC7755Inbox.FulfillmentInfo memory info = inbox.getFulfillmentInfo(entryPoint.getUserOpHash(userOps[0]));
        assertEq(info.fulfiller, address(0));
    }

    function test_validatePaymasterUserOp_decrementsMagicSpendBalance(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);
        uint256 initialBalance = paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS);

        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));

        assertEq(paymaster.getMagicSpendBalance(signer.addr, _ETH_ADDRESS), initialBalance - ethAmount);
    }

    function test_validatePaymasterUserOp_sendsFundsToAccount(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);
        uint256 initialBalance = address(mockAccount).balance;

        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));

        assertEq(address(mockAccount).balance, initialBalance + ethAmount);
    }

    function test_validatePaymasterUserOp_sendsFundsFromPaymaster(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymaster(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(_ETH_ADDRESS, ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);
        uint256 initialBalance = address(paymaster).balance;

        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));

        assertEq(address(paymaster).balance, initialBalance - ethAmount);
    }

    function test_validatePaymasterUserOp_sendsTokenFundsToAccount(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymasterBoth(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(address(mockErc20), ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);
        uint256 initialBalance = mockErc20.balanceOf(address(mockAccount));

        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));

        assertEq(mockErc20.balanceOf(address(mockAccount)), initialBalance + ethAmount);
    }

    function test_validatePaymasterUserOp_sendsTokenFundsFromPaymaster(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymasterBoth(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(address(mockErc20), ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);
        uint256 initialBalance = mockErc20.balanceOf(address(paymaster));

        vm.prank(signer.addr, signer.addr);
        entryPoint.handleOps(userOps, payable(BUNDLER));

        assertEq(mockErc20.balanceOf(address(paymaster)), initialBalance - ethAmount);
    }

    function test_postOp_revertsIfNotCalledByEntryPoint(uint256 amount, uint256 ethAmount)
        public
        fundAccount(signer.addr, amount)
        fundPaymasterBoth(signer.addr, amount)
    {
        vm.assume(ethAmount > 0);

        PackedUserOperation[] memory userOps = _generateUserOps(address(mockErc20), ethAmount, address(0), 0);
        uint256 maxCost = this.calculateMaxCost(userOps[0]);

        vm.assume(ethAmount < type(uint256).max - maxCost && ethAmount + maxCost < amount);
        _deposit(maxCost);

        vm.prank(signer.addr, signer.addr);
        vm.expectRevert(Paymaster.NotEntryPoint.selector);
        paymaster.postOp(IPaymaster.PostOpMode.opSucceeded, "", 0, 0);
    }

    function _generateUserOps(address token, uint256 ethAmount, address precheck, uint256 nonce)
        private
        view
        returns (PackedUserOperation[] memory)
    {
        bytes[] memory attributes = new bytes[](2);
        attributes[0] = abi.encodeWithSelector(_MAGIC_SPEND_REQUEST_SELECTOR, token, ethAmount);
        attributes[1] = abi.encodeWithSelector(_PRECHECK_ATTRIBUTE_SELECTOR, precheck);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = PackedUserOperation({
            sender: address(mockAccount),
            nonce: nonce,
            initCode: "",
            callData: abi.encodeWithSelector(
                MockAccount.executeUserOp.selector, address(paymaster), token.addressToBytes32()
            ),
            accountGasLimits: bytes32(abi.encodePacked(uint128(1000000), uint128(1000000))),
            preVerificationGas: 100000,
            gasFees: bytes32(abi.encodePacked(uint128(1000000), uint128(1000000))),
            paymasterAndData: _encodePaymasterAndData(attributes),
            signature: abi.encode(0)
        });
        return userOps;
    }

    function _encodePaymasterAndData(bytes[] memory attributes) private view returns (bytes memory) {
        return abi.encodePacked(address(paymaster), uint128(1000000), uint128(1000000), abi.encode(attributes));
    }

    function calculateMaxCost(PackedUserOperation calldata userOp) public pure returns (uint256) {
        MemoryUserOp memory mUserOp;
        _copyUserOpToMemory(userOp, mUserOp);
        return _getRequiredPrefund(mUserOp);
    }

    function _deposit(uint256 amount) private {
        vm.prank(signer.addr);
        paymaster.entryPointDeposit(amount);
    }

    function _isValidWithdrawAddress(address withdrawAddress) private view {
        vm.assume(withdrawAddress.code.length == 0 && uint256(uint160(withdrawAddress)) > 65535);
    }
}
