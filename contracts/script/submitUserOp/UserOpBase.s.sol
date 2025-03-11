// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";
import {RRC7755Outbox} from "../../src/RRC7755Outbox.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {StandardBase} from "../requests/StandardBase.s.sol";

import {MockAccount} from "../../test/mocks/MockAccount.sol";

contract UserOpBase is StandardBase {
    using GlobalTypes for address;

    struct MagicSpendRequest {
        address token;
        uint256 amount;
    }

    address private constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    function _initMessage(uint256 destinationChainId, uint256 duration, uint256 nonce)
        internal
        virtual
        override
        returns (bytes32, bytes32, bytes memory, bytes[] memory)
    {
        (bytes32 destinationChain,,, bytes[] memory attributes) =
            super._initMessage(destinationChainId, duration, nonce);
        HelperConfig.NetworkConfig memory dstConfig = helperConfig.getConfig(destinationChainId);

        MagicSpendRequest memory magicSpendRequest = MagicSpendRequest({
            token: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            amount: 0.0001 ether
        });

        uint128 verificationGasLimit = 100000;
        uint128 callGasLimit = 100000;
        uint128 maxPriorityFeePerGas = 100000;
        uint128 maxFeePerGas = 100000;

        vm.createSelectFork(dstConfig.rpcUrl);
        uint256 entryPointNonce = EntryPoint(payable(ENTRY_POINT)).getNonce(dstConfig.smartAccount, 0);

        bytes32 receiver = ENTRY_POINT.addressToBytes32();
        bytes[] memory newAttributes = _addInboxAndMagicSpendAttribute(attributes, dstConfig.inbox, magicSpendRequest);

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: dstConfig.smartAccount,
            nonce: entryPointNonce,
            initCode: "",
            callData: abi.encodeWithSelector(MockAccount.executeUserOp.selector, address(dstConfig.paymaster), magicSpendRequest.token),
            accountGasLimits: bytes32(abi.encodePacked(verificationGasLimit, callGasLimit)),
            preVerificationGas: 100000,
            gasFees: bytes32(abi.encodePacked(maxPriorityFeePerGas, maxFeePerGas)),
            paymasterAndData: _encodePaymasterAndData(dstConfig.paymaster, newAttributes),
            signature: ""
        });

        return (destinationChain, receiver, abi.encode(userOp), new bytes[](0));
    }

    function _encodePaymasterAndData(address paymaster, bytes[] memory attributes)
        private
        pure
        returns (bytes memory)
    {
        uint128 paymasterVerificationGasLimit = 100000;
        uint128 paymasterPostOpGasLimit = 100000;
        return abi.encodePacked(
            paymaster,
            paymasterVerificationGasLimit,
            paymasterPostOpGasLimit,
            abi.encode(attributes)
        );
    }

    function _addInboxAndMagicSpendAttribute(bytes[] memory attributes, address inbox, MagicSpendRequest memory req) private pure returns (bytes[] memory) {
        bytes[] memory newAttributes = new bytes[](attributes.length + 2);
        for (uint256 i = 0; i < attributes.length; i++) {
            newAttributes[i] = attributes[i];
        }
        newAttributes[attributes.length] = abi.encodeWithSelector(_INBOX_ATTRIBUTE_SELECTOR, inbox);
        newAttributes[attributes.length + 1] = abi.encodeWithSelector(_MAGIC_SPEND_REQUEST_SELECTOR, req.token, req.amount);
        return newAttributes;
    }

    // Including to block from coverage report
    function test_userOp_base() external {}
}
