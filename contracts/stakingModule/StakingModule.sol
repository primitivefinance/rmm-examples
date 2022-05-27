// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract StakingModule {
    struct User {
        uint256 balance;
        uint256 claimed;
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
        users[msg.sender][poolId].claimed = pools[poolId].accumulatedRewardPerShare;
    }

    function pending(address sir, uint256 poolId) external view returns (uint256) {
        Pool memory pool = pools[poolId];
        uint256 rewardPerShare = pool.rewardPerBlock * PRECISION / pool.balance;
        uint256 accumulatedRewardPerShare = pool.accumulatedRewardPerShare + ((block.number - pool.lastUpdateAtBlock) * rewardPerShare);

        User memory user = users[sir][poolId];
        return (accumulatedRewardPerShare - user.claimed) / PRECISION * user.balance;
    }
}
