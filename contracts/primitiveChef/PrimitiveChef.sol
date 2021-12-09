// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// @title   PrimitiveChef contract
/// @notice  Updated version of SushiSwap MasterChef contract to support Primitive liquidity tokens.
///          Along a couple of improvements, the biggest change is the support of ERC1155 instead of ERC20.
/// @author  Primitive

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@primitivefi/rmm-manager/contracts/interfaces/IERC1155Permit.sol";
import "@primitivefi/rmm-manager/contracts/base/Multicall.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./IPrimitiveChef.sol";
import "./RewardToken.sol";

contract PrimitiveChef is IPrimitiveChef, Ownable, ERC1155Holder, Multicall {
    using SafeERC20 for IERC20;

    // The SUSHI TOKEN!
    RewardToken public override rewardToken;

    // Dev address.
    address public override collector;

    // Block number when bonus SUSHI period ends.
    uint256 public override bonusEndBlock;

    // SUSHI tokens created per block.
    uint256 public override rewardPerBlock;

    // Bonus muliplier for early sushi makers.
    uint256 public constant override BONUS_MULTIPLIER = 10;

    // Info of each pool.
    PoolInfo[] public override pools;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public override users;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public override totalAllocPoint = 0;

    // The block number when SUSHI mining starts.
    uint256 public override startBlock;

    bytes private _data;

    constructor(
        RewardToken rewardToken_,
        address collector_,
        uint256 rewardPerBlock_,
        uint256 startBlock_,
        uint256 bonusEndBlock_
    ) {
        rewardToken = rewardToken_;
        collector = collector_;
        rewardPerBlock = rewardPerBlock_;
        bonusEndBlock = bonusEndBlock_;
        startBlock = startBlock_;
    }

    function selfPermit(
        address house,
        address owner,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IERC1155Permit(house).permit(owner, address(this), approved, deadline, v, r, s);
    }

    function poolLength() external view override returns (uint256) {
        return pools.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 allocPoint,
        IERC1155 lpToken,
        uint256 poolId,
        bool withUpdate
    ) external override onlyOwner() {
        if (withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += allocPoint;
        pools.push(
            PoolInfo({
                lpToken: lpToken,
                poolId: poolId,
                allocPoint: allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0
            })
        );
    }

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(
        uint256 pid,
        uint256 allocPoint,
        bool withUpdate
    ) external override onlyOwner() {
        if (withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint -= pools[pid].allocPoint + allocPoint;
        pools[pid].allocPoint = allocPoint;
    }

    // Return reward multiplier over the given from to to block.
    function getMultiplier(uint256 from, uint256 to) public view override returns (uint256) {
        if (to <= bonusEndBlock) {
            return to -  from * BONUS_MULTIPLIER;
        } else if (from >= bonusEndBlock) {
            return to - from;
        } else {
            return bonusEndBlock - from * BONUS_MULTIPLIER + to - bonusEndBlock;
        }
    }

    // View function to see pending SUSHIs on frontend.
    function pendingReward(uint256 pid, address account)
        external
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = users[pid][account];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this), pool.poolId);
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward =
                multiplier * rewardPerBlock * pool.allocPoint / totalAllocPoint;
            accRewardPerShare += sushiReward * 1e12 / lpSupply;
        }
        return user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public override {
        uint256 length = pools.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 pid) public override {
        PoolInfo storage pool = pools[pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this), pool.poolId);
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward = multiplier * rewardPerBlock * pool.allocPoint / totalAllocPoint;
        rewardToken.mint(collector, reward / 10);
        rewardToken.mint(address(this), reward);
        pool.accRewardPerShare += reward * 1e12 / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 pid, uint256 amount) public override {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = users[pid][msg.sender];
        updatePool(pid);
        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accRewardPerShare / 1e12 - user.rewardDebt;
            safeRewardTransfer(msg.sender, pending);
        }

        pool.lpToken.safeTransferFrom(
            msg.sender,
            address(this),
            pool.poolId,
            amount,
            _data
        );

        user.amount += amount;
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;
        emit Deposit(msg.sender, pid, amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 pid, uint256 amount) public override {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = users[pid][msg.sender];
        require(user.amount >= amount, "withdraw: not good");
        updatePool(pid);
        uint256 pending = user.amount * pool.accRewardPerShare / 1e12 - user.rewardDebt;
        safeRewardTransfer(msg.sender, pending);
        user.amount -= amount;
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;

        pool.lpToken.safeTransferFrom(
            address(this),
            msg.sender,
            pool.poolId,
            amount,
            _data
        );

        emit Withdraw(msg.sender, pid, amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 pid) public override {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = users[pid][msg.sender];

        pool.lpToken.safeTransferFrom(
            address(this),
            msg.sender,
            pool.poolId,
            user.amount,
            _data
        );

        emit EmergencyWithdraw(msg.sender, pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeRewardTransfer(address to, uint256 amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (amount > balance) {
            rewardToken.transfer(to, balance);
        } else {
            rewardToken.transfer(to, amount);
        }
    }

    // Update dev address by the previous dev.
    function setCollector(address newCollector) public onlyOwner() override {
        collector = newCollector;
    }
}
