// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";

import {UserOpBase} from "./UserOpBase.s.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract UserOpHashiBase is UserOpBase {
    bytes4 private constant _SHOYU_BASHI_ATTRIBUTE_SELECTOR = 0xda07e15d; // shoyuBashi(bytes32)
    address private constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    function _initMessage(
        uint256 destinationChainId,
        uint256 duration,
        uint256 nonce,
        address shoyuBashi,
        bool isOPStack
    ) internal returns (bytes32, bytes32, bytes memory, bytes[] memory) {
        (bytes32 destinationChain, bytes32 receiver, bytes memory payload, bytes[] memory baseAttributes) =
            _initMessage(destinationChainId, duration, nonce, isOPStack);

        PackedUserOperation memory userOp = _updateUserOpAttributes(payload, shoyuBashi);

        return (destinationChain, receiver, abi.encode(userOp), baseAttributes);
    }

    function _updateUserOpAttributes(bytes memory payload, address shoyuBashi)
        private
        pure
        returns (PackedUserOperation memory)
    {
        PackedUserOperation memory userOp = abi.decode(payload, (PackedUserOperation));
        (bytes[] memory attributes) = abi.decode(_slice(userOp.paymasterAndData, 52), (bytes[]));

        bytes[] memory newAttributes = _convertAttributes(attributes, shoyuBashi);

        userOp.paymasterAndData = _encodePaymasterAndData(_slice(userOp.paymasterAndData, 0, 52), newAttributes);
        return userOp;
    }

    function _convertAttributes(bytes[] memory attributes, address shoyuBashi)
        private
        pure
        returns (bytes[] memory)
    {
        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == _L2_ORACLE_ATTRIBUTE_SELECTOR) {
                attributes[i] = abi.encodeWithSelector(_SHOYU_BASHI_ATTRIBUTE_SELECTOR, shoyuBashi);
            }
        }

        return attributes;
    }

    function _encodePaymasterAndData(bytes memory prefix, bytes[] memory attributes)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(prefix, abi.encode(attributes));
    }

    // Including to block from coverage report
    function test_userOpHashi_base() external {}

    function _slice(bytes memory data, uint256 start, uint256 end) private pure returns (bytes memory) {
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = data[i];
        }
        return result;
    }

    function _slice(bytes memory data, uint256 start) private pure returns (bytes memory) {
        uint256 end = data.length;
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = data[i];
        }
        return result;
    }
}
