// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC1155TokenReceiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * TODO:
 * - [] Add a reentrancy protection
 */
/// @title Staking Module Contract
/// @notice Core of the staking module contract
/// @author Primitive
contract StakingModule is ERC1155TokenReceiver {
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

    mapping(uint256 => Pool) public pools;
    mapping(address => mapping(uint256 => User)) public users;
    uint256 public pc;

    bytes private empty;

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
        pools[pc].tokenId = tokenId;
        pools[pc].token = token;
        pools[pc].rewardPerBlock = rewardPerBlock;
        pools[pc].lastUpdateAtBlock = block.number;
        ++pc;
    }

    function deposit(uint256 poolId, uint256 amount) calibrate(poolId) external {
        pools[poolId].balance += amount;
        users[msg.sender][poolId].balance += amount;
        users[msg.sender][poolId].claimedAt = pools[poolId].accumulatedRewardPerShare;
        IERC1155(pools[poolId].token).safeTransferFrom(
            msg.sender,
            address(this),
            pools[poolId].tokenId,
            amount,
            empty
        );
    }

    function withdraw(uint256 poolId, uint256 amount) calibrate(poolId) external {
        claim(poolId);
        users[msg.sender][poolId].claimedAt = pools[poolId].accumulatedRewardPerShare;
        pools[poolId].balance -= amount;
        users[msg.sender][poolId].balance -= amount;
        IERC1155(pools[poolId].token).safeTransferFrom(
            address(this),
            msg.sender,
            pools[poolId].tokenId,
            amount,
            empty
        );
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
