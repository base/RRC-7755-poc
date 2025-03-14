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

    struct Message {
        address outbox;
        uint256 destinationChainId;
        uint256 duration;
        uint256 nonce;
        bool isOPStack;
    }

    struct MessageProcessor {
        HelperConfig.NetworkConfig dstConfig;
        MagicSpendRequest magicSpendRequest;
        GasLimit g;
        uint256 srcChainId;
        uint256 entryPointNonce;
    }

    struct GasLimit {
        uint128 verificationGasLimit;
        uint128 callGasLimit;
        uint128 maxPriorityFeePerGas;
        uint128 maxFeePerGas;
    }

    struct MagicSpendRequest {
        address token;
        uint256 amount;
    }

    address private constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    bytes4 internal constant _SOURCE_CHAIN_ATTRIBUTE_SELECTOR = 0x10b2cb84;

    function _initMessage(Message memory m) internal virtual returns (bytes32, bytes32, bytes memory, bytes[] memory) {
        MessageProcessor memory mp;

        (bytes32 destinationChain,,, bytes[] memory attributes) =
            super._initMessage(m.destinationChainId, m.duration, m.nonce, m.isOPStack);
        mp.dstConfig = helperConfig.getConfig(m.destinationChainId);

        mp.magicSpendRequest =
            MagicSpendRequest({token: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, amount: 0.0001 ether});

        mp.g = GasLimit({
            verificationGasLimit: 100000,
            callGasLimit: 100000,
            maxPriorityFeePerGas: 100000,
            maxFeePerGas: 100000
        });
        mp.srcChainId = block.chainid;

        vm.createSelectFork(mp.dstConfig.rpcUrl);
        mp.entryPointNonce = EntryPoint(payable(ENTRY_POINT)).getNonce(mp.dstConfig.smartAccount, 0);

        bytes[] memory newAttributes = _addInboxAndMagicSpendAttribute(
            attributes, mp.dstConfig.inbox, mp.srcChainId, m.outbox, mp.magicSpendRequest
        );

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: mp.dstConfig.smartAccount,
            nonce: mp.entryPointNonce,
            initCode: "",
            callData: abi.encodeWithSelector(
                MockAccount.executeUserOp.selector, address(mp.dstConfig.paymaster), mp.magicSpendRequest.token
            ),
            accountGasLimits: bytes32(abi.encodePacked(mp.g.verificationGasLimit, mp.g.callGasLimit)),
            preVerificationGas: 100000,
            gasFees: bytes32(abi.encodePacked(mp.g.maxPriorityFeePerGas, mp.g.maxFeePerGas)),
            paymasterAndData: _encodePaymasterAndData(mp.dstConfig.paymaster, newAttributes),
            signature: ""
        });

        return (destinationChain, ENTRY_POINT.addressToBytes32(), abi.encode(userOp), new bytes[](0));
    }

    function _encodePaymasterAndData(address paymaster, bytes[] memory attributes)
        private
        pure
        returns (bytes memory)
    {
        uint128 paymasterVerificationGasLimit = 100000;
        uint128 paymasterPostOpGasLimit = 100000;
        return
            abi.encodePacked(paymaster, paymasterVerificationGasLimit, paymasterPostOpGasLimit, abi.encode(attributes));
    }

    function _addInboxAndMagicSpendAttribute(
        bytes[] memory attributes,
        address inbox,
        uint256 srcChainId,
        address outbox,
        MagicSpendRequest memory req
    ) private pure returns (bytes[] memory) {
        bytes[] memory newAttributes = new bytes[](attributes.length + 3);
        for (uint256 i = 0; i < attributes.length; i++) {
            newAttributes[i] = attributes[i];
        }
        newAttributes[attributes.length] = abi.encodeWithSelector(_INBOX_ATTRIBUTE_SELECTOR, inbox);
        newAttributes[attributes.length + 1] =
            abi.encodeWithSelector(_MAGIC_SPEND_REQUEST_SELECTOR, req.token, req.amount);
        newAttributes[attributes.length + 2] =
            abi.encodeWithSelector(_SOURCE_CHAIN_ATTRIBUTE_SELECTOR, srcChainId, outbox);

        return newAttributes;
    }

    // Including to block from coverage report
    function test_userOp_base() external {}
}
