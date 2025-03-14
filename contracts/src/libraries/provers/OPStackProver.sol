// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StateValidator} from "../StateValidator.sol";
import {BlockHeaders} from "../BlockHeaders.sol";

/// @title OPStackProver
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice This is a utility library for validating OP Stack storage proofs.
library OPStackProver {
    using StateValidator for address;
    using BlockHeaders for bytes;

    /// @notice The address and storage keys to validate on L1 and L2
    struct Target {
        /// @dev The address of the L1 contract to validate. Should be Optimism's AnchorStateRegistry contract
        address l1Address;
        /// @dev The storage key on L1 to validate.
        bytes l1StorageKey;
        /// @dev The address of the L2 contract to validate.
        address l2Address;
        /// @dev The storage key on L2 to validate.
        bytes l2StorageKey;
    }

    /// @notice Parameters needed for a full nested cross-L2 storage proof
    struct RRC7755Proof {
        /// @dev The storage root of Optimism's MessagePasser contract - used to compute our L1 storage value
        bytes32 l2MessagePasserStorageRoot;
        /// @dev The RLP-encoded array of block headers of the chain's L2 block used for the proof. Hashing this bytes
        ///      string should produce the blockhash.
        bytes encodedBlockArray;
        /// @dev Parameters needed to validate the authenticity of Ethereum's execution client's state root
        StateValidator.StateProofParameters stateProofParams;
        /// @dev Parameters needed to validate the authenticity of the l2Oracle for the destination L2 chain on Eth
        /// mainnet
        StateValidator.AccountProofParameters dstL2StateRootProofParams;
        /// @dev Parameters needed to validate the authenticity of a specified storage location on the destination L2
        ///      chain
        StateValidator.AccountProofParameters dstL2AccountProofParams;
    }

    /// @notice This error is thrown when verification of the authenticity of the l2Oracle for the destination L2 chain
    ///         on Eth mainnet fails
    error InvalidL1Storage();

    /// @notice This error is thrown when verification of the authenticity of the destination L2 storage slot fails
    error InvalidL2Storage();

    /// @notice This error is thrown when the supplied l2StateRoot does not correspond to our validated L1 state
    error InvalidL2StateRoot();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If the L2StateRoot does not correspond to the validated L1 storage slot
    ///
    /// @dev Implementation will vary by L2
    ///
    /// @param proof  The proof to validate
    /// @param target The proof target on L1 and dst L2
    function validate(bytes calldata proof, Target memory target) internal view returns (bytes memory) {
        RRC7755Proof memory data = abi.decode(proof, (RRC7755Proof));

        // Set the expected storage key for the L1 storage slot
        data.dstL2StateRootProofParams.storageKey = target.l1StorageKey;
        // Set the expected storage key for the destination L2 storage slot
        data.dstL2AccountProofParams.storageKey = target.l2StorageKey;

        // We first need to validate knowledge of the destination L2 chain's state root.
        // StateValidator.validateState will accomplish each of the following 4 steps:
        //      1. Confirm beacon root
        //      2. Validate L1 state root
        //      3. Validate L1 account proof where `account` here is the destination chain's AnchorStateRegistry
        //         contract
        //      4. Validate storage proof proving destination L2 root stored in L1 AnchorStateRegistry contract
        if (!target.l1Address.validateState(data.stateProofParams, data.dstL2StateRootProofParams)) {
            revert InvalidL1Storage();
        }

        // As an intermediate step, we need to prove that `data.dstL2StateRootProofParams.storageValue` is linked
        // to the correct l2StateRoot before we can prove l2Storage

        bytes32 version;
        // Extract the L2 stateRoot and timestamp from the RLP-encoded block array
        bytes32 l2StateRoot = data.encodedBlockArray.extractStateRoot();
        // Derive the L2 blockhash
        bytes32 l2BlockHash = data.encodedBlockArray.toBlockHash();

        // Compute the expected destination chain output root (which is the value we just proved is in the L1 storage
        // slot)
        bytes32 expectedOutputRoot =
            keccak256(abi.encodePacked(version, l2StateRoot, data.l2MessagePasserStorageRoot, l2BlockHash));
        // If this checks out, it means we know the correct l2StateRoot
        if (bytes32(data.dstL2StateRootProofParams.storageValue) != expectedOutputRoot) {
            revert InvalidL2StateRoot();
        }

        // Because the previous step confirmed L1 state, we do not need to repeat steps 1 and 2 again
        // We now just need to validate account storage on the destination L2 using
        // StateValidator.validateAccountStorage
        // This library function will accomplish the following 2 steps:
        //      5. Validate L2 account proof where `account` here is the destination L2 contract
        //      6. Validate storage proof proving the destination L2 storage slot
        if (!target.l2Address.validateAccountStorage(l2StateRoot, data.dstL2AccountProofParams)) {
            revert InvalidL2Storage();
        }

        return data.dstL2AccountProofParams.storageValue;
    }
}
