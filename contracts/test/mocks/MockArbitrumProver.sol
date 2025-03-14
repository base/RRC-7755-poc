// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RRC7755OutboxToArbitrum} from "../../src/outboxes/RRC7755OutboxToArbitrum.sol";

contract MockArbitrumProver is RRC7755OutboxToArbitrum {
    function minExpiryTime(uint256 finalityDelay) external pure returns (uint256) {
        return _minExpiryTime(finalityDelay);
    }

    function validateProof(
        bytes32 destinationChain,
        bytes memory storageKey,
        bytes32 inbox,
        bytes[] calldata attributes,
        bytes calldata proof
    ) external view {
        _validateProof(destinationChain, storageKey, inbox, attributes, proof, msg.sender);
    }

    // Including to block from coverage report
    function test() external {}
}
