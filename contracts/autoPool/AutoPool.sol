// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@primitivefi/rmm-manager/contracts/base/Multicall.sol";
import "@primitivefi/rmm-manager/contracts/interfaces/IPrimitiveManager.sol";
import "@primitivefi/rmm-core/contracts/interfaces/IPrimitiveEngine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./IAutoPool.sol";

/// @title    AutoPool contract
/// @author   Primitive
/// @notice   Allows liquidity providers to have their LP tokens automatically moved to a new pool after the expiration of the
///           current one.
contract AutoPool is IAutoPool, Ownable, ERC1155Holder, Multicall {
    /// @inheritdoc IAutoPool
    mapping(address => UserInfo) public override userInfoOf;

    /// @inheritdoc IAutoPool
    address public immutable override manager;

    /// @inheritdoc IAutoPool
    address public immutable override engine;

    /// @inheritdoc IAutoPool
    uint256 public immutable override PRECISION = 10 ** 18;

    /// @inheritdoc IAutoPool
    uint256[] public override cumulatedRates;

    /// @inheritdoc IAutoPool
    uint256 public override currentPoolId;

    /// @dev Empty bytes to pass along ERC1155 transfers
    bytes private _empty;

    modifier updateUserInfo() {
        if (userInfoOf[msg.sender].lastCumulatedRateIndex != cumulatedRates.length - 1) {
            userInfoOf[msg.sender].amount = userInfoOf[msg.sender].amount
            * cumulatedRates[cumulatedRates.length - 1]
            / cumulatedRates[userInfoOf[msg.sender].lastCumulatedRateIndex]
            ;
        }

        userInfoOf[msg.sender].lastCumulatedRateIndex = cumulatedRates.length - 1;

        _;
    }

    constructor(
        address engine_,
        address manager_,
        uint256 currentPoolId_
    ) {
        engine = engine_;
        manager = manager_;
        currentPoolId = currentPoolId_;
        cumulatedRates.push(1 * 10 ** 18);
    }

    function deposit(uint256 amount) external updateUserInfo() override {
        IERC1155(manager).safeTransferFrom(
            msg.sender,
            address(this),
            currentPoolId,
            amount,
            _empty
        );

        userInfoOf[msg.sender].amount += amount;

        emit Deposit(msg.sender, currentPoolId, amount);
    }

    function withdraw(uint256 amount) external updateUserInfo() override {
        IERC1155(manager).safeTransferFrom(
            msg.sender,
            address(this),
            currentPoolId,
            amount,
            _empty
        );

        userInfoOf[msg.sender].amount += amount;

        emit Withdraw(msg.sender, currentPoolId, amount);
    }

    function move(
        uint256 minRiskyOut,
        uint256 minStableOut,
        uint256 newPoolId,
        uint256 minLiquidityOut
    ) external onlyOwner() override {
        uint256 previousdelLiquidity = IERC1155(manager).balanceOf(address(this), currentPoolId);

        (uint256 delRisky, uint256 delStable) = IPrimitiveManager(manager).remove(
            engine,
            bytes32(currentPoolId),
            previousdelLiquidity,
            minRiskyOut,
            minStableOut
        );

        uint256 delLiquidity = IPrimitiveManager(manager).allocate(
            bytes32(newPoolId),
            IPrimitiveEngine(engine).risky(),
            IPrimitiveEngine(engine).stable(),
            delRisky,
            delStable,
            false,
            minLiquidityOut
        );

        uint256 rate = delLiquidity * PRECISION / previousdelLiquidity;
        uint256 cumulatedRate = rate * cumulatedRates[cumulatedRates.length - 1] / PRECISION;
        cumulatedRates.push(cumulatedRate);
        currentPoolId = newPoolId;
    }

    function balanceOf(address account) external view override returns (uint256) {
        uint256 amount = userInfoOf[account].amount
            * cumulatedRates[cumulatedRates.length - 1]
            / cumulatedRates[userInfoOf[account].lastCumulatedRateIndex];

        return amount;
    }
}
