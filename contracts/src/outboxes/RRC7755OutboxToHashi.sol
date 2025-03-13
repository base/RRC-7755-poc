// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {HashiProver} from "../libraries/provers/HashiProver.sol";
import {GlobalTypes} from "../libraries/GlobalTypes.sol";
import {RRC7755Inbox} from "../RRC7755Inbox.sol";
import {RRC7755Outbox} from "../RRC7755Outbox.sol";

/// @title RRC7755OutboxToHashi
///
/// @author Crosschain Alliance
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on a EVM
///         chain.
contract RRC7755OutboxToHashi is RRC7755Outbox {
    using HashiProver for bytes;
    using GlobalTypes for bytes32;

    /// @notice The selector for the shoyuBashi attribute
    bytes4 internal constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    ///         current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from current destination
    ///                 chain block timestamp.
    /// @custom:reverts If the L2StateRoot does not correspond to the validated L1 storage slot
    /// @custom:reverts If caller is not the address in the proof storage value
    ///
    /// @param destinationChain        The destination chain identifier
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    ///                                `RRC7755Inbox` contract
    /// @param inbox                   The address of the `RRC7755Inbox` contract
    /// @param attributes              The attributes of the message
    /// @param proof                   The proof to validate
    /// @param caller                  The address of the caller
    function _validateProof(
        bytes32 destinationChain,
        bytes memory inboxContractStorageKey,
        bytes32 inbox,
        bytes[] calldata attributes,
        bytes calldata proof,
        address caller
    ) internal view override {
        address shoyuBashi = _extractShoyuBashi(attributes);
        HashiProver.Target memory target = HashiProver.Target({
            addr: inbox.bytes32ToAddress(),
            storageKey: inboxContractStorageKey,
            destinationChainId: uint256(destinationChain),
            shoyuBashi: shoyuBashi
        });
        (uint256 timestamp, bytes memory inboxContractStorageValue) = proof.validate(target);

        RRC7755Inbox.FulfillmentInfo memory fulfillmentInfo = _decodeFulfillmentInfo(bytes32(inboxContractStorageValue));

        if (fulfillmentInfo.fulfiller != caller) {
            revert InvalidCaller({expectedCaller: fulfillmentInfo.fulfiller, caller: caller});
        }

        bytes calldata delayAttribute = _locateAttribute(attributes, _DELAY_ATTRIBUTE_SELECTOR);
        (uint256 delaySeconds,) = abi.decode(delayAttribute[4:], (uint256, uint256));

        // Ensure that the fulfillment timestamp is not within the finality delay
        if (fulfillmentInfo.timestamp + delaySeconds > timestamp) {
            revert FinalityDelaySecondsInProgress();
        }
    }

    /// @notice Returns the minimum amount of time before a request can expire
    function _minExpiryTime(uint256 finalityDelaySeconds) internal pure override returns (uint256) {
        return finalityDelaySeconds;
    }

    function _extractShoyuBashi(bytes[] calldata attributes) internal pure returns (address) {
        bytes calldata shoyuBashiBytes = _locateAttribute(attributes, _SHOYU_BASHI_ATTRIBUTE_SELECTOR);
        bytes32 shoyuBashiBytes32 = abi.decode(shoyuBashiBytes[4:], (bytes32));
        return shoyuBashiBytes32.bytes32ToAddress();
    }

    function _getRequiredAttributes(bool requireInbox) internal pure override returns (bytes4[] memory) {
        bytes4[] memory requiredSelectors = new bytes4[](requireInbox ? 6 : 5);
        requiredSelectors[0] = _REWARD_ATTRIBUTE_SELECTOR;
        requiredSelectors[1] = _NONCE_ATTRIBUTE_SELECTOR;
        requiredSelectors[2] = _REQUESTER_ATTRIBUTE_SELECTOR;
        requiredSelectors[3] = _DELAY_ATTRIBUTE_SELECTOR;
        requiredSelectors[4] = _SHOYU_BASHI_ATTRIBUTE_SELECTOR;
        if (requireInbox) {
            requiredSelectors[5] = _INBOX_ATTRIBUTE_SELECTOR;
        }
        return requiredSelectors;
    }
}
