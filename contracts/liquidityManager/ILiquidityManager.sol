// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

/// @title    Liquidity Manager Interface
/// @notice   Shows how a contract can allocate and remove liquidity from RMM pools
///           on behalf of users. This example focuses on interacting with a unique
///           PrimitiveManager contract and only allows the deposit of a specific
///           risky / stable pair
/// @author   Primitive
interface ILiquidityManager {
    /// EFFECT FUNCTIONS ///

    /// @notice                   Allocates risky and stable tokens from the
    ///                           sender's wallet into a pool
    /// @param poolId             Id of the pool to allocate the tokens into
    /// @param delRisky           Amount of risky tokens to allocate into the pool
    /// @param delStable          Amount of stable tokens to allocate into the pool
    /// @param minLiquidityOut    Minimum amount of liquidity pool tokens expected
    ///                           to be received after the allocation
    function allocate(
        bytes32 poolId,
        uint256 delRisky,
        uint256 delStable,
        uint256 minLiquidityOut
    ) external;

    /// @notice                Removes risky and stable tokens from a pool and sends
    ///                        them to the sender's wallet
    /// @param engine          Address of the PrimitiveEngine contract specific to the
    ///                        risky / stable pair
    /// @param poolId          Id of the pool to remove the liquidity tokens from
    /// @param delLiquidity    Amount of liquidity pool tokens to remove
    /// @param minRiskyOut     Minimum amount of risky tokens expected to be received
    ///                        after the removal
    /// @param minStableOut    Minimum amount of stable tokens expected to be received
    ///                        after the removal
    function remove(
        address engine,
        bytes32 poolId,
        uint256 delLiquidity,
        uint256 minRiskyOut,
        uint256 minStableOut
    ) external;

    /// VIEW FUNCTIONS ///

    /// @notice   PrimitiveManager contract used to allocate and remove liquidity
    /// @return   Address of the PrimitiveManager contract
    function manager() external view returns (address);

    /// @notice   Risky token of the risky / stable pair
    /// @return   Address of the risky token contract
    function risky() external view returns (address);

    /// @notice   Stable token of the risky / stable pair
    /// @return   Address of the stable token contract
    function stable() external view returns (address);

    /// @notice   Amount of liquidity pool tokens currently owned by
    ///           a user and managed by the LiquidityManager contract
    /// @return   Amount of liquidity pool tokens
    function liquidityOf(address) external view returns (uint256);
}
