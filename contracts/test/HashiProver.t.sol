// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {stdJson} from "forge-std/StdJson.sol";

import {HashiProver} from "../src/libraries/provers/HashiProver.sol";
import {BlockHeaders} from "../src/libraries/BlockHeaders.sol";
import {GlobalTypes} from "../src/libraries/GlobalTypes.sol";
import {StateValidator} from "../src/libraries/StateValidator.sol";
import {RRC7755OutboxToHashi} from "../src/outboxes/RRC7755OutboxToHashi.sol";
import {RRC7755Outbox} from "../src/RRC7755Outbox.sol";

import {MockShoyuBashi} from "./mocks/MockShoyuBashi.sol";
import {MockHashiProver} from "./mocks/MockHashiProver.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract HashiProverTest is BaseTest {
    using stdJson for string;
    using GlobalTypes for address;
    using BlockHeaders for bytes;

    struct Message {
        bytes32 sourceChain;
        bytes32 destinationChain;
        bytes32 sender;
        bytes32 receiver;
        bytes payload;
        bytes[] attributes;
    }

    uint256 public immutable HASHI_DOMAIN_DST_CHAIN_ID = 111112;
    address private constant _INBOX_CONTRACT = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    bytes32 constant VERIFIER_STORAGE_LOCATION = 0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00;

    MockHashiProver prover;
    MockShoyuBashi shoyuBashi;

    function setUp() external {
        shoyuBashi = new MockShoyuBashi();
        prover = new MockHashiProver();
        approveAddr = address(prover);
        _setUp();

        string memory path = string.concat(rootPath, "/test/data/HashiProverProof.json");
        validProof = vm.readFile(path);
    }

    function test_minExpiryTime(uint256 finalityDelay) external view {
        assertEq(prover.minExpiryTime(finalityDelay), finalityDelay);
    }

    function test_reverts_ifFinalityDelaySecondsStillInProgress() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes memory proof = _buildAndEncodeProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);
        m.attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, type(uint256).max - 1 ether, 1828828574);

        vm.prank(FILLER);
        vm.expectRevert(RRC7755OutboxToHashi.FinalityDelaySecondsInProgress.selector);
        prover.validateProof(
            bytes32(HASHI_DOMAIN_DST_CHAIN_ID), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, proof
        );
    }

    function test_reverts_ifInvalidBlockHeader() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);
        HashiProver.RRC7755Proof memory proof = _buildProof(validProof);

        (, uint256 blockNumber,) = proof.rlpEncodedBlockHeader.extractStateRootBlockNumberAndTimestamp();

        bytes32 wrongBlockHeaderHash = bytes32(uint256(0));
        shoyuBashi.setHash(HASHI_DOMAIN_DST_CHAIN_ID, blockNumber, wrongBlockHeaderHash);

        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidBlockHeader.selector);
        prover.validateProof(
            bytes32(0), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, abi.encode(proof)
        );
    }

    function test_reverts_ifInvalidStorage() external fundAlice(_REWARD_AMOUNT) {
        bytes memory wrongStorageValue = "0x23214a0864fc0014cab6030267738f01affdd547000000000000000067444860";
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        HashiProver.RRC7755Proof memory proof = _buildProof(validProof);
        proof.dstAccountProofParams.storageValue = wrongStorageValue;
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        vm.expectRevert(HashiProver.InvalidStorage.selector);
        prover.validateProof(
            bytes32(HASHI_DOMAIN_DST_CHAIN_ID),
            inboxStorageKey,
            _INBOX_CONTRACT.addressToBytes32(),
            m.attributes,
            abi.encode(proof)
        );
    }

    function test_reverts_ifInvalidCaller() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes memory proof = _buildAndEncodeProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.expectRevert(abi.encodeWithSelector(RRC7755Outbox.InvalidCaller.selector, address(this), FILLER));
        prover.validateProof(
            bytes32(HASHI_DOMAIN_DST_CHAIN_ID), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, proof
        );
    }

    function test_proveGnosisChiadoStateFromBaseSepolia() external fundAlice(_REWARD_AMOUNT) {
        Message memory m = _initMessage(_REWARD_AMOUNT);
        bytes32 messageId =
            prover.getMessageId(m.sourceChain, m.sender, m.destinationChain, m.receiver, m.payload, m.attributes);

        bytes memory proof = _buildAndEncodeProof(validProof);
        bytes memory inboxStorageKey = _deriveStorageKey(messageId);

        vm.prank(FILLER);
        prover.validateProof(
            bytes32(HASHI_DOMAIN_DST_CHAIN_ID), inboxStorageKey, _INBOX_CONTRACT.addressToBytes32(), m.attributes, proof
        );
    }

    function _buildAndEncodeProof(string memory json) private returns (bytes memory) {
        return abi.encode(_buildProof(json));
    }

    function _buildProof(string memory json) private returns (HashiProver.RRC7755Proof memory) {
        StateValidator.AccountProofParameters memory dstAccountProofParams = StateValidator.AccountProofParameters({
            storageKey: json.readBytes(".dstAccountProofParams.storageKey"),
            storageValue: json.readBytes(".dstAccountProofParams.storageValue"),
            accountProof: abi.decode(json.parseRaw(".dstAccountProofParams.accountProof"), (bytes[])),
            storageProof: abi.decode(json.parseRaw(".dstAccountProofParams.storageProof"), (bytes[]))
        });

        bytes memory rlpEncodedBlockHeader = json.readBytes(".rlpEncodedBlockHeader");
        (, uint256 blockNumber,) = rlpEncodedBlockHeader.extractStateRootBlockNumberAndTimestamp();

        shoyuBashi.setHash(HASHI_DOMAIN_DST_CHAIN_ID, blockNumber, rlpEncodedBlockHeader.toBlockHash());

        return HashiProver.RRC7755Proof({
            rlpEncodedBlockHeader: rlpEncodedBlockHeader,
            dstAccountProofParams: dstAccountProofParams
        });
    }

    function _initMessage(uint256 rewardAmount) private view returns (Message memory) {
        Message memory m;
        m.sourceChain = bytes32(uint256(31337));
        m.destinationChain = bytes32(HASHI_DOMAIN_DST_CHAIN_ID);
        m.sender = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496.addressToBytes32();
        m.receiver = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496.addressToBytes32();
        m.attributes = new bytes[](5);

        m.attributes[0] =
            abi.encodeWithSelector(_REWARD_ATTRIBUTE_SELECTOR, address(mockErc20).addressToBytes32(), rewardAmount);
        m.attributes[1] = abi.encodeWithSelector(_DELAY_ATTRIBUTE_SELECTOR, 10, 1828828574);
        m.attributes[2] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, 1);
        m.attributes[3] = abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, ALICE.addressToBytes32());
        m.attributes[4] =
            abi.encodeWithSelector(_SHOYU_BASHI_ATTRIBUTE_SELECTOR, address(shoyuBashi).addressToBytes32());

        return m;
    }

    function _deriveStorageKey(bytes32 messageId) internal pure override returns (bytes memory) {
        return abi.encode(keccak256(abi.encodePacked(messageId, VERIFIER_STORAGE_LOCATION)));
    }
}
