// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {HelperConfig} from "../HelperConfig.s.sol";
import {StandardBase} from "../requests/StandardBase.s.sol";

contract HashiBase is StandardBase {
    bytes4 private constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)

    function _initMessage(uint256 destinationChainId, uint256 duration, uint256 nonce, bool isOPStack)
        internal
        override
        returns (bytes32, bytes32, bytes memory, bytes[] memory)
    {
        (bytes32 destinationChain, bytes32 receiver, bytes memory payload, bytes[] memory attributes) =
            super._initMessage(destinationChainId, duration, nonce, isOPStack);
        HelperConfig.NetworkConfig memory srcConfig = helperConfig.getConfig(block.chainid);

        attributes[attributes.length - 1] =
            abi.encodeWithSelector(_SHOYU_BASHI_ATTRIBUTE_SELECTOR, srcConfig.shoyuBashi);

        return (destinationChain, receiver, payload, attributes);
    }

    // Including to block from coverage report
    function test_hashi_base() external {}
}
