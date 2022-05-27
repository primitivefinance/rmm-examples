// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract StakingModule {
    struct User {
        uint256 balance;
        uint256 claimedAt;
    }

    struct Pool {
        uint256 tokenId;
        address token;
        uint256 rewardPerBlock;
        uint256 accumulatedRewardPerShare;
        uint256 lastUpdateAtBlock;
        uint256 balance;
    }

    Pool[] public pools;
    mapping(address => mapping(uint256 => User)) public users;

    address public immutable rewardToken;
    uint256 public PRECISION = 10 ** 12;

    modifier calibrate(uint256 poolId) {
        Pool storage pool = pools[poolId];

        if (pool.balance > 0) {
            uint256 rewardPerShare = pool.rewardPerBlock * PRECISION / pool.balance;
            pool.accumulatedRewardPerShare += (block.number - pool.lastUpdateAtBlock) * rewardPerShare;
        }

        pool.lastUpdateAtBlock = block.number;
        _;
    }

    constructor(address _rewardToken) {
        rewardToken = _rewardToken;
    }

    function create(
        uint256 tokenId,
        address token,
        uint256 rewardPerBlock
    ) external {
        pools.push(Pool({
            tokenId: tokenId,
            token: token,
            rewardPerBlock: rewardPerBlock,
            accumulatedRewardPerShare: 0,
            lastUpdateAtBlock: block.number,
            balance: 0
        }));
    }

    function deposit(uint256 poolId, uint256 amount) calibrate(poolId) external {
        pools[poolId].balance += amount;
        users[msg.sender][poolId].balance += amount;
        users[msg.sender][poolId].claimedAt = pools[poolId].accumulatedRewardPerShare;
    }

    function withdraw(uint256 poolId, uint256 amount) calibrate(poolId) external {
        claim(poolId);
        users[msg.sender][poolId].claimedAt = pools[poolId].accumulatedRewardPerShare;
        pools[poolId].balance -= amount;
        users[msg.sender][poolId].balance -= amount;
    }

    function claim(uint256 poolId) calibrate(poolId) public {
        uint256 amount = pending(msg.sender, poolId);
        users[msg.sender][poolId].claimedAt = pools[poolId].accumulatedRewardPerShare;
        _distribute(msg.sender, amount);
    }

    function pending(address staker, uint256 poolId) public view returns (uint256) {
        Pool memory pool = pools[poolId];
        uint256 rewardPerShare = pool.rewardPerBlock * PRECISION / pool.balance;
        uint256 accumulatedRewardPerShare = pool.accumulatedRewardPerShare + ((block.number - pool.lastUpdateAtBlock) * rewardPerShare);

        User memory user = users[staker][poolId];
        return (accumulatedRewardPerShare - user.claimedAt) / PRECISION * user.balance;
    }

    function _distribute(address to, uint256 amount) private {

    }
}
