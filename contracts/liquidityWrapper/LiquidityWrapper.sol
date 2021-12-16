// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@primitivefi/rmm-manager/contracts/interfaces/IERC1155Permit.sol";
import "@primitivefi/rmm-manager/contracts/base/Multicall.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./ILiquidityWrapper.sol";

/// @title   Liquidity Pool Tokens Wrapper contract
/// @notice  Wraps PrimitiveManager liquidity pool tokens (ERC1155) into ERC20 tokens
/// @author  Primitive
contract LiquidityWrapper is
    ILiquidityWrapper,
    ERC20,
    ERC1155Holder,
    Multicall
{
    /// @inheritdoc ILiquidityWrapper
    address public override manager;

    /// @inheritdoc ILiquidityWrapper
    uint256 public override poolId;

    /// @dev Null variable to pass to `safeTransferFrom`
    bytes private data;

    /// @param name_     Name of the wrapped token
    /// @param symbol_   Symbol of the wrapped token
    /// @param manager_  Address of the PrimitiveManager associated with this wrapper
    /// @param poolId_   Id of the PrimitiveManager pool associated with this wrapper
    constructor(
        string memory name_,
        string memory symbol_,
        address manager_,
        uint256 poolId_
    ) ERC20(name_, symbol_) {
        manager = manager_;
        poolId = poolId_;
    }

    /// @inheritdoc ILiquidityWrapper
    function selfPermit(
        address owner,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IERC1155Permit(manager).permit(
            owner,
            address(this),
            approved,
            deadline,
            v,
            r,
            s
        );
    }

    /// @inheritdoc ILiquidityWrapper
    function wrap(address to, uint256 amount) external override {
        IERC1155(manager).safeTransferFrom(
            msg.sender,
            address(this),
            poolId,
            amount,
            data
        );
        _mint(to, amount);
        emit Wrap(msg.sender, to, amount);
    }

    /// @inheritdoc ILiquidityWrapper
    function unwrap(address to, uint256 amount) external override {
        _burn(msg.sender, amount);
        IERC1155(manager).safeTransferFrom(
            address(this),
            to,
            poolId,
            amount,
            data
        );
        emit Unwrap(msg.sender, to, amount);
    }
}
