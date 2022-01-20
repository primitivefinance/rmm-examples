// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IAutoPool {
    /// STRUCTS ///

    struct UserInfo {
        uint256 amount;
        uint256 lastCumulatedRateIndex;
    }

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

    /// EFFECT FUNCTIONS ///

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function move(
        uint256 minRiskyOut,
        uint256 minStableOut,
        uint256 newPoolId,
        uint256 minLiquidityOut
    ) external;

    /// VIEW FUNCTIONS ///

    function userInfoOf(address account) external returns (
        uint256 amount,
        uint256 lastCumulatedRateIndex
    );

    function manager() external view returns (address);

    function engine() external view returns (address);

    function currentPoolId() external view returns (uint256);

    function PRECISION() external view returns (uint256);

    function cumulatedRates(uint256) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}
