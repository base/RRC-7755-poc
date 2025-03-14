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
        bytes32,
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

    /// @notice Returns the minimum amount of time before a request can expire
    function _minExpiryTime(uint256) internal pure override returns (uint256) {
        return 8 days;
    }

    function _getRequiredAttributes(bool isUserOp) internal pure override returns (bytes4[] memory) {
        bytes4[] memory requiredSelectors = new bytes4[](isUserOp ? 7 : 5);
        requiredSelectors[0] = _REWARD_ATTRIBUTE_SELECTOR;
        requiredSelectors[1] = _L2_ORACLE_ATTRIBUTE_SELECTOR;
        requiredSelectors[2] = _NONCE_ATTRIBUTE_SELECTOR;
        requiredSelectors[3] = _REQUESTER_ATTRIBUTE_SELECTOR;
        requiredSelectors[4] = _DELAY_ATTRIBUTE_SELECTOR;
        if (isUserOp) {
            requiredSelectors[5] = _INBOX_ATTRIBUTE_SELECTOR;
            requiredSelectors[6] = _SOURCE_CHAIN_ATTRIBUTE_SELECTOR;
        }
        return requiredSelectors;
    }
}
