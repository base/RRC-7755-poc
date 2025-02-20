// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {BlockHeaders} from "../src/libraries/BlockHeaders.sol";
import {MockBlockHeaders} from "./mocks/MockBlockHeaders.sol";
import {BaseTest} from "./BaseTest.t.sol";

contract BlockHeadersTest is BaseTest {
    MockBlockHeaders blockHeaders;

    bytes constant HEADERS =
        hex"f90224a035c9f378e2ebe594d151c19def4502e6d376e0b549287681a9647127f37f9ac9a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794a4b000000000000000000073657175656e636572a0aebca17956e6adc9e2166f963e9f042fe712bd8cab4cf89a793c796336d0af5fa0806927c2dc94b0755f3caf54994a4e5377229abc876c685b03ba3ab2bd58bf9ea0daccbbfa4a42c6cb97be8b96af4e40be4f2ab7bed3be60ed4942580ca4ff1ebdb901001800000000800010000000000000200440010800000000800000010020120000001008000000020000000000000200040000000040000080000020000000000100001000000000000800040800000000000000000000000080004000084001000008000100010200000000400030000000800000000000000000001002000010010000000000800060000000100000000000020200000000000000020220000000000020000280040000000000000000000008000000000000000000000000000000000200000040011010000002080000000000000404000200020000001000000000008044000000020000000000000000080000000000000100080000c0000184067fac8c8704000000000000830882df846765d7eaa0d63456a0b43da010028730599fbc11921229a389a166ae6be20b71ed36e2c03aa0000000000000d9ef00000000006fb312000000000000002000000000000000008800000000001190478405f5e100";
    bytes constant INVALID_HEADERS = hex"e1a0df6e85afcdb9d4af3a682a4caf4b95dd4acdc3de3e2ef743f6157ac7b9a661cb";
    bytes constant INVALID_HEADERS_2 =
        hex"f90241a0422c100e6b380989f1571b70f04e1414cf7028d1c190203788103a52f3af4e28a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794a4b000000000000000000073657175656e636572a0296daa75d732540d610bf7aefab460bb4d8d96efc273adb8751fe203c3e84ee3a03ce8d10a008d58d1f91ea328797a521a2336f49b08a7b3159524c7b9c5fd56d9a0e643e69e6f4055ade783f69418e91932d7e8c8887a7fc887e6f6f0aefb1e85cfb9010011000000002040020104002008000001144000002064806412000040820000004200110000000a00010901200200000000100200000000000080808000a100a00008000000800010000000080010000a000244480800000020010000000000000010001002000020801a000001800808002001422410040000000850000b010880020440000000000070000000800088801000480020090200008804020000204202468000000042804000802000400001000c000008000000008000032600060054c052804001502009156800001080000000804000010000000000000060020011100200000a00004002001000081000810228090000003004020000400000018406c3473b87040000000000008329c636a1000000000000000000000000000000000000000000000000000000000000000000a0fd178b1d44bb2abed16ab8dfc29065631adbbc13b31cc9df7497cbbca79f8024a0000000000000e5e70000000000718b810000000000000020000000000000000088000000000012d4aa841607f420";

    function setUp() public {
        blockHeaders = new MockBlockHeaders();
    }

    function test_toBlockHash() public view {
        bytes32 blockHash = blockHeaders.toBlockHash(HEADERS);
        assertEq(blockHash, keccak256(HEADERS));
    }

    function test_extractStateRootBlockNumberAndTimestamp() public view {
        (bytes32 stateRoot, uint256 blockNumber, uint256 timestamp) =
            blockHeaders.extractStateRootBlockNumberAndTimestamp(HEADERS);

        assertEq(stateRoot, 0xaebca17956e6adc9e2166f963e9f042fe712bd8cab4cf89a793c796336d0af5f);
        assertEq(blockNumber, uint256(109030540));
        assertEq(timestamp, uint256(1734727658));
    }

    function test_extractStateRootBlockNumberAndTimestamp_reverts_ifInvalidBlockFieldRLP() public {
        vm.expectRevert(BlockHeaders.InvalidBlockFieldRLP.selector);
        blockHeaders.extractStateRootBlockNumberAndTimestamp(INVALID_HEADERS);
    }

    function test_extractStateRootBlockNumberAndTimestamp_reverts_ifInvalidBlockFieldRLP_2() public {
        vm.expectRevert(BlockHeaders.BytesLengthExceeds32.selector);
        blockHeaders.extractStateRootBlockNumberAndTimestamp(INVALID_HEADERS_2);
    }

    function test_extractStateRoot_reverts_ifInvalidBlockFieldRLP() public {
        vm.expectRevert(BlockHeaders.InvalidBlockFieldRLP.selector);
        blockHeaders.extractStateRoot(INVALID_HEADERS);
    }

    function test_extractStateRoot() public view {
        bytes32 stateRoot = blockHeaders.extractStateRoot(HEADERS);

        assertEq(stateRoot, 0xaebca17956e6adc9e2166f963e9f042fe712bd8cab4cf89a793c796336d0af5f);
    }
}
