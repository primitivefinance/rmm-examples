// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefi/rmm-manager/contracts/interfaces/IPrimitiveManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract LiquidityExample is ERC1155Holder {
    address public manager;
    address public risky;
    address public stable;

    mapping(address => uint256) public liquidityOf;

    constructor(
        address manager_,
        address risky_,
        address stable_
    ) {
        manager = manager_;
        risky = risky_;
        stable = stable_;

        IERC20(risky).approve(manager, type(uint256).max);
        IERC20(stable).approve(manager, type(uint256).max);
    }

    function allocate(
        bytes32 poolId,
        uint256 delRisky,
        uint256 delStable,
        uint256 minLiquidityOut
    ) external {
        IERC20(risky).transferFrom(msg.sender, address(this), delRisky);
        IERC20(stable).transferFrom(msg.sender, address(this), delStable);

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

        liquidityOf[msg.sender] += delLiquidity;

        uint256 dust = IERC20(risky).balanceOf(address(this));
        if (dust != 0) IERC20(risky).transfer(msg.sender, dust);

        dust = IERC20(stable).balanceOf(address(this));
        if (dust != 0) IERC20(stable).transfer(msg.sender, dust);
    }

    function remove(
        address engine,
        bytes32 poolId,
        uint256 delLiquidity,
        uint256 minRiskyOut,
        uint256 minStableOut
    ) external {
        liquidityOf[msg.sender] -= delLiquidity;

        (
            uint256 delRisky,
            uint256 delStable
        ) = IPrimitiveManager(manager).remove(engine, poolId, delLiquidity, minRiskyOut, minStableOut);

        if (delRisky != 0) IERC20(risky).transfer(msg.sender, delRisky);
        if (delStable != 0) IERC20(stable).transfer(msg.sender, delStable);
    }
}
