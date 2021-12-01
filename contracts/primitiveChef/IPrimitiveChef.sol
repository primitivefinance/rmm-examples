// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@primitivefinance/rmm-periphery/contracts/interfaces/IERC1155Permit.sol";
import "@primitivefinance/rmm-periphery/contracts/interfaces/IMulticall.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./RewardToken.sol";

interface IPrimitiveChef is IMulticall {

    /// @notice Info of each user
    /// @param amount  How many LP tokens the user has provided
    /// @param rewardDebt
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC1155 lpToken; // Address of LP token contract.
        uint256 poolId;
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        uint256 accRewardPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }

    function rewardToken() external view returns (RewardToken);

    // Dev address.
    function collector() external view returns (address);

    // Block number when bonus SUSHI period ends.
    function bonusEndBlock() external view returns (uint256);

    // SUSHI tokens created per block.
    function rewardPerBlock() external view returns (uint256);

    // Bonus muliplier for early sushi makers.
    function BONUS_MULTIPLIER() external view returns (uint256);

    // Info of each pool.
    function pools(uint256) external view returns (
        IERC1155 lpToken,
        uint256 poolId,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accRewardPerShare
    );

    // Info of each user that stakes LP tokens.
    function users(uint256, address) external view returns (
        uint256 amount,
        uint256 rewardDebt
    );

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    function totalAllocPoint() external view returns (uint256);

    // The block number when SUSHI mining starts.
    function startBlock() external view returns (uint256);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );


    function selfPermit(
        address house,
        address owner,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function poolLength() external view returns (uint256);

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 allocPoint,
        IERC1155 lpToken,
        uint256 poolId,
        bool withUpdate
    ) external;

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(
        uint256 pid,
        uint256 allocPoint,
        bool withUpdate
    ) external;

    // Return reward multiplier over the given from to to block.
    function getMultiplier(uint256 from, uint256 to)
        external
        view
        returns (uint256);

    // View function to see pending SUSHIs on frontend.
    function pendingReward(uint256 pid, address account)
        external
        view
        returns (uint256);

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 pid) external;

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 pid, uint256 amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 pid, uint256 amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 pid) external;

    // Update dev address by the previous dev.
    function setCollector(address newCollector) external;
}
