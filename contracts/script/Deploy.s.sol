// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {MultiChain} from "./MultiChain.sol";
import {RRC7755OutboxToArbitrum} from "../src/outboxes/RRC7755OutboxToArbitrum.sol";
import {RRC7755OutboxToOPStack} from "../src/outboxes/RRC7755OutboxToOPStack.sol";
import {RRC7755OutboxToHashi} from "../src/outboxes/RRC7755OutboxToHashi.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {RRC7755Inbox} from "../src/RRC7755Inbox.sol";

contract Deploy is MultiChain {
    function run() external {
        string memory out = "{";

        for (uint256 i; i < chains.length; i++) {
            vm.createSelectFork(chains[i].rpcUrl);

            out = string.concat(out, "\"", chains[i].chainName, "\": {");

            vm.startBroadcast();

            Paymaster paymaster = new Paymaster(ENTRY_POINT);
            out = _record(out, address(paymaster), "Paymaster");

            RRC7755Inbox inbox = new RRC7755Inbox(address(paymaster));
            out = _record(out, address(inbox), "RRC7755Inbox");

            paymaster.initialize(address(inbox));

            if (block.chainid != 421614) {
                out = _record(out, address(new RRC7755OutboxToArbitrum()), "RRC7755OutboxToArbitrum");
            }
            out = _record(out, address(new RRC7755OutboxToOPStack()), "RRC7755OutboxToOPStack");
            out = _record(out, address(new RRC7755OutboxToHashi()), "RRC7755OutboxToHashi");

            vm.stopBroadcast();

            out = string.concat(out, "},");
        }

        out = string.concat(out, "}");

        vm.writeFile("addresses.json", out);
    }

    function _record(string memory out, address contractAddr, string memory key) private pure returns (string memory) {
        return string.concat(out, "\"", key, "\": \"", Strings.toHexString(contractAddr), "\",");
    }

    // Including to block from coverage report
    function test() external {}
}
