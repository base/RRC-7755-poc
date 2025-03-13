// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RRC7755Outbox} from "../../src/RRC7755Outbox.sol";

contract MockOutbox is RRC7755Outbox {
    function _minExpiryTime(uint256) internal pure override returns (uint256) {
        return 10;
    }

    function _validateProof(
        bytes32 destinationChain,
        bytes memory inboxContractStorageKey,
        bytes32 inbox,
        bytes[] calldata attributes,
        bytes calldata proofData,
        address caller
    ) internal view override {}

    function _getRequiredAttributes(bool) internal pure override returns (bytes4[] memory) {
        bytes4[] memory requiredSelectors = new bytes4[](4);
        requiredSelectors[0] = _REWARD_ATTRIBUTE_SELECTOR;
        requiredSelectors[1] = _NONCE_ATTRIBUTE_SELECTOR;
        requiredSelectors[2] = _REQUESTER_ATTRIBUTE_SELECTOR;
        requiredSelectors[3] = _DELAY_ATTRIBUTE_SELECTOR;
        return requiredSelectors;
    }

    // Including to block from coverage report
    function test() external {}
}
