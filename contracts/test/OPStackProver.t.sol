// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {stdJson} from "forge-std/StdJson.sol";

import {OPStackProver} from "../src/libraries/provers/OPStackProver.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {RRC7755OutboxToOPStack} from "../src/outboxes/RRC7755OutboxToOPStack.sol";
import {RRC7755Outbox} from "../src/RRC7755Outbox.sol";

import {MockOPStackProver} from "./mocks/MockOPStackProver.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract OPStackProverTest is BaseTest {
    using stdJson for string;
    using GlobalTypes for address;

    struct Message {
        bytes32 sourceChain;
        bytes32 destinationChain;
        bytes32 sender;
        bytes32 receiver;
        bytes payload;
        bytes[] attributes;
    }

    MockOPStackProver prover;

    address private constant _INBOX_CONTRACT = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    bytes4 internal constant _L2_ORACLE_STORAGE_KEY_ATTRIBUTE_SELECTOR = 0x0f786369;
    bytes32 constant VERIFIER_STORAGE_LOCATION = 0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00;

    function setUp() external {
        prover = new MockOPStackProver();
        approveAddr = address(prover);
        _setUp();

        string memory path = string.concat(rootPath, "/test/data/OPSepoliaProof.json");
        string memory invalidL1StoragePath = string.concat(rootPath, "/test/data/invalids/OPInvalidL1Storage.json");
        string memory invalidL2StateRootPath = string.concat(rootPath, "/test/data/invalids/OPInvalidL2StateRoot.json");
        string memory invalidL2StoragePath = string.concat(rootPath, "/test/data/invalids/OPInvalidL2Storage.json");
        validProof = vm.readFile(path);
        invalidL1State = vm.readFile(invalidL1StoragePath);
        invalidL2StateRootProof = vm.readFile(invalidL2StateRootPath);
        invalidL2Storage = vm.readFile(invalidL2StoragePath);
    }

    function test_minExpiryTime(uint256 finalityDelay) external view {
        assertEq(prover.minExpiryTime(finalityDelay), 14 days);
    }

    function test_validate_reverts_ifBeaconRootCallFails() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        OPStackProver.RRC7755Proof memory proofData = _buildProof(validProof);
        proofData.stateProofParams.beaconOracleTimestamp++;
        bytes memory storageProofData = abi.encode(proofData);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert();
        prover.validateProof(
            m.destinationChain, inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, storageProofData
        );
    }

    function test_validate_reverts_ifInvalidBeaconRoot() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        OPStackProver.RRC7755Proof memory proofData = _buildProof(validProof);
        proofData.stateProofParams.beaconRoot = keccak256("invalidRoot");
        bytes memory storageProofData = abi.encode(proofData);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert();
        prover.validateProof(
            m.destinationChain, inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, storageProofData
        );
    }

    function test_validate_reverts_ifInvalidL1StateRoot() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        OPStackProver.RRC7755Proof memory proofData = _buildProof(validProof);
        proofData.stateProofParams.executionStateRoot = keccak256("invalidRoot");
        bytes memory storageProofData = abi.encode(proofData);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert();
        prover.validateProof(
            m.destinationChain, inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, storageProofData
        );
    }

    function test_validate_reverts_ifInvalidL1Storage() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes memory storageProofData = _buildProofAndEncodeProof(invalidL1State);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(OPStackProver.InvalidL1Storage.selector);
        prover.validateProof(
            m.destinationChain, inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, storageProofData
        );
    }

    function test_validate_reverts_ifInvalidL2StateRoot() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes memory storageProofData = _buildProofAndEncodeProof(invalidL2StateRootProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(OPStackProver.InvalidL2StateRoot.selector);
        prover.validateProof(
            m.destinationChain, inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, storageProofData
        );
    }

    function test_validate_reverts_ifInvalidL2Storage() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes memory storageProofData = _buildProofAndEncodeProof(invalidL2Storage);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(OPStackProver.InvalidL2Storage.selector);
        prover.validateProof(
            m.destinationChain, inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, storageProofData
        );
    }

    function test_validate_reverts_ifInvalidCaller() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes memory storageProofData = _buildProofAndEncodeProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, address(this), FILLER));
        prover.validateProof(
            m.destinationChain, inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, storageProofData
        );
    }

    function test_validate_proveOptimismSepoliaStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes memory storageProofData = _buildProofAndEncodeProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        prover.validateProof(
            m.destinationChain, inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, storageProofData
        );
    }

    function _buildProofAndEncodeProof(string memory json) private returns (bytes memory) {
        OPStackProver.RRC7755Proof memory proofData = _buildProof(json);
        return abi.encode(proofData);
    }

    function _buildProof(string memory json) private returns (OPStackProver.RRC7755Proof memory) {
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

        return OPStackProver.RRC7755Proof({
            l2MessagePasserStorageRoot: json.readBytes32(".l2MessagePasserStorageRoot"),
            encodedBlockArray: json.readBytes(".encodedBlockArray"),
            stateProofParams: stateProofParams,
            dstL2StateRootProofParams: dstL2StateRootParams,
            dstL2AccountProofParams: dstL2AccountProofParams
        });
    }

    function _initMessage(uint256 rewardAmount) private pure returns (Message memory) {
        Message memory m;
        m.sourceChain = bytes32(uint256(31337));
        m.destinationChain = bytes32(uint256(31337));
        m.sender = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496.addressToBytes32();
        m.receiver = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496.addressToBytes32();
        m.attributes = new bytes[](6);

        m.attributes[0] = abi.encodeWithSelector(
            _REWARD_ATTRIBUTE_SELECTOR, 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, rewardAmount
        );
        m.attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1828828574);
        m.attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        m.attributes[3] = abi.encodeWithSelector(
            _REQUESTER_ATTRIBUTE_SELECTOR, 0x000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6
        );
        m.attributes[4] =
            abi.encodeWithSelector(_L2_ORACLE_ATTRIBUTE_SELECTOR, 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
        m.attributes[5] = abi.encodeWithSelector(
            _L2_ORACLE_STORAGE_KEY_ATTRIBUTE_SELECTOR,
            0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49
        );

        return m;
    }

    function _deriveStorageKey(bytes32 messageId) internal pure override returns (bytes memory) {
        return abi.encode(keccak256(abi.encodePacked(messageId, VERIFIER_STORAGE_LOCATION)));
    }
}
