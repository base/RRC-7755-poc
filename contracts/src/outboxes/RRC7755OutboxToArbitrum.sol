// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ArbitrumProver} from "../libraries/provers/ArbitrumProver.sol";
import {GlobalTypes} from "../libraries/GlobalTypes.sol";
import {RRC7755Inbox} from "../RRC7755Inbox.sol";
import {RRC7755Outbox} from "../RRC7755Outbox.sol";

/// @title RRC7755OutboxToArbitrum
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on
///         Arbitrum
contract RRC7755OutboxToArbitrum is RRC7755Outbox {
    using ArbitrumProver for bytes;
    using GlobalTypes for bytes32;

    /// @notice This struct is used to process attributes while avoiding stack too deep errors
    struct ProcessAttributesState {
        /// @dev The selectors that are required for the request
        bytes4[] requiredSelectors;
        /// @dev Whether each required selector has been processed
        bool[] processed;
    }

    /// @notice This error is thrown when a duplicate attribute is found
    ///
    /// @param selector The selector of the duplicate attribute
    error DuplicateAttribute(bytes4 selector);

    /// @notice Returns the required attributes for this contract
    function getRequiredAttributes(bool isUserOp) external pure override returns (bytes4[] memory) {
        return _getRequiredAttributes(isUserOp);
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
    ) public override {
        if (msg.sender != address(this)) {
            revert InvalidCaller({caller: msg.sender, expectedCaller: address(this)});
        }

        // Define required attributes and their handlers
        ProcessAttributesState memory state;
        state.requiredSelectors = _getRequiredAttributes(requireInbox);
        state.processed = new bool[](state.requiredSelectors.length);

        // Process all attributes
        for (uint256 i; i < attributes.length; i++) {
            bytes4 selector = bytes4(attributes[i]);

            uint256 index = _findSelectorIndex(selector, state.requiredSelectors);
            if (index != type(uint256).max) {
                if (state.processed[index]) {
                    revert DuplicateAttribute(selector);
                }

                _processAttribute(selector, attributes[i], requester, value, messageId);
                state.processed[index] = true;
            } else if (!_isOptionalAttribute(selector)) {
                revert UnsupportedAttribute(selector);
            }
        }

        // Check for missing required attributes
        for (uint256 i; i < state.requiredSelectors.length; i++) {
            if (!state.processed[i]) {
                revert MissingRequiredAttribute(state.requiredSelectors[i]);
            }
        }
    }

    /// @notice Returns true if the attribute selector is supported by this contract
    ///
    /// @param selector The selector of the attribute
    ///
    /// @return _ True if the attribute selector is supported by this contract
    function supportsAttribute(bytes4 selector) public pure override returns (bool) {
        return selector == _REWARD_ATTRIBUTE_SELECTOR || selector == _L2_ORACLE_ATTRIBUTE_SELECTOR
            || selector == _NONCE_ATTRIBUTE_SELECTOR || selector == _REQUESTER_ATTRIBUTE_SELECTOR
            || selector == _DELAY_ATTRIBUTE_SELECTOR || super.supportsAttribute(selector);
    }

    /// @notice Returns the minimum amount of time before a request can expire
    function _minExpiryTime(uint256) internal pure override returns (uint256) {
        return 8 days;
    }

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo not found at verifyingContractStorageKey on request.verifyingContract
    /// @custom:reverts If the L2StorageRoot does not correspond to our validated L1 storage slot
    /// @custom:reverts If caller is not the address in the proof storage value
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    ///                                `RRC7755Inbox` contract
    /// @param inbox                   The address of the `RRC7755Inbox` contract
    /// @param attributes              The attributes of the request
    /// @param proof                   The proof to validate
    /// @param caller                  The address of the caller
    function _validateProof(
        bytes memory inboxContractStorageKey,
        bytes32 inbox,
        bytes[] calldata attributes,
        bytes calldata proof,
        address caller
    ) internal view override {
        bytes calldata l2OracleAttribute = _locateAttribute(attributes, _L2_ORACLE_ATTRIBUTE_SELECTOR);
        address l2Oracle = abi.decode(l2OracleAttribute[4:], (address));
        bytes memory inboxContractStorageValue = proof.validate(
            ArbitrumProver.Target({
                l1Address: l2Oracle,
                l2Address: inbox.bytes32ToAddress(),
                l2StorageKey: inboxContractStorageKey
            })
        );

        RRC7755Inbox.FulfillmentInfo memory fulfillmentInfo = _decodeFulfillmentInfo(bytes32(inboxContractStorageValue));

        if (fulfillmentInfo.fulfiller != caller) {
            revert InvalidCaller({expectedCaller: fulfillmentInfo.fulfiller, caller: caller});
        }
    }

    /// @dev Helper function to process individual attributes
    function _processAttribute(
        bytes4 selector,
        bytes calldata attribute,
        address requester,
        uint256 value,
        bytes32 messageId
    ) private {
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
        }
    }

    /// @dev Helper function to find the index of a selector in the array
    function _findSelectorIndex(bytes4 selector, bytes4[] memory selectors) private pure returns (uint256) {
        for (uint256 i; i < selectors.length; i++) {
            if (selector == selectors[i]) return i;
        }
        return type(uint256).max; // Not found
    }

    function _getRequiredAttributes(bool requireInbox) private pure returns (bytes4[] memory) {
        bytes4[] memory requiredSelectors = new bytes4[](requireInbox ? 6 : 5);
        requiredSelectors[0] = _REWARD_ATTRIBUTE_SELECTOR;
        requiredSelectors[1] = _L2_ORACLE_ATTRIBUTE_SELECTOR;
        requiredSelectors[2] = _NONCE_ATTRIBUTE_SELECTOR;
        requiredSelectors[3] = _REQUESTER_ATTRIBUTE_SELECTOR;
        requiredSelectors[4] = _DELAY_ATTRIBUTE_SELECTOR;
        if (requireInbox) {
            requiredSelectors[5] = _INBOX_ATTRIBUTE_SELECTOR;
        }
        return requiredSelectors;
    }
}
