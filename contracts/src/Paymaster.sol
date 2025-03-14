// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {IPaymaster} from "account-abstraction/interfaces/IPaymaster.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IInbox} from "./interfaces/IInbox.sol";
import {IUserOpPrecheck} from "./interfaces/IUserOpPrecheck.sol";
import {GlobalTypes} from "./libraries/GlobalTypes.sol";

/// @title Paymaster
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice This contract is used as a hook for fulfillers to provide funds for requested transactions when the
///         cross-chain call(s) are ERC-4337 User Operations
contract Paymaster is IPaymaster {
    using SafeTransferLib for address;
    using GlobalTypes for address;
    using GlobalTypes for bytes32;

    /// @notice The context structure returned by validatePaymasterUserOp
    struct Context {
        /// @dev The hash of the user operation
        bytes32 userOpHash;
        /// @dev The fulfiller's claim address
        address claimAddress;
        /// @dev The sender of the user operation
        address sender;
        /// @dev The token address for magic spend
        bytes32 magicSpendToken;
        /// @dev The amount that was spent as a magic spend (either native currency or ERC20 tokens)
        uint256 magicSpendAmount;
        /// @dev The address of the fulfiller
        address fulfiller;
    }

    /// @notice The bytes32 address value to represent native currency
    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    /// @notice The selector for the precheck attribute
    bytes4 internal constant _PRECHECK_ATTRIBUTE_SELECTOR = 0xbef86027; // precheck(bytes32)

    /// @notice The selector for requesting magic spend funds for call execution
    bytes4 internal constant _MAGIC_SPEND_REQUEST_SELECTOR = 0x92041278; // magicSpendRequest(address,uint256)

    /// @notice The ERC-4337 EntryPoint contract
    IEntryPoint public immutable ENTRY_POINT;

    /// @notice The RRC-7755 Inbox contract
    IInbox public immutable INBOX;

    /// @notice The address of the previous fulfiller to have sponsored a User Operation. If this is the zero address,
    ///         `totalTrackedGasBalance` MUST exactly equal ENTRY_POINT.balanceOf(address(this)). If this is not the
    ///         zero address, there should be a difference between `totalTrackedGasBalance` and
    ///         ENTRY_POINT.balanceOf(address(this)). That difference is subtracted from `prevFulfiller`'s _ethForGas
    ///         balance.
    address prevFulfiller;

    /// @notice The total amount of eth that has been deposited into the paymaster and converted to gas.
    uint256 public totalTrackedGasBalance;

    /// @notice A mapping tracking fulfiller claim addresses. If set, this address is the address the fulfiller is
    ///         allowed to claim rewards on source chain from. If not set, the fulfiller must claim from their own
    ///         address.
    mapping(address fulfiller => address claimAddress) public fulfillerClaimAddress;

    /// @notice A mapping tracking the amount of eth that has been allocated for gas sponsorship by a fulfiller. This
    ///         balance sits in the EntryPoint contract.
    mapping(address fulfiller => uint256 ethForGas) private _ethForGas;

    /// @notice A mapping tracking the magic spend amount that has been allocated by a fulfiller. This balance sits in
    ///         this contract and is used to provide funds for call execution. This is different from gas sponsorship.
    ///         It is for any call sending an eth value or erc20 tokens with it.
    mapping(address fulfiller => mapping(bytes32 token => uint256 magicSpendBalance)) private _magicSpendBalance;

    /// @notice A mapping from an account's address to the magic spend amount that can be withdrawn by the account.
    ///         This is used to track the amount of currency (either eth or erc20 tokens) that has been allocated by
    ///         the paymaster but not yet withdrawn by the account
    mapping(address account => mapping(bytes32 token => uint256)) private _withdrawable;

    /// @notice This error is thrown when an address is the zero address
    error ZeroAddress();

    /// @notice This error is thrown when the sender is not the EntryPoint contract
    error NotEntryPoint();

    /// @notice This error is thrown when an account attempts to withdraw more eth than its current allocation in the
    ///         paymaster
    ///
    /// @param account The address of the fulfiller
    /// @param balance The magic spend balance of the fulfiller
    /// @param amount  The amount of eth that is being requested by the fulfiller or user operation
    error InsufficientMagicSpendBalance(address account, uint256 balance, uint256 amount);

    /// @notice This error is thrown when an account attempts to withdraw more gas than its current allocation in the
    ///         paymaster
    ///
    /// @param account The address of the fulfiller
    /// @param balance The gas balance of the fulfiller
    /// @param amount  The amount of eth that is being requested by the fulfiller or user operation
    error InsufficientGasBalance(address account, uint256 balance, uint256 amount);

    /// @notice This error is thrown when the amount of eth to withdraw is zero
    error ZeroAmount();

    /// @notice This error is thrown if a fulfiller submits a `msg.value` greater than the total value needed for all
    ///         the calls
    ///
    /// @param expected The total value needed for all the calls
    /// @param actual   The received `msg.value`
    error InvalidValue(uint256 expected, uint256 actual);

    /// @notice This error is thrown in `fulfillerWithdraw` when the caller is not the RRC-7755 Inbox contract
    error InvalidCaller();

    /// @notice This event is emitted when a fulfiller's claim address is set
    ///
    /// @param fulfiller    The address of the fulfiller
    /// @param claimAddress The address that the fulfiller is allowed to claim rewards from
    event ClaimAddressSet(address indexed fulfiller, address indexed claimAddress);

    /// @notice This event is emitted when a fulfiller withdraws magic spend eth from the paymaster
    ///
    /// @param caller          The address of the caller
    /// @param withdrawAddress The address that the eth is being withdrawn to
    /// @param amount          The amount of eth that is being withdrawn
    event MagicSpendWithdrawal(address indexed caller, address indexed withdrawAddress, uint256 amount);

    /// @notice This event is emitted when a fulfiller withdraws gas eth from the EntryPoint
    ///
    /// @param caller          The address of the caller
    /// @param withdrawAddress The address that the eth is being withdrawn to
    /// @param amount          The amount of eth that is being withdrawn
    event GasWithdrawal(address indexed caller, address indexed withdrawAddress, uint256 amount);

    /// @dev Stores entrypoint and initializes owner. Expected to be deployed by the RRC-7755 Inbox contract
    ///
    /// @custom:reverts If the EntryPoint contract is the zero address
    ///
    /// @param entryPoint The EntryPoint contract to use for the paymaster
    /// @param inbox The RRC-7755 Inbox contract to use for the paymaster
    constructor(address entryPoint, address inbox) payable {
        if (entryPoint == address(0) || inbox == address(0)) {
            revert ZeroAddress();
        }

        ENTRY_POINT = IEntryPoint(entryPoint);
        INBOX = IInbox(inbox);
    }

    /// @dev A modifier that ensures the caller is the EntryPoint contract
    modifier onlyEntryPoint() {
        if (msg.sender != address(ENTRY_POINT)) {
            revert NotEntryPoint();
        }
        _;
    }

    /// @notice A receive function that allows fulfillers to deposit eth into the paymaster
    receive() external payable {
        _depositEth();
    }

    /// @notice Deposits eth or any ERC20 token for magic spend support
    ///
    /// @custom:reverts If token address is representing eth and `amount` does not match `msg.value`
    ///
    /// @param token  Address representing ERC20 token or eth to deposit
    /// @param amount Amount of magic spend currency to deposit
    function magicSpendDeposit(address token, uint256 amount) external payable {
        bytes32 tokenBytes32 = token.addressToBytes32();
        if (tokenBytes32 == _NATIVE_ASSET) {
            if (amount != msg.value) {
                revert InvalidValue(amount, msg.value);
            }

            _depositEth();
        } else {
            if (msg.value != 0) {
                revert InvalidValue(0, msg.value);
            }

            // ERC20 deposit
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            _magicSpendBalance[msg.sender][tokenBytes32] += balanceAfter - balanceBefore;
        }
    }

    /// @notice Transfers ETH from this contract into the EntryPoint.
    ///
    /// @dev Reverts if caller's magic spend balance is insufficient
    ///
    /// @param amount The amount to deposit on the Entrypoint.
    function entryPointDeposit(uint256 amount) external payable {
        _depositEth();
        _convertEthForGas(msg.sender, amount);
    }

    /// @notice A function that allows a fulfiller to withdraw eth or ERC20 tokens from the paymaster
    ///
    /// @custom:reverts If the withdraw address is the zero address
    /// @custom:reverts If caller's magic spend balance is insufficient
    ///
    /// @param token           Token address to withdraw
    /// @param withdrawAddress The address to withdraw the eth or tokens to
    /// @param amount          The amount of eth or tokens to withdraw
    function withdrawTo(address token, address withdrawAddress, uint256 amount) external {
        _fulfillerWithdraw(msg.sender, token, withdrawAddress, amount);
    }

    /// @notice A function that allows the RRC-7755 Inbox contract to withdraw eth or ERC20 tokens from the paymaster
    ///
    /// @custom:reverts If the caller is not the RRC-7755 Inbox contract
    /// @custom:reverts If fulfiller's magic spend balance is insufficient
    ///
    /// @param fulfiller The address of the fulfiller
    /// @param token     The token address to withdraw
    /// @param amount    The amount of eth or tokens to withdraw
    function fulfillerWithdraw(address fulfiller, address token, uint256 amount) external {
        if (msg.sender != address(INBOX)) {
            revert InvalidCaller();
        }

        _fulfillerWithdraw(fulfiller, token, msg.sender, amount);
    }

    /// @notice A function that allows a fulfiller to withdraw gas eth from the EntryPoint
    ///
    /// @custom:reverts If the withdraw address is the zero address
    /// @custom:reverts If caller's eth for gas balance is insufficient
    ///
    /// @param withdrawAddress The address to withdraw the eth to
    /// @param amount          The amount of eth to withdraw
    function entryPointWithdrawTo(address payable withdrawAddress, uint256 amount) external {
        if (withdrawAddress == address(0)) {
            revert ZeroAddress();
        }

        uint256 balance = getGasBalance(msg.sender);

        if (amount > balance) {
            revert InsufficientGasBalance(msg.sender, balance, amount);
        }

        unchecked {
            _ethForGas[msg.sender] -= amount;
            totalTrackedGasBalance -= amount;
        }

        ENTRY_POINT.withdrawTo(withdrawAddress, amount);

        emit GasWithdrawal(msg.sender, withdrawAddress, amount);
    }

    /// @notice A function that allows a fulfiller to set their claim address
    ///
    /// @param fulfillerClaimAddr The address to set as the claim address
    function setClaimAddress(address fulfillerClaimAddr) external {
        fulfillerClaimAddress[msg.sender] = fulfillerClaimAddr;

        emit ClaimAddressSet(msg.sender, fulfillerClaimAddr);
    }

    /// @notice A function that validates a User Operation and returns the context and validation data
    ///
    /// @custom:reverts If the sender is not the EntryPoint contract
    /// @custom:reverts If the fulfiller does not have enough magic spend balance to cover the cost of the User Op
    /// @custom:reverts If the fulfiller does not have enough gas balance to cover the gas cost of the User Op
    /// @custom:reverts If the precheck contract is not the zero address and the precheck reverts
    ///
    /// @param userOp     The User Operation to validate
    /// @param userOpHash Hash of the user's request data
    /// @param maxCost    The maximum cost of this transaction (based on maximum gas and gas price from userOp)
    ///
    /// @return context        The context for the User Operation
    /// @return validationData The validation data for the User Operation
    function validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
        external
        onlyEntryPoint
        returns (bytes memory context, uint256 validationData)
    {
        _settleBalanceDiff(maxCost);
        (bytes[] memory attributes) = abi.decode(userOp.paymasterAndData[52:], (bytes[]));
        (bytes32 magicSpendToken, uint256 magicSpendAmount, address precheckContract) =
            _extractMagicSpendAndPrecheck(attributes);

        address fulfiller = tx.origin;
        uint256 balance = _magicSpendBalance[fulfiller][magicSpendToken];
        uint256 gasBalance = _ethForGas[fulfiller];

        if (maxCost > gasBalance) {
            revert InsufficientGasBalance(fulfiller, gasBalance, maxCost);
        }

        if (magicSpendAmount > balance) {
            revert InsufficientMagicSpendBalance(fulfiller, balance, magicSpendAmount);
        }

        if (precheckContract != address(0)) {
            IUserOpPrecheck(precheckContract).precheckUserOp(userOp, fulfiller);
        }

        _withdrawable[userOp.sender][magicSpendToken] += magicSpendAmount;
        prevFulfiller = fulfiller;
        address storedClaimAddress = fulfillerClaimAddress[fulfiller];

        Context memory ctx = Context({
            userOpHash: userOpHash,
            claimAddress: storedClaimAddress == address(0) ? fulfiller : storedClaimAddress,
            sender: userOp.sender,
            magicSpendToken: magicSpendToken,
            magicSpendAmount: magicSpendAmount,
            fulfiller: fulfiller
        });

        return (abi.encode(ctx), 0);
    }

    /// @notice A function that allows a smart account to withdraw eth from the paymaster during its user operation
    ///         execution
    ///
    /// @custom:reverts If the withdrawable amount is 0
    ///
    /// @param token Token address to withdraw
    function withdrawGasExcess(bytes32 token) external {
        uint256 amount = _withdrawable[msg.sender][token];

        if (amount == 0) {
            revert ZeroAmount();
        }

        delete _withdrawable[msg.sender][token];
        _sendTokens({token: token.bytes32ToAddress(), to: msg.sender, amount: amount});
    }

    /// @notice A function that is called after a User Operation is executed. This function is used to update the
    ///         paymaster's state and to set the fulfillment info for the User Operation
    ///
    /// @param mode    Enum with the following options:
    ///                  opSucceeded - User operation succeeded.
    ///                  opReverted  - User op reverted. The paymaster still has to pay for gas.
    ///                  postOpReverted - never passed in a call to postOp().
    /// @param context The context value returned by validatePaymasterUserOp
    function postOp(PostOpMode mode, bytes calldata context, uint256, uint256) external onlyEntryPoint {
        (Context memory ctx) = abi.decode(context, (Context));

        if (mode == PostOpMode.opSucceeded) {
            INBOX.storeReceipt(ctx.userOpHash, ctx.claimAddress);
        }

        // If the sender's withdrawable balance is not equal to the eth amount, it means that the sender's balance was
        // spent as a magic spend balance. Thus the fulfiller's magic spend balance should be reduced by the eth amount
        if (_withdrawable[ctx.sender][ctx.magicSpendToken] != ctx.magicSpendAmount) {
            _magicSpendBalance[ctx.fulfiller][ctx.magicSpendToken] -= ctx.magicSpendAmount;
        }

        delete _withdrawable[ctx.sender][ctx.magicSpendToken];
    }

    /// @notice A function that returns the balance of gas eth for a fulfiller
    ///
    /// @param account The address of the fulfiller
    ///
    /// @return balance The balance of gas eth for the fulfiller
    function getGasBalance(address account) public view returns (uint256) {
        uint256 balance = _ethForGas[account];
        uint256 diff = _calculateBalanceDiff({maxCost: 0});

        if (account == prevFulfiller) {
            balance -= diff;
        }

        return balance;
    }

    /// @notice A function that returns the balance of magic spend eth for a fulfiller
    ///
    /// @param account The address of the fulfiller
    /// @param token   Currency address
    ///
    /// @return balance The balance of magic spend eth for the fulfiller
    function getMagicSpendBalance(address account, address token) external view returns (uint256) {
        bytes32 tokenBytes32 = token.addressToBytes32();
        return _magicSpendBalance[account][tokenBytes32];
    }

    /// @notice A function that allows a fulfiller to withdraw eth or ERC20 tokens from the paymaster
    ///
    /// @custom:reverts If the withdraw address is the zero address
    /// @custom:reverts If fulfiller's magic spend balance is insufficient
    ///
    /// @param fulfiller       The address of the fulfiller
    /// @param token           Token address to withdraw
    /// @param withdrawAddress The address to withdraw the tokens to
    /// @param amount          The amount of eth or tokens to withdraw
    function _fulfillerWithdraw(address fulfiller, address token, address withdrawAddress, uint256 amount) private {
        bytes32 tokenBytes32 = token.addressToBytes32();
        if (withdrawAddress == address(0)) {
            revert ZeroAddress();
        }

        uint256 balance = _magicSpendBalance[fulfiller][tokenBytes32];

        if (amount > balance) {
            revert InsufficientMagicSpendBalance(fulfiller, balance, amount);
        }

        unchecked {
            _magicSpendBalance[fulfiller][tokenBytes32] -= amount;
        }

        _sendTokens({token: token, to: withdrawAddress, amount: amount});

        emit MagicSpendWithdrawal(fulfiller, withdrawAddress, amount);
    }

    /// @notice A function that deposits eth into the paymaster
    function _depositEth() private {
        unchecked {
            _magicSpendBalance[msg.sender][_NATIVE_ASSET] += msg.value;
        }
    }

    /// @notice A function that converts eth allocation from magic spend to gas sponsorship
    ///
    /// @custom:reverts If the fulfiller's magic spend balance is insufficient
    ///
    /// @param fulfiller The address of the fulfiller
    /// @param amount    The amount of eth to convert for gas
    function _convertEthForGas(address fulfiller, uint256 amount) private {
        uint256 balance = _magicSpendBalance[fulfiller][_NATIVE_ASSET];

        if (amount > balance) {
            revert InsufficientMagicSpendBalance(fulfiller, balance, amount);
        }

        unchecked {
            _magicSpendBalance[fulfiller][_NATIVE_ASSET] -= amount;
            _ethForGas[fulfiller] += amount;
            totalTrackedGasBalance += amount;
        }

        address(ENTRY_POINT).safeTransferETH(amount);
    }

    /// @notice A function that settles the balance difference between the paymaster and the EntryPoint
    ///
    /// @dev This is called for every User Operation
    ///
    /// @param maxCost The maximum cost of the user operation
    function _settleBalanceDiff(uint256 maxCost) private {
        address prevFulfiller_ = prevFulfiller;
        if (prevFulfiller_ == address(0)) return;

        uint256 diff = _calculateBalanceDiff(maxCost);

        // The diff should never be higher than `totalTrackedGasBalance` or `_ethForGas[prevFulfiller_]`
        unchecked {
            totalTrackedGasBalance -= diff;
            _ethForGas[prevFulfiller_] -= diff;
        }

        prevFulfiller = address(0);
    }

    /// @notice Sends `amount` tokens of type `token` to `to` address
    ///
    /// @param token  Address of currency
    /// @param to     Address to send tokens to
    /// @param amount Amount of tokens to send
    function _sendTokens(address token, address to, uint256 amount) private {
        if (token.addressToBytes32() == _NATIVE_ASSET) {
            to.safeTransferETH(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    /// @notice A function that calculates the difference between the total tracked gas balance in the paymaster and
    ///         the paymaster's balance in EntryPoint
    ///
    /// @param maxCost The maximum cost of the user operation
    ///
    /// @return diff The balance difference
    function _calculateBalanceDiff(uint256 maxCost) private view returns (uint256) {
        uint256 totalTrackedEthBalance_ = totalTrackedGasBalance;

        // Adding maxCost here to account for the case where maxCost has already been deducted from the paymaster
        // balance in EntryPoint
        uint256 entryPointBalance = ENTRY_POINT.balanceOf(address(this)) + maxCost;

        return totalTrackedEthBalance_ - entryPointBalance;
    }

    function _extractMagicSpendAndPrecheck(bytes[] memory attributes)
        private
        pure
        returns (bytes32, uint256, address)
    {
        bytes32 magicSpendToken;
        uint256 magicSpendAmount;
        address precheckContract;

        for (uint256 i; i < attributes.length; i++) {
            bytes4 selector = bytes4(attributes[i]);
            if (selector == _MAGIC_SPEND_REQUEST_SELECTOR) {
                (magicSpendToken, magicSpendAmount) = abi.decode(_attributeContents(attributes[i]), (bytes32, uint256));
            } else if (selector == _PRECHECK_ATTRIBUTE_SELECTOR) {
                precheckContract = abi.decode(_attributeContents(attributes[i]), (address));
            }
        }

        return (magicSpendToken, magicSpendAmount, precheckContract);
    }

    function _attributeContents(bytes memory attribute) private pure returns (bytes memory) {
        bytes memory data = attribute;
        assembly {
            data := add(data, 0x4)
        }
        return data;
    }
}
