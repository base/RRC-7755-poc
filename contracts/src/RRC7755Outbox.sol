// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {UserOperationLib} from "account-abstraction/core/UserOperationLib.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {GlobalTypes} from "./libraries/GlobalTypes.sol";
import {NonceManager} from "./NonceManager.sol";
import {RRC7755Base} from "./RRC7755Base.sol";
import {RRC7755Inbox} from "./RRC7755Inbox.sol";

/// @title RRC7755Outbox
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice A source contract for initiating RRC-7755 Cross Chain Requests as well as reward fulfillment to Fulfillers
///         that submit the cross chain calls to destination chains.
abstract contract RRC7755Outbox is RRC7755Base, NonceManager {
    using GlobalTypes for address;
    using GlobalTypes for bytes32;
    using UserOperationLib for PackedUserOperation;
    using SafeTransferLib for address;

    /// @notice An enum representing the status of an RRC-7755 cross chain call
    enum CrossChainCallStatus {
        None,
        Requested,
        Canceled,
        Completed
    }

    /// @notice The selector for the nonce attribute
    bytes4 internal constant _NONCE_ATTRIBUTE_SELECTOR = 0xce03fdab; // nonce(uint256)

    /// @notice The selector for the reward attribute
    bytes4 internal constant _REWARD_ATTRIBUTE_SELECTOR = 0xa362e5db; // reward(bytes32,uint256) rewardAsset, rewardAmount

    /// @notice The selector for the delay attribute
    bytes4 internal constant _DELAY_ATTRIBUTE_SELECTOR = 0x84f550e0; // delay(uint256,uint256) finalityDelaySeconds, expiry

    /// @notice The selector for the requester attribute
    bytes4 internal constant _REQUESTER_ATTRIBUTE_SELECTOR = 0x3bd94e4c; // requester(bytes32)

    /// @notice The selector for the l2Oracle attribute
    bytes4 internal constant _L2_ORACLE_ATTRIBUTE_SELECTOR = 0x7ff7245a; // l2Oracle(address)

    /// @notice The selector for the source chain attribute
    bytes4 internal constant _SOURCE_CHAIN_ATTRIBUTE_SELECTOR = 0x10b2cb84; // sourceChain(bytes32,bytes32)

    /// @notice A mapping from the keccak256 hash of a message request to its current status
    mapping(bytes32 messageId => CrossChainCallStatus status) private _messageStatus;

    /// @notice A mapping from the keccak256 hash of a message request to the amount of reward received
    mapping(bytes32 messageId => uint256 amountReceived) private _amountReceived;

    /// @notice The bytes32 representation of the address representing the native currency of the blockchain this
    ///         contract is deployed on following ERC-7528
    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    /// @notice Main storage location used as the base for the fulfillmentInfo mapping following EIP-7201.
    ///         keccak256(abi.encode(uint256(keccak256(bytes("RRC-7755"))) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _VERIFIER_STORAGE_LOCATION =
        0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00;

    /// @notice The expected entry point receiver for UserOp requests
    bytes32 private constant _EXPECTED_ENTRY_POINT = 0x0000000000000000000000000000000071727de22e5e9d8baf0edac6f37da032;

    /// @notice The duration, in excess of CrossChainRequest.expiry, which must pass before a request can be canceled
    uint256 public constant CANCEL_DELAY_SECONDS = 1 days;

    /// @notice Event emitted when a user sends a message to the `RRC7755Inbox`
    ///
    /// @param messageId        The keccak256 hash of the message request
    /// @param sourceChain      The chain identifier of the source chain
    /// @param sender           The account address of the sender
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The messages to be included in the request
    /// @param attributes       The attributes to be included in the message
    event MessagePosted(
        bytes32 indexed messageId,
        bytes32 sourceChain,
        bytes32 sender,
        bytes32 destinationChain,
        bytes32 receiver,
        bytes payload,
        bytes[] attributes
    );

    /// @notice Event emitted when a cross chain call is successfully completed
    ///
    /// @param messageId The keccak256 hash of a `CrossChainRequest`
    /// @param submitter   The address of the fulfiller that successfully completed the cross chain call
    event CrossChainCallCompleted(bytes32 indexed messageId, address submitter);

    /// @notice Event emitted when an expired cross chain call request is canceled
    ///
    /// @param messageId The keccak256 hash of a `CrossChainRequest`
    event CrossChainCallCanceled(bytes32 indexed messageId);

    /// @notice This error is thrown when a cross chain request specifies the native currency as the reward type but
    ///         does not send the correct `msg.value`
    ///
    /// @param expected The expected `msg.value` that should have been sent with the transaction
    /// @param received The actual `msg.value` that was sent with the transaction
    error InvalidValue(uint256 expected, uint256 received);

    /// @notice This error is thrown if a user attempts to cancel a request or a fulfiller attempts to claim a reward for
    ///         a request that is not in the `CrossChainCallStatus.Requested` state
    ///
    /// @param expected The expected status during the transaction
    /// @param actual   The actual request status during the transaction
    error InvalidStatus(CrossChainCallStatus expected, CrossChainCallStatus actual);

    /// @notice This error is thrown if an attempt to cancel a request is made before the request's expiry timestamp
    ///
    /// @param currentTimestamp The current block timestamp
    /// @param expiry           The timestamp at which the request expires
    error CannotCancelRequestBeforeExpiry(uint256 currentTimestamp, uint256 expiry);

    /// @notice This error is thrown if an account attempts to call processAttributes
    ///
    /// @param caller         The account attempting the request cancellation
    /// @param expectedCaller The account that created the request
    error InvalidCaller(address caller, address expectedCaller);

    /// @notice This error is thrown if a request expiry does not give enough time for the delay attribute to pass
    error ExpiryTooSoon();

    /// @notice This error is thrown if an unsupported attribute is provided
    ///
    /// @param selector The selector of the unsupported attribute
    error UnsupportedAttribute(bytes4 selector);

    /// @notice This error is thrown if a required attribute is missing from the global attributes array for a 7755
    ///         request
    ///
    /// @param selector The selector of the missing attribute
    error MissingRequiredAttribute(bytes4 selector);

    /// @notice This error is thrown if the passed in nonce is incorrect
    error InvalidNonce();

    /// @notice This error is thrown if the passed in requester is not equal to msg.sender
    error InvalidRequester();

    /// @notice This error is thrown if the receiver for a UserOp request is not the expected entry point
    error InvalidReceiver();

    /// @notice This error is thrown if the specified source chain is incorrect for a UserOp request
    error InvalidSourceChain();

    /// @notice This error is thrown if the specified sender is not this address for a UserOp request
    error InvalidSender();

    /// @notice Initiates the sending of a 7755 request containing a single message
    ///
    /// @custom:reverts If a required attribute is missing from the global attributes array
    /// @custom:reverts If an unsupported attribute is provided
    ///
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The encoded calls array
    /// @param attributes       The attributes to be included in the message
    ///
    /// @return messageId The generated request id
    function sendMessage(
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes
    ) external payable returns (bytes32) {
        bytes32 sender = address(this).addressToBytes32();
        bytes32 sourceChain = bytes32(block.chainid);

        bytes32 messageId = getMessageId(sourceChain, sender, destinationChain, receiver, payload, attributes);

        if (attributes.length == 0) {
            if (receiver != _EXPECTED_ENTRY_POINT) {
                revert InvalidReceiver();
            }

            bytes[] memory userOpAttributes = _getUserOpAttributes(payload);
            this.processAttributes(messageId, userOpAttributes, msg.sender, msg.value, true);
        } else {
            this.processAttributes(messageId, attributes, msg.sender, msg.value, false);
        }

        _messageStatus[messageId] = CrossChainCallStatus.Requested;

        emit MessagePosted(messageId, sourceChain, sender, destinationChain, receiver, payload, attributes);

        return messageId;
    }

    /// @notice To be called by a fulfiller that successfully submitted a cross chain request to the destination chain and
    ///         can prove it with a valid nested storage proof
    ///
    /// @custom:reverts If the request is not in the `CrossChainCallStatus.Requested` state
    /// @custom:reverts If storage proof invalid
    /// @custom:reverts If finality delay seconds have not passed since the request was fulfilled on destination chain
    /// @custom:reverts If the reward attribute is not found in the attributes array
    ///
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The encoded calls array
    /// @param attributes       The attributes to be included in the message
    /// @param proof            A proof that cryptographically verifies that `fulfillmentInfo` does, indeed, exist in
    ///                         storage on the destination chain
    /// @param payTo            The address the fulfiller wants to receive the reward
    function claimReward(
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes,
        bytes calldata proof,
        address payTo
    ) external {
        bytes32 sender = address(this).addressToBytes32();
        bytes32 sourceChain = bytes32(block.chainid);
        bytes32 messageId = super.getMessageId(sourceChain, sender, destinationChain, receiver, payload, attributes);

        bytes memory storageKey = abi.encode(keccak256(abi.encodePacked(messageId, _VERIFIER_STORAGE_LOCATION)));
        _validateProof(destinationChain, storageKey, receiver, attributes, proof, msg.sender);

        (bytes32 rewardAsset, uint256 rewardAmount) = _getReward(messageId, attributes);

        _processClaim(messageId, payTo, rewardAsset, rewardAmount);
    }

    /// @notice To be called by a fulfiller that successfully submitted a cross chain user operation to the destination chain
    ///
    /// @custom:reverts If the request is not in the `CrossChainCallStatus.Requested` state
    /// @custom:reverts If storage proof invalid
    /// @custom:reverts If finality delay seconds have not passed since the request was fulfilled on destination chain
    /// @custom:reverts If the reward attribute is not found in the attributes array
    ///
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param userOp           The ERC-4337 User Operation
    /// @param proof            A proof that cryptographically verifies that `fulfillmentInfo` does, indeed, exist in
    ///                         storage on the destination chain
    /// @param payTo            The address the fulfiller wants to receive the reward
    function claimReward(
        bytes32 destinationChain,
        bytes32 receiver,
        PackedUserOperation calldata userOp,
        bytes calldata proof,
        address payTo
    ) external {
        bytes32 messageId = getUserOpHash(userOp, receiver, destinationChain);

        bytes memory storageKey = abi.encode(keccak256(abi.encodePacked(messageId, _VERIFIER_STORAGE_LOCATION)));
        bytes[] memory attributes = getUserOpAttributes(userOp);
        (bytes32 rewardAsset, uint256 rewardAmount) =
            this.innerValidateProofAndGetReward(messageId, destinationChain, storageKey, attributes, proof, msg.sender);

        _processClaim(messageId, payTo, rewardAsset, rewardAmount);
    }

    /// @notice Cancels a pending request that has expired
    ///
    /// @custom:reverts If the request is not in the `CrossChainCallStatus.Requested` state
    /// @custom:reverts If the current block timestamp is less than the expiry timestamp plus the cancel delay seconds
    ///
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The encoded calls to be included in the request
    /// @param attributes       The attributes to be included in the message
    function cancelMessage(
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes
    ) external {
        bytes32 sender = address(this).addressToBytes32();
        bytes32 sourceChain = bytes32(block.chainid);
        bytes32 messageId = super.getMessageId(sourceChain, sender, destinationChain, receiver, payload, attributes);

        (bytes32 requester, uint256 expiry, bytes32 rewardAsset, uint256 rewardAmount) =
            getRequesterAndExpiryAndReward(messageId, attributes);

        _processCancellation(messageId, requester, expiry, rewardAsset, rewardAmount);
    }

    /// @notice Cancels a pending user op request that has expired
    ///
    /// @custom:reverts If the request is not in the `CrossChainCallStatus.Requested` state
    /// @custom:reverts If the current block timestamp is less than the expiry timestamp plus the cancel delay seconds
    ///
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param userOp           The ERC-4337 User Operation
    function cancelUserOp(bytes32 destinationChain, bytes32 receiver, PackedUserOperation calldata userOp) external {
        bytes32 messageId = getUserOpHash(userOp, receiver, destinationChain);
        bytes[] memory attributes = getUserOpAttributes(userOp);

        (bytes32 requester, uint256 expiry, bytes32 rewardAsset, uint256 rewardAmount) =
            this.getRequesterAndExpiryAndReward(messageId, attributes);

        _processCancellation(messageId, requester, expiry, rewardAsset, rewardAmount);
    }

    /// @notice Returns the cross chain call request status for a hashed request
    ///
    /// @param messageId The keccak256 hash of a message request
    ///
    /// @return _ The `CrossChainCallStatus` status for the associated message request
    function getMessageStatus(bytes32 messageId) external view returns (CrossChainCallStatus) {
        return _messageStatus[messageId];
    }

    /// @notice Returns the required attributes for this contract
    ///
    /// @param isUserOp Whether the request is an ERC-4337 User Operation
    ///
    /// @return _ The required attributes for this contract
    function getRequiredAttributes(bool isUserOp) external pure returns (bytes4[] memory) {
        return _getRequiredAttributes(isUserOp);
    }

    /// @notice Returns the optional attributes for this contract
    ///
    /// @return _ The optional attributes for this contract
    function getOptionalAttributes() external pure returns (bytes4[] memory) {
        return _getOptionalAttributes();
    }

    /// @notice This is only to be called by this contract during a `sendMessage` call
    ///
    /// @custom:reverts If the caller is not this contract
    ///
    /// @param messageId    The keccak256 hash of the message request
    /// @param attributes   The attributes to be processed
    /// @param requester    The address of the requester
    /// @param value        The value of the message
    /// @param requireInbox Whether the inbox attribute is required
    function processAttributes(
        bytes32 messageId,
        bytes[] calldata attributes,
        address requester,
        uint256 value,
        bool requireInbox
    ) public {
        if (msg.sender != address(this)) {
            revert InvalidCaller({caller: msg.sender, expectedCaller: address(this)});
        }

        // Define required attributes and their handlers
        ProcessAttributesState memory state;
        state.requiredSelectors = _getRequiredAttributes(requireInbox);
        state.processedRequired = new bool[](state.requiredSelectors.length);
        state.optionalSelectors = _getOptionalAttributes();
        state.processedOptional = new bool[](state.optionalSelectors.length);

        // Process all attributes
        for (uint256 i; i < attributes.length; i++) {
            bytes4 selector = bytes4(attributes[i]);

            uint256 index = _findSelectorIndex(selector, state.requiredSelectors);
            if (index != type(uint256).max) {
                if (state.processedRequired[index]) {
                    revert DuplicateAttribute(selector);
                }

                _processAttribute(selector, attributes[i], requester, value, messageId);
                state.processedRequired[index] = true;
                continue;
            }

            index = _findSelectorIndex(selector, state.optionalSelectors);

            if (index == type(uint256).max) {
                revert UnsupportedAttribute(selector);
            }

            if (state.processedOptional[index]) {
                revert DuplicateAttribute(selector);
            }

            state.processedOptional[index] = true;
        }

        // Check for missing required attributes
        for (uint256 i; i < state.requiredSelectors.length; i++) {
            if (!state.processedRequired[i]) {
                revert MissingRequiredAttribute(state.requiredSelectors[i]);
            }
        }
    }

    /// @notice Validates storage proofs and verifies fill
    ///
    /// @custom:reverts If storage proof invalid
    /// @custom:reverts If fillInfo not found at inboxContractStorageKey on crossChainCall.verifyingContract
    /// @custom:reverts If fillInfo.timestamp is less than crossChainCall.finalityDelaySeconds from current destination
    ///                 chain block timestamp
    ///
    /// @param messageId               The keccak256 hash of the message request
    /// @param destinationChain        The destination chain identifier
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    ///                                `RRC7755Inbox` contract
    /// @param attributes              The attributes to be included in the message
    /// @param proofData               The proof to validate
    /// @param caller                  The address of the caller
    ///
    /// @return _ The reward asset and reward amount
    function innerValidateProofAndGetReward(
        bytes32 messageId,
        bytes32 destinationChain,
        bytes memory inboxContractStorageKey,
        bytes[] calldata attributes,
        bytes calldata proofData,
        address caller
    ) public view returns (bytes32, uint256) {
        (bytes32 rewardAsset, uint256 rewardAmount, bytes32 inbox) = _getRewardAndInbox(messageId, attributes);
        _validateProof(destinationChain, inboxContractStorageKey, inbox, attributes, proofData, caller);
        return (rewardAsset, rewardAmount);
    }

    /// @notice Returns the keccak256 hash of a message request or the user op hash if the request is an ERC-4337 User
    ///         Operation
    ///
    /// @param sourceChain      The source chain identifier
    /// @param sender           The account address of the sender
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The messages to be included in the request
    /// @param attributes       The attributes to be included in the message
    ///
    /// @return _ The keccak256 hash of the message request
    function getMessageId(
        bytes32 sourceChain,
        bytes32 sender,
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes
    ) public view override returns (bytes32) {
        return attributes.length == 0
            ? this.getUserOpHash(abi.decode(payload, (PackedUserOperation)), receiver, destinationChain)
            : super.getMessageId(sourceChain, sender, destinationChain, receiver, payload, attributes);
    }

    /// @notice Returns the requester, expiry, reward asset, and reward amount from the attributes array
    ///
    /// @param messageId The keccak256 hash of the message request
    /// @param attributes The attributes to be included in the message
    ///
    /// @return _ The requester, expiry, reward asset, and reward amount
    function getRequesterAndExpiryAndReward(bytes32 messageId, bytes[] calldata attributes)
        public
        view
        returns (bytes32, uint256, bytes32, uint256)
    {
        bytes32 requester;
        uint256 expiry;
        bytes32 rewardAsset;

        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == _REQUESTER_ATTRIBUTE_SELECTOR) {
                requester = abi.decode(attributes[i][4:], (bytes32));
            } else if (bytes4(attributes[i]) == _DELAY_ATTRIBUTE_SELECTOR) {
                (, expiry) = abi.decode(attributes[i][4:], (uint256, uint256));
            } else if (bytes4(attributes[i]) == _REWARD_ATTRIBUTE_SELECTOR) {
                (rewardAsset,) = abi.decode(attributes[i][4:], (bytes32, uint256));
            }
        }

        return (requester, expiry, rewardAsset, _amountReceived[messageId]);
    }

    /// @notice Returns the hash of an ERC-4337 User Operation
    ///
    /// @param userOp           The ERC-4337 User Operation
    /// @param receiver         The destination chain EntryPoint contract address
    /// @param destinationChain The destination chain identifier
    ///
    /// @return _ The hash of the ERC-4337 User Operation
    function getUserOpHash(PackedUserOperation calldata userOp, bytes32 receiver, bytes32 destinationChain)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(userOp.hash(), receiver.bytes32ToAddress(), uint256(destinationChain)));
    }

    /// @notice Returns the attributes for an ERC-4337 User Operation
    ///
    /// @param userOp The ERC-4337 User Operation
    ///
    /// @return _ The attributes for the ERC-4337 User Operation
    function getUserOpAttributes(PackedUserOperation calldata userOp) public pure returns (bytes[] memory) {
        return abi.decode(userOp.paymasterAndData[52:], (bytes[]));
    }

    /// @notice Returns true if the attribute selector is supported by this contract
    ///
    /// @param selector The selector of the attribute
    ///
    /// @return _ True if the attribute selector is supported by this contract
    function supportsAttribute(bytes4 selector) public pure returns (bool) {
        uint256 requiredIndex = _findSelectorIndex(selector, _getRequiredAttributes(true));
        uint256 optionalIndex = _findSelectorIndex(selector, _getOptionalAttributes());

        return requiredIndex != type(uint256).max || optionalIndex != type(uint256).max;
    }

    /// @dev Helper function to process individual attributes
    function _processAttribute(
        bytes4 selector,
        bytes calldata attribute,
        address requester,
        uint256 value,
        bytes32 messageId
    ) internal virtual {
        if (selector == _REWARD_ATTRIBUTE_SELECTOR) {
            _handleRewardAttribute(attribute, requester, value, messageId);
        } else if (selector == _NONCE_ATTRIBUTE_SELECTOR) {
            if (abi.decode(attribute[4:], (uint256)) != _incrementNonce(requester)) {
                revert InvalidNonce();
            }
        } else if (selector == _REQUESTER_ATTRIBUTE_SELECTOR) {
            if (abi.decode(attribute[4:], (address)) != requester) {
                revert InvalidRequester();
            }
        } else if (selector == _DELAY_ATTRIBUTE_SELECTOR) {
            _handleDelayAttribute(attribute);
        } else if (selector == _SOURCE_CHAIN_ATTRIBUTE_SELECTOR) {
            (uint256 sourceChain, address sender) = abi.decode(attribute[4:], (uint256, address));
            if (sourceChain != uint256(block.chainid)) {
                revert InvalidSourceChain();
            }
            if (sender != address(this)) {
                revert InvalidSender();
            }
        }
    }

    /// @notice Validates storage proofs and verifies fill
    ///
    /// @custom:reverts If storage proof invalid
    /// @custom:reverts If fillInfo not found at inboxContractStorageKey on crossChainCall.verifyingContract
    /// @custom:reverts If fillInfo.timestamp is less than crossChainCall.finalityDelaySeconds from current destination
    ///                 chain block timestamp
    /// @custom:reverts If caller is not the address in the proof storage value
    ///
    /// @dev Implementation will vary by L2
    ///
    /// @param destinationChain        The destination chain identifier
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    ///                                `RRC7755Inbox` contract
    /// @param inbox                   The address of the `RRC7755Inbox` contract
    /// @param attributes              The attributes to be included in the message
    /// @param proofData               The proof to validate
    /// @param caller                  The address of the caller
    function _validateProof(
        bytes32 destinationChain,
        bytes memory inboxContractStorageKey,
        bytes32 inbox,
        bytes[] calldata attributes,
        bytes calldata proofData,
        address caller
    ) internal view virtual;

    /// @notice Returns the minimum amount of time before a request can expire
    ///
    /// @param finalityDelaySeconds The amount of time that must pass before a fulfiller is able to claim their reward
    function _minExpiryTime(uint256 finalityDelaySeconds) internal pure virtual returns (uint256);

    /// @notice Decodes the `FulfillmentInfo` struct from the `RRC7755Inbox` storage slot
    ///
    /// @param inboxContractStorageValue The storage value of the `RRC7755Inbox` storage slot
    ///
    /// @return fulfillmentInfo The decoded `FulfillmentInfo` struct
    function _decodeFulfillmentInfo(bytes32 inboxContractStorageValue)
        internal
        pure
        returns (RRC7755Inbox.FulfillmentInfo memory)
    {
        RRC7755Inbox.FulfillmentInfo memory fulfillmentInfo;
        fulfillmentInfo.fulfiller = address(uint160((uint256(inboxContractStorageValue) >> 96) & type(uint160).max));
        fulfillmentInfo.timestamp = uint96(uint256(inboxContractStorageValue));
        return fulfillmentInfo;
    }

    function _getRequiredAttributes(bool isUserOp) internal pure virtual returns (bytes4[] memory);

    function _getOptionalAttributes() internal pure virtual returns (bytes4[] memory) {
        bytes4[] memory optionalSelectors = new bytes4[](3);
        optionalSelectors[0] = _PRECHECK_ATTRIBUTE_SELECTOR;
        optionalSelectors[1] = _MAGIC_SPEND_REQUEST_SELECTOR;
        optionalSelectors[2] = _INBOX_ATTRIBUTE_SELECTOR;
        return optionalSelectors;
    }

    function _handleRewardAttribute(bytes calldata attribute, address requester, uint256 value, bytes32 messageId)
        internal
    {
        (bytes32 rewardAsset, uint256 rewardAmount) = abi.decode(attribute[4:], (bytes32, uint256));

        bool usingNativeCurrency = rewardAsset == _NATIVE_ASSET;
        uint256 expectedValue = usingNativeCurrency ? rewardAmount : 0;

        if (value != expectedValue) {
            revert InvalidValue(expectedValue, value);
        }

        if (!usingNativeCurrency) {
            uint256 balanceBefore = IERC20(rewardAsset.bytes32ToAddress()).balanceOf(address(this));
            rewardAsset.bytes32ToAddress().safeTransferFrom(requester, address(this), rewardAmount);
            uint256 balanceAfter = IERC20(rewardAsset.bytes32ToAddress()).balanceOf(address(this));
            _amountReceived[messageId] = balanceAfter - balanceBefore;
        } else {
            _amountReceived[messageId] = rewardAmount;
        }
    }

    function _handleDelayAttribute(bytes calldata attribute) internal view {
        (uint256 finalityDelaySeconds, uint256 expiry) = abi.decode(attribute[4:], (uint256, uint256));

        if (expiry < block.timestamp + _minExpiryTime(finalityDelaySeconds)) {
            revert ExpiryTooSoon();
        }
    }

    function _processClaim(bytes32 messageId, address payTo, bytes32 rewardAsset, uint256 rewardAmount) private {
        _checkValidStatus({messageId: messageId, expectedStatus: CrossChainCallStatus.Requested});
        _messageStatus[messageId] = CrossChainCallStatus.Completed;
        _sendReward(payTo, rewardAsset, rewardAmount);

        emit CrossChainCallCompleted(messageId, msg.sender);
    }

    function _processCancellation(
        bytes32 messageId,
        bytes32 requester,
        uint256 expiry,
        bytes32 rewardAsset,
        uint256 rewardAmount
    ) private {
        _checkValidStatus({messageId: messageId, expectedStatus: CrossChainCallStatus.Requested});

        if (block.timestamp < expiry + CANCEL_DELAY_SECONDS) {
            revert CannotCancelRequestBeforeExpiry({
                currentTimestamp: block.timestamp,
                expiry: expiry + CANCEL_DELAY_SECONDS
            });
        }

        _messageStatus[messageId] = CrossChainCallStatus.Canceled;

        // Return the stored reward back to the original requester
        _sendReward(requester.bytes32ToAddress(), rewardAsset, rewardAmount);

        emit CrossChainCallCanceled(messageId);
    }

    function _sendReward(address to, bytes32 rewardAsset, uint256 rewardAmount) private {
        if (rewardAsset == _NATIVE_ASSET) {
            to.safeTransferETH(rewardAmount);
        } else {
            rewardAsset.bytes32ToAddress().safeTransfer(to, rewardAmount);
        }
    }

    function _checkValidStatus(bytes32 messageId, CrossChainCallStatus expectedStatus) private view {
        CrossChainCallStatus status = _messageStatus[messageId];

        if (status != expectedStatus) {
            revert InvalidStatus({expected: expectedStatus, actual: status});
        }
    }

    function _getUserOpAttributes(bytes calldata payload) private view returns (bytes[] memory) {
        PackedUserOperation memory userOp = abi.decode(payload, (PackedUserOperation));
        return this.getUserOpAttributes(userOp);
    }

    function _getReward(bytes32 messageId, bytes[] calldata attributes) private view returns (bytes32, uint256) {
        bytes32 rewardAsset;

        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == _REWARD_ATTRIBUTE_SELECTOR) {
                (rewardAsset,) = abi.decode(attributes[i][4:], (bytes32, uint256));
            }
        }

        return (rewardAsset, _amountReceived[messageId]);
    }

    function _getRewardAndInbox(bytes32 messageId, bytes[] calldata attributes)
        private
        view
        returns (bytes32, uint256, bytes32)
    {
        bytes32 rewardAsset;
        bytes32 inbox;

        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == _REWARD_ATTRIBUTE_SELECTOR) {
                (rewardAsset,) = abi.decode(attributes[i][4:], (bytes32, uint256));
            } else if (bytes4(attributes[i]) == _INBOX_ATTRIBUTE_SELECTOR) {
                inbox = abi.decode(attributes[i][4:], (bytes32));
            }
        }

        return (rewardAsset, _amountReceived[messageId], inbox);
    }
}
