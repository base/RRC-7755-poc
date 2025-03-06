// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/core/EntryPoint.sol";

import {GlobalTypes} from "../../src/libraries/GlobalTypes.sol";

contract MockAccount {
    using GlobalTypes for bytes32;

    struct Call {
        bytes32 to;
        bytes data;
        uint256 value;
    }

    receive() external payable {}

    function validateUserOp(PackedUserOperation calldata, bytes32, uint256)
        external
        pure
        returns (uint256 validationData)
    {
        return 0;
    }

    function executeUserOp(address paymaster, bytes32 token) external {
        bytes4 selector = bytes4(keccak256("withdrawGasExcess(bytes32)"));
        (bool success,) = paymaster.call(abi.encodeWithSelector(selector, token));
        require(success, "Failed to call withdrawGasExcess");
    }

    function executeUserOpWithCalls(address paymaster, bytes32 token, Call[] calldata calls) external {
        bytes4 selector = bytes4(keccak256("withdrawGasExcess(bytes32)"));
        (bool success,) = paymaster.call(abi.encodeWithSelector(selector, token));
        require(success, "Failed to call withdrawGasExcess");

        for (uint256 i; i < calls.length; i++) {
            address to = calls[i].to.bytes32ToAddress();
            _call(to, calls[i].data, calls[i].value);
        }
    }

    // Including to block from coverage report
    function test() external {}

    function _call(address to, bytes memory data, uint256 value) private {
        (bool success, bytes memory result) = to.call{value: value}(data);
        if (!success) {
            assembly ("memory-safe") {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
