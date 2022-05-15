// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title    RewardToken Contract
/// @notice   Reward token distributed via a PrimitiveChef contract
/// @author   Primitive
contract RewardToken is ERC20 {
    /// ERRORS ///

    /// @notice   Thrown when the sender is not the `chef` address
    error NotChefError();

    /// MODIFIERS ///

    /// @dev   Restricts the call to the `chef` address
    modifier onlyChef() {
        if (msg.sender != chef) revert NotChefError();
        _;
    }

    /// STORAGE VARIABLES ///

    /// @notice   Address of the PrimitiveChef contract
    address public chef;

    /// EFFECT FUNCTIONS ///

    /// @param name_     Name of the reward token
    /// @param symbol_   Symbol of the reward token
    /// @param chef_     Address of the PrimitiveChef contract
    constructor(
        string memory name_,
        string memory symbol_,
        address chef_
    ) ERC20(name_, symbol_) {
        chef = chef_;
    }

    /// @notice         Mints `amount` of tokens to `to`
    /// @dev            Can only be called by the PrimitiveChef
    /// @param to       Address receiving the tokens
    /// @param amount   Amount of tokens to mint
    function mint(address to, uint256 amount) external onlyChef {
        _mint(to, amount);
    }
}
