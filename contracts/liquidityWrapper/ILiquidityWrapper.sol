// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@primitivefi/rmm-manager/contracts/interfaces/IMulticall.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title    Liquidity Wrapper Interface
/// @notice   Allows users to wrap specific PrimitiveManager liquidity pool tokens
///           (ERC1155) into ERC20 tokens
/// @author   Primitive
interface ILiquidityWrapper is IERC20, IERC1155Receiver, IMulticall {
    /// EVENTS ///

    /// @notice         Emitted when `from` wraps `amount` of liquidity pool tokens for `to`
    /// @param from     Address wrapping the liquidity pool tokens
    /// @param to       Address receiving the wrapped liquidity pool tokens
    /// @param amount   Amount of liquidity pool tokens wrapped
    event Wrap(address indexed from, address indexed to, uint256 amount);

    /// @notice         Emitted when `from` unwraps `amount` liquidity pool tokens for `to`
    /// @param from     Address unwrapping the liquidity pool tokens
    /// @param to       Address receiving the unwrapped liquidity pool tokens
    /// @param amount   Amount of liquidity pool tokens unwrapped
    event Unwrap(address indexed from, address indexed to, uint256 amount);

    /// EFFECT FUNCTIONS ///

    /// @notice           Self approves the wrapper to move `owner` liquidity pool tokens by using permit
    /// @param owner      Address of the owner of the liquidity pool tokens
    /// @param approved   True if the approval should be granted
    /// @param deadline   Expiry date of the signature
    /// @param v          V part of the signature
    /// @param r          R part of the signature
    /// @param s          S part of the signature
    function selfPermit(
        address owner,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice         Wraps `amount` of liquidity pool tokens and sends them to `to`
    /// @param to       Address of the recipient of the wrapped liquidity pool tokens
    /// @param amount   Amount of liquidity pool tokens to wrap
    function wrap(address to, uint256 amount) external;

    /// @notice         Unwraps `amount` of wrapped liquidity pool tokens and sends them to {to}
    /// @param to       Address of the recipient of the unwrapped liquidity pool tokens
    /// @param amount   Amount of wrapped liquidity pool tokens to unwrap
    function unwrap(address to, uint256 amount) external;

    /// VIEW FUNCTIONS ///

    /// @notice   Returns the address of the PrimitiveManager associated with this wrapper
    /// @return   Address of the PrimitiveManager associated with this wrapper
    function manager() external view returns (address);

    /// @notice   Returns the id of the PrimitiveManager liquidity pool token pool associated with this wrapper
    /// @return   Id of the PrimitiveManager liquidity pool token associated with this wrapper
    function poolId() external view returns (uint256);
}
