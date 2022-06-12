// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IERC1155TokenReceiver.sol";

/// @title ERC1155 Token Receiver
/// @notice Abstract contract allowing the reception of ERC1155 tokens
/// @dev On top of inheriting from this contract, both ERC1155 receive functions can be overridden to add custom behaviors on reception
/// @author Primitive
abstract contract ERC1155TokenReceiver is IERC1155TokenReceiver {
    /// EFFECT FUNCTIONS ///

    /// @inheritdoc IERC1155TokenReceiver
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external virtual returns (bytes4) {
        return IERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @inheritdoc IERC1155TokenReceiver
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns (bytes4) {
        return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}
