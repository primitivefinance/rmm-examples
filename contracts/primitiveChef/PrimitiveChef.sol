// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@primitivefi/rmm-manager/contracts/interfaces/IERC1155Permit.sol";
import "@primitivefi/rmm-manager/contracts/base/Multicall.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@primitivefi/rmm-manager/contracts/base/Reentrancy.sol";

import "./IPrimitiveChef.sol";
import "./RewardToken.sol";

/// @title   PrimitiveChef contract
/// @notice  Updated version of SushiSwap MasterChef contract to support Primitive liquidity tokens.
///          Along a couple of improvements, the biggest change is the support of ERC1155 instead of ERC20.
/// @author  Primitive
contract PrimitiveChef is
    IPrimitiveChef,
    Ownable,
    ERC1155Holder,
    Multicall,
    Reentrancy
{
    using SafeERC20 for IERC20;

    /// STATE VARIABLES ///

    /// @inheritdoc IPrimitiveChef
    RewardToken public override rewardToken;

    /// @inheritdoc IPrimitiveChef
    address public override collector;

    /// @inheritdoc IPrimitiveChef
    uint256 public override bonusEndBlock;

    /// @inheritdoc IPrimitiveChef
    uint256 public override rewardPerBlock;

    /// @inheritdoc IPrimitiveChef
    uint256 public constant override BONUS_MULTIPLIER = 10;

    /// @inheritdoc IPrimitiveChef
    PoolInfo[] public override pools;

    /// @inheritdoc IPrimitiveChef
    mapping(uint256 => mapping(address => UserInfo)) public override users;

    /// @inheritdoc IPrimitiveChef
    uint256 public override totalAllocPoint = 0;

    /// @inheritdoc IPrimitiveChef
    uint256 public override startBlock;

    /// @dev Null variable to pass with ERC1155 transfer calls
    bytes private _data;

    /// EFFECT FUNCTIONS ///

    /// @param rewardToken_ Address of the token rewarded to the stakers
    /// @param collector_ Address collecting the staking dev bonus
    /// @param rewardPerBlock_ Amount of reward per block
    /// @param bonusEndBlock_ Block number of the end of the bonus period
    /// @param startBlock_ Block number of the start of the staking
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
        startBlock = startBlock_;
        bonusEndBlock = bonusEndBlock_;
    }

    /// @inheritdoc IPrimitiveChef
    function selfPermit(
        address lpToken,
        address owner,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IERC1155Permit(lpToken).permit(
            owner,
            address(this),
            approved,
            deadline,
            v,
            r,
            s
        );
    }

    /// @inheritdoc IPrimitiveChef
    function add(
        uint256 allocPoint,
        IERC1155 lpToken,
        uint256 tokenId,
        bool withUpdate
    ) external override onlyOwner {
        if (withUpdate) massUpdatePools();

        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint += allocPoint;

        pools.push(
            PoolInfo({
                lpToken: lpToken,
                tokenId: tokenId,
                allocPoint: allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0
            })
        );
    }

    /// @inheritdoc IPrimitiveChef
    function set(
        uint256 pid,
        uint256 allocPoint,
        bool withUpdate
    ) external override onlyOwner {
        if (withUpdate) massUpdatePools();

        totalAllocPoint -= pools[pid].allocPoint + allocPoint;
        pools[pid].allocPoint = allocPoint;
    }

    /// @inheritdoc IPrimitiveChef
    function massUpdatePools() public override {
        uint256 length = pools.length;

        for (uint256 pid = 0; pid < length; pid += 1) {
            updatePool(pid);
        }
    }

    /// @inheritdoc IPrimitiveChef
    function updatePool(uint256 pid) public override {
        PoolInfo storage pool = pools[pid];

        if (block.number <= pool.lastRewardBlock) return;

        uint256 lpSupply = pool.lpToken.balanceOf(address(this), pool.tokenId);

        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward = (multiplier * rewardPerBlock * pool.allocPoint) /
            totalAllocPoint;

        rewardToken.mint(collector, reward / 10);
        rewardToken.mint(address(this), reward);

        pool.accRewardPerShare += (reward * 1e12) / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    /// @inheritdoc IPrimitiveChef
    function deposit(uint256 pid, uint256 amount) external override lock {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = users[pid][msg.sender];

        updatePool(pid);

        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accRewardPerShare) /
                1e12 -
                user.rewardDebt;
            safeRewardTransfer(msg.sender, pending);
        }

        pool.lpToken.safeTransferFrom(
            msg.sender,
            address(this),
            pool.tokenId,
            amount,
            _data
        );

        user.amount += amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;

        emit Deposit(msg.sender, pid, amount);
    }

    /// @inheritdoc IPrimitiveChef
    function withdraw(uint256 pid, uint256 amount) external override lock {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = users[pid][msg.sender];

        if (amount > user.amount) revert WithdrawAmountError();

        updatePool(pid);

        uint256 pending = (user.amount * pool.accRewardPerShare) /
            1e12 -
            user.rewardDebt;

        safeRewardTransfer(msg.sender, pending);

        user.amount -= amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;

        pool.lpToken.safeTransferFrom(
            address(this),
            msg.sender,
            pool.tokenId,
            amount,
            _data
        );

        emit Withdraw(msg.sender, pid, amount);
    }

    /// @inheritdoc IPrimitiveChef
    function emergencyWithdraw(uint256 pid) external override lock {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = users[pid][msg.sender];

        pool.lpToken.safeTransferFrom(
            address(this),
            msg.sender,
            pool.tokenId,
            user.amount,
            _data
        );

        emit EmergencyWithdraw(msg.sender, pid, user.amount);

        user.amount = 0;
        user.rewardDebt = 0;
    }

    /// @inheritdoc IPrimitiveChef
    function setCollector(address newCollector) external override onlyOwner {
        collector = newCollector;
    }

    /// VIEW FUNCTIONS ///

    /// @inheritdoc IPrimitiveChef
    function poolLength() external view override returns (uint256) {
        return pools.length;
    }

    /// @inheritdoc IPrimitiveChef
    function getMultiplier(uint256 from, uint256 to)
        public
        view
        override
        returns (uint256)
    {
        if (to <= bonusEndBlock) return to - from * BONUS_MULTIPLIER;
        if (from >= bonusEndBlock) return to - from;
        return bonusEndBlock - from * BONUS_MULTIPLIER + to - bonusEndBlock;
    }

    /// @inheritdoc IPrimitiveChef
    function pendingReward(uint256 pid, address account)
        external
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = pools[pid];
        UserInfo storage user = users[pid][account];

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this), pool.tokenId);

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 sushiReward = (multiplier *
                rewardPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accRewardPerShare += (sushiReward * 1e12) / lpSupply;
        }

        return (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
    }

    /// INTERNAL FUNCTIONS ///

    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeRewardTransfer(address to, uint256 amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));

        if (amount > balance) {
            rewardToken.transfer(to, balance);
        } else {
            rewardToken.transfer(to, amount);
        }
    }
}
