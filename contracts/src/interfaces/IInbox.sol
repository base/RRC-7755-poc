// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IInbox {
    function storeReceipt(bytes32 messageId, address fulfiller) external;
}
