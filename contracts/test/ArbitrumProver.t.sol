// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {stdJson} from "forge-std/StdJson.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {ArbitrumProver} from "../src/libraries/provers/ArbitrumProver.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {RRC7755OutboxToArbitrum} from "../src/outboxes/RRC7755OutboxToArbitrum.sol";
import {RRC7755Outbox} from "../src/RRC7755Outbox.sol";

import {MockArbitrumProver} from "./mocks/MockArbitrumProver.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract ArbitrumProverTest is BaseTest {
    using stdJson for string;
    using GlobalTypes for address;
    using Strings for address;

    MockArbitrumProver prover;
    string unconfirmedState;

    address private constant _INBOX_CONTRACT = 0xdac62f96404AB882F5a61CFCaFb0C470a19FC514;

    function setUp() external {
        prover = new MockArbitrumProver();
        approveAddr = address(prover);
        _setUp();

        string memory path = string.concat(rootPath, "/test/data/ArbitrumSepoliaProof.json");
        string memory invalidPath = string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidL1State.json");
        string memory invalidBlockHeadersPath =
            string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidBlockHeaders.json");
        string memory invalidL2StoragePath =
            string.concat(rootPath, "/test/data/invalids/ArbitrumInvalidL2Storage.json");
        string memory unconfirmedStatePath = string.concat(rootPath, "/test/data/invalids/ArbitrumUnconfirmed.json");

        validProof = vm.readFile(path);
        invalidL1State = vm.readFile(invalidPath);
        invalidBlockHeaders = vm.readFile(invalidBlockHeadersPath);
        invalidL2Storage = vm.readFile(invalidL2StoragePath);
        unconfirmedState = vm.readFile(unconfirmedStatePath);
    }

    function test_minExpiryTime(uint256 finalityDelay) external view {
        assertEq(prover.minExpiryTime(finalityDelay), 8 days);
    }

    function test_reverts_ifInvalidL1State() external fundAlice(_REWARD_AMOUNT) {
        (string memory sourceChain, string memory sender, Call[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = _getMessageId(sourceChain, sender, calls, attributes);

        ArbitrumProver.RRC7755Proof memory proof = _buildProof(invalidL1State);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidStateRoot.selector);
        prover.validateProof(
            bytes32(0), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), attributes, abi.encode(proof)
        );
    }

    function test_reverts_ifUnconfirmed() external fundAlice(_REWARD_AMOUNT) {
        (string memory sourceChain, string memory sender, Call[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = _getMessageId(sourceChain, sender, calls, attributes);

        ArbitrumProver.RRC7755Proof memory proof = _buildProof(unconfirmedState);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.NodeNotConfirmed.selector);
        prover.validateProof(
            bytes32(0), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), attributes, abi.encode(proof)
        );
    }

    function test_reverts_ifInvalidRLPHeaders() external fundAlice(_REWARD_AMOUNT) {
        (string memory sourceChain, string memory sender, Call[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = _getMessageId(sourceChain, sender, calls, attributes);

        ArbitrumProver.RRC7755Proof memory proof = _buildProof(invalidBlockHeaders);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidBlockHeaders.selector);
        prover.validateProof(
            bytes32(0), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), attributes, abi.encode(proof)
        );
    }

    function test_reverts_ifInvalidL2Storage() external fundAlice(_REWARD_AMOUNT) {
        (string memory sourceChain, string memory sender, Call[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = _getMessageId(sourceChain, sender, calls, attributes);

        ArbitrumProver.RRC7755Proof memory proof = _buildProof(invalidL2Storage);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(ArbitrumProver.InvalidL2Storage.selector);
        prover.validateProof(
            bytes32(0), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), attributes, abi.encode(proof)
        );
    }

    function test_reverts_ifInvalidCaller() external fundAlice(_REWARD_AMOUNT) {
        (string memory sourceChain, string memory sender, Call[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = _getMessageId(sourceChain, sender, calls, attributes);

        ArbitrumProver.RRC7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, address(this), FILLER));
        prover.validateProof(
            bytes32(0), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), attributes, abi.encode(proof)
        );
    }

    function test_proveArbitrumSepoliaStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        (string memory sourceChain, string memory sender, Call[] memory calls, bytes[] memory attributes) =
            _initMessage(_REWARD_AMOUNT);
        bytes32 messageId = _getMessageId(sourceChain, sender, calls, attributes);

        ArbitrumProver.RRC7755Proof memory proof = _buildProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        prover.validateProof(
            bytes32(0), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), attributes, abi.encode(proof)
        );
    }

    function _buildProof(string memory json) private returns (ArbitrumProver.RRC7755Proof memory) {
        ArbitrumProver.GlobalState memory afterStateGlobalState = ArbitrumProver.GlobalState({
            bytes32Vals: abi.decode(json.parseRaw(".afterState.globalState.bytes32Vals"), (bytes32[2])),
            u64Vals: abi.decode(json.parseRaw(".afterState.globalState.u64Vals"), (uint64[2]))
        });
        afterStateGlobalState.bytes32Vals[0] = json.readBytes32(".afterState.globalState.bytes32Vals[0]");
        afterStateGlobalState.bytes32Vals[1] = json.readBytes32(".afterState.globalState.bytes32Vals[1]");
        afterStateGlobalState.u64Vals[0] = uint64(json.readUint(".afterState.globalState.u64Vals[0]"));
        afterStateGlobalState.u64Vals[1] = uint64(json.readUint(".afterState.globalState.u64Vals[1]"));

        ArbitrumProver.AssertionState memory afterState = ArbitrumProver.AssertionState({
            globalState: afterStateGlobalState,
            machineStatus: ArbitrumProver.MachineStatus(json.readUint(".afterState.machineStatus")),
            endHistoryRoot: json.readBytes32(".afterState.endHistoryRoot")
        });

        StateValidator.StateProofParameters memory stateProofParams = StateValidator.StateProofParameters({
            beaconRoot: json.readBytes32(".stateProofParams.beaconRoot"),
            beaconOracleTimestamp: json.readUint(".stateProofParams.beaconOracleTimestamp"),
            executionStateRoot: json.readBytes32(".stateProofParams.executionStateRoot"),
            stateRootProof: abi.decode(json.parseRaw(".stateProofParams.stateRootProof"), (bytes32[]))
        });
        StateValidator.AccountProofParameters memory dstL2StateRootParams = StateValidator.AccountProofParameters({
            storageKey: json.readBytes(".dstL2StateRootProofParams.storageKey"),
            storageValue: json.readBytes(".dstL2StateRootProofParams.storageValue"),
            accountProof: abi.decode(json.parseRaw(".dstL2StateRootProofParams.accountProof"), (bytes[])),
            storageProof: abi.decode(json.parseRaw(".dstL2StateRootProofParams.storageProof"), (bytes[]))
        });
        StateValidator.AccountProofParameters memory dstL2AccountProofParams = StateValidator.AccountProofParameters({
            storageKey: json.readBytes(".dstL2AccountProofParams.storageKey"),
            storageValue: json.readBytes(".dstL2AccountProofParams.storageValue"),
            accountProof: abi.decode(json.parseRaw(".dstL2AccountProofParams.accountProof"), (bytes[])),
            storageProof: abi.decode(json.parseRaw(".dstL2AccountProofParams.storageProof"), (bytes[]))
        });

        mockBeaconOracle.commitBeaconRoot(1, stateProofParams.beaconOracleTimestamp, stateProofParams.beaconRoot);

        return ArbitrumProver.RRC7755Proof({
            encodedBlockArray: json.readBytes(".encodedBlockArray"),
            afterState: afterState,
            prevAssertionHash: json.readBytes32(".prevAssertionHash"),
            sequencerBatchAcc: json.readBytes32(".sequencerBatchAcc"),
            stateProofParams: stateProofParams,
            dstL2StateRootProofParams: dstL2StateRootParams,
            dstL2AccountProofParams: dstL2AccountProofParams
        });
    }

    function _initMessage(uint256 rewardAmount)
        private
        view
        returns (string memory, string memory, Call[] memory, bytes[] memory)
    {
        string memory sourceChain = _remote(31337);
        string memory sender = address(this).toChecksumHexString();
        Call[] memory calls = new Call[](0);
        bytes[] memory attributes = new bytes[](5);

        attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1828828574);
        attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        attributes[4] =
            abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, 0x042B2E6C5E99d4c521bd49beeD5E99651D9B0Cf4); // Arbitrum Rollup on Sepolia

        return (sourceChain, sender, calls, attributes);
    }
}
