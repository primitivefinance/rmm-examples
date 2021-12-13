// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@primitivefi/rmm-manager/contracts/interfaces/IERC1155Permit.sol";
import "@primitivefi/rmm-manager/contracts/interfaces/IMulticall.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./RewardToken.sol";

/// @title   Interface of the PrimitiveChef contract
/// @author  Primitive
interface IPrimitiveChef is IMulticall {
    /// STRUCTS ///

    /// @notice             Info of a user
    /// @return amount      Amount of liquidity pool tokens provided by the user
    /// @return rewardDebt  Pending reward debt of the user
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /// @notice                    Info of a staking pool
    /// @return lpToken            Address of the PrimitiveManager contract
    /// @return tokenId            Id of the PrimitiveManager pool
    /// @return allocPoinnt        Allocation points assigned to this pool
    /// @return lastRewardBlock    Last block number with a reward distribution
    /// @return accRewardPerShare  Accumulated reward per share with a 1e12 precision
    struct PoolInfo {
        IERC1155 lpToken;
        uint256 tokenId;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    /// EVENTS ///

    /// @notice        Emitted when a user deposits liquidity pool tokens in a staking pool
    /// @param user    Address of the user depositing into the staking pool
    /// @param pid     Id of the staking pool
    /// @param amount  Amount of liquidity pool tokens deposited into the staking pool
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice        Emitted when a user withdraws liquidity pool tokens from a staking pool
    /// @param user    Address of the user withdrawing from the staking pool
    /// @param pid     Id of the staking pool
    /// @param amount  Amount of liquidity tokens withdrawn from the staking pool
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice      Emitted when a user emergency withdraws liquidity pool tokens from a staking pool
    /// @param user  Address of the user emergency withdrawing from the staking pool
    /// @param pid   Id of the staking pool
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /// ERRORS ///

    /// @notice  Thrown when a user tries to withdraw more liquidity pool tokens than what they staked
    error WithdrawAmountError();

    /// EFFECT FUNCTIONS ///

    /// @notice          Self approves this contract to move {lpToken} liquidity pool tokens from {owner}'s wallet
    /// @param lpToken   Address of the PrimitiveManager contract
    /// @param owner     Address of the owner of the tokens
    /// @param approved  True if approval should be granted
    /// @param v         V part of the signature
    /// @param r         R part of the signature
    /// @param s         S part of the signature
    function selfPermit(
        address lpToken,
        address owner,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice            Adds a new liquidity pool token to the contract
    /// @dev               Adding the same PrDo not add the same liquidity pool token twice, or this will mess up the reward calculations
    /// @param allocPoint  Allocation points for this staking pool
    /// @param lpToken     Address of the PrimitiveManager
    /// @param tokenId     Id of the PrimitiveManager pool
    /// @param withUpdate  True if the reward variables of the pool should be updated
    function add(
        uint256 allocPoint,
        IERC1155 lpToken,
        uint256 tokenId,
        bool withUpdate
    ) external;

    /// @notice            Updates the allocation points of a pool
    /// @param pid         Id of the pool to update
    /// @param allocPoint  New allocation points for the pool
    /// @param withUpdate  True if the reward variables of the pool should be updated
    function set(
        uint256 pid,
        uint256 allocPoint,
        bool withUpdate
    ) external;

    /// @notice  Mass updates the reward variables for all the pools
    function massUpdatePools() external;

    /// @notice     Updates the reward variables of a given pool
    /// @param pid  Id of the poold to update
    function updatePool(uint256 pid) external;

    /// @notice        Deposits {amount} of liquidity pool tokens into pool {pid}
    /// @param pid     Id of the pool to deposit into
    /// @param amount  Amount of liquidity pool tokens to deposit into the pool
    function deposit(uint256 pid, uint256 amount) external;

    /// @notice        Withdraws {amount} of liquidity pool tokens from pool {poolId}
    /// @param pid     Id of the pool to withdraw from
    /// @param amount  Amount of liquidity pool tokens to withdraw from the pool
    function withdraw(uint256 pid, uint256 amount) external;

    /// @notice     Emergency withdraws all the liquidity pool tokens from pool {poolId},
    ///             without getting the reward
    /// @param pid  Id of the pool to emergency withdraw from
    function emergencyWithdraw(uint256 pid) external;

    /// @notice Sets the address of the dev bonus collector
    /// @param newCollector Address of the new collector
    function setCollector(address newCollector) external;

    /// VIEW FUNCTIONS ///

    /// @notice  Returns the token rewarded to the stakers
    /// @return  Contract of the reward token
    function rewardToken() external view returns (RewardToken);

    /// @notice  Returns the address collecting the dev bonus
    /// @return  Address of the collector
    function collector() external view returns (address);

    /// @notice  Returns the end of the bonus period
    /// @return  Block number of the end of the bonus period
    function bonusEndBlock() external view returns (uint256);

    /// @notice  Returns the reward awarded per block
    /// @return  Reward amount per block (with decimals)
    function rewardPerBlock() external view returns (uint256);

    /// @notice  Returns the bonus multiplier for early stakers
    /// @return  Multiplier bonus amount
    function BONUS_MULTIPLIER() external view returns (uint256);

    /// @notice                    Returns the info of {poolId}
    /// @param poolId              Id of the staking pool
    /// @return lpToken            Address of the PrimitiveManager contract emitting the liquidity pool tokens
    /// @return tokenId            Id of the PrimitiveManager pool
    /// @return allocPoint        Allocation points assigned to this pool
    /// @return lastRewardBlock    Last block number with a reward distribution
    /// @return accRewardPerShare  Accumulated reward per share with a 1e12 precision
    function pools(uint256 poolId) external view returns (
        IERC1155 lpToken,
        uint256 tokenId,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accRewardPerShare
    );

    /// @notice             Returns staking info of {poolId} for {user}
    /// @param poolId       Id of the staking pool
    /// @param user         Address of the user
    /// @return amount      Amount of liquidity pool tokens staked by the user in this pool
    /// @return rewardDebt  Pending reward for the user for this pool
    function users(uint256 poolId, address user) external view returns (
        uint256 amount,
        uint256 rewardDebt
    );

    /// @notice  Returns the sum of all allocation points in all pools
    /// @return  Amount of all allocation points in all poools
    function totalAllocPoint() external view returns (uint256);

    /// @notice  Returns the starting block of the staking
    /// @return  Block number of the start of the staking
    function startBlock() external view returns (uint256);

    /// @notice  Returns the number of pools created
    /// @return  Number of pools created
    function poolLength() external view returns (uint256);

    /// @notice  Returns the reward multiplier over the given from and to blocks
    /// @return  Reward multiplier amount
    function getMultiplier(
        uint256 from,
        uint256 to
    ) external view returns (uint256);

    /// @notice      Returns the pending reward of {user} for the staking pool {pid}
    /// @param pid   Id of the staking pool
    /// @param user  Address of the user
    /// @return      Amount of pending reward
    function pendingReward(
        uint256 pid,
        address user
    ) external view returns (uint256);
}
