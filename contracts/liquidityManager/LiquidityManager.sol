// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import "@primitivefi/rmm-manager/contracts/interfaces/IPrimitiveManager.sol";
import "@primitivefi/rmm-manager/contracts/interfaces/IMarginManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../libraries/TransferHelper.sol";

import "./ILiquidityManager.sol";

/// @title    Liquidity Manager contract
/// @notice   Shows how a contract can allocate and remove liquidity from RMM pools
///           on behalf of users. This example focuses on interacting with a unique
///           PrimitiveManager contract and only allows the deposit of a specific
///           risky / stable pair
/// @author   Primitive
contract LiquidityManager is ILiquidityManager, ERC1155Holder {
    /// STORAGE VARIABLES ///

    /// @inheritdoc ILiquidityManager
    address public immutable manager;

    /// @inheritdoc ILiquidityManager
    address public immutable risky;

    /// @inheritdoc ILiquidityManager
    address public immutable stable;

    /// @inheritdoc ILiquidityManager
    mapping(address => mapping(bytes32 => uint256)) public liquidityOf;

    /// EFFECT FUNCTIONS ///

    /// @param manager_    Address of the PrimitiveManager contract that this contract
    ///                    will interfact with
    /// @param risky_      Address of the risky token contract of the risky / stable pair
    /// @param stable_     Address of the stable token contract of the risky / stable pair
    constructor(
        address manager_,
        address risky_,
        address stable_
    ) {
        manager = manager_;
        risky = risky_;
        stable = stable_;

        // Warning: this approval mechanism is basic and could be abused by potential
        // malicious actors. A better implementation would be to check the allowance
        // before allocating or having a public approve function
        IERC20(risky).approve(manager, type(uint256).max);
        IERC20(stable).approve(manager, type(uint256).max);
    }

    /// @inheritdoc ILiquidityManager
    function allocate(
        bytes32 poolId,
        uint256 delRisky,
        uint256 delStable,
        uint256 minLiquidityOut
    ) external {
        TransferHelper.safeTransferFrom(risky, msg.sender, address(this), delRisky);
        TransferHelper.safeTransferFrom(stable, msg.sender, address(this), delStable);

        uint256 delLiquidity = IPrimitiveManager(manager).allocate(
            address(this),
            poolId,
            risky,
            stable,
            delRisky,
            delStable,
            false,
            minLiquidityOut
        );

        liquidityOf[msg.sender][poolId] += delLiquidity;
    }

    /// @inheritdoc ILiquidityManager
    function remove(
        address engine,
        bytes32 poolId,
        uint256 delLiquidity,
        uint256 minRiskyOut,
        uint256 minStableOut
    ) external {
        liquidityOf[msg.sender][poolId] -= delLiquidity;

        (uint256 delRisky, uint256 delStable) = IPrimitiveManager(manager)
            .remove(engine, poolId, delLiquidity, minRiskyOut, minStableOut);

        IMarginManager(manager).withdraw(
            msg.sender,
            engine,
            delRisky,
            delStable
        );
    }
}
