// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title RRC7755Base
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice This contract contains helper functions and shared message attributes for RRC-7755 used by both Inbox and
///         Outbox contracts. The attributes are inspired by ERC-7786.
abstract contract RRC7755Base {
    /// @notice Low-level call specs representing the desired transaction on destination chain
    struct Call {
        /// @dev The address to call
        bytes32 to;
        /// @dev The calldata to call with
        bytes data;
        /// @dev The native asset value of the call
        uint256 value;
    }

    /// @notice This struct is used to process attributes while avoiding stack too deep errors
    struct ProcessAttributesState {
        /// @dev The selectors that are required for the request
        bytes4[] requiredSelectors;
        /// @dev Whether each required selector has been processed
        bool[] processedRequired;
        /// @dev The selectors that are optional for the request
        bytes4[] optionalSelectors;
        /// @dev Whether each optional selector has been processed
        bool[] processedOptional;
    }

    /// @notice The selector for the precheck attribute
    bytes4 internal constant _PRECHECK_ATTRIBUTE_SELECTOR = 0xbef86027; // precheck(bytes32)

    /// @notice The selector for requesting magic spend funds for call execution
    bytes4 internal constant _MAGIC_SPEND_REQUEST_SELECTOR = 0x92041278; // magicSpendRequest(address,uint256)

    /// @notice The selector for the inbox attribute
    bytes4 internal constant _INBOX_ATTRIBUTE_SELECTOR = 0xbd362374; // inbox(bytes32)

    /// @notice This error is thrown if an attribute is not found in the attributes array
    ///
    /// @param selector The selector of the attribute that was not found
    error AttributeNotFound(bytes4 selector);

    /// @notice This error is thrown when a duplicate attribute is found
    ///
    /// @param selector The selector of the duplicate attribute
    error DuplicateAttribute(bytes4 selector);

    /// @notice Returns the keccak256 hash of a message request
    ///
    /// @dev Filters out the fulfiller attribute from the attributes array
    ///
    /// @param sourceChain      The source chain identifier
    /// @param sender           The account address of the sender
    /// @param destinationChain The destination chain identifier
    /// @param receiver         The account address of the receiver
    /// @param payload          The encoded calls to be included in the request
    /// @param attributes       The attributes to be included in the message
    ///
    /// @return _ The keccak256 hash of the message request
    function getMessageId(
        bytes32 sourceChain,
        bytes32 sender,
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes
    ) public view virtual returns (bytes32) {
        return keccak256(abi.encode(sourceChain, sender, destinationChain, receiver, payload, attributes));
    }

    /// @notice Locates an attribute in the attributes array
    ///
    /// @custom:reverts If the attribute is not found
    ///
    /// @param attributes The attributes array to search
    /// @param selector   The selector of the attribute to find
    ///
    /// @return attribute The attribute found
    function _locateAttribute(bytes[] calldata attributes, bytes4 selector) internal pure returns (bytes calldata) {
        (bool found, bytes calldata attribute) = _locateAttributeUnchecked(attributes, selector);

        if (!found) {
            revert AttributeNotFound(selector);
        }

        return attribute;
    }

    /// @notice Locates an attribute in the attributes array without checking if the attribute is found
    ///
    /// @param attributes The attributes array to search
    /// @param selector   The selector of the attribute to find
    ///
    /// @return found     Whether the attribute was found
    /// @return attribute The attribute found
    function _locateAttributeUnchecked(bytes[] calldata attributes, bytes4 selector)
        internal
        pure
        returns (bool found, bytes calldata attribute)
    {
        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == selector) {
                return (true, attributes[i]);
            }
        }
        return (false, attributes[0]);
    }

    /// @dev Helper function to find the index of a selector in the array
    function _findSelectorIndex(bytes4 selector, bytes4[] memory selectors) internal pure returns (uint256) {
        for (uint256 i; i < selectors.length; i++) {
            if (selector == selectors[i]) return i;
        }
        return type(uint256).max; // Not found
    }
}
