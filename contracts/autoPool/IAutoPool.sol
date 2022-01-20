// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IAutoPool {
    /// EVENTS ///

    event Deposit(
        address indexed account,
        uint256 poolId,
        uint256 amount
    );

    event Withdraw(
        address indexed account,
        uint256 poolId,
        uint256 amount
    );
}
