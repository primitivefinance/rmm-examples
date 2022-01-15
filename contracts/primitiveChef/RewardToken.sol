// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    error NotChefError();

    modifier onlyChef() {
        if (msg.sender != chef) revert NotChefError();
        _;
    }

    address public chef;

    constructor(
        string memory name_,
        string memory symbol_,
        address chef_
    ) ERC20(name_, symbol_) {
        chef = chef_;
    }

    function mint(address to, uint256 amount) external onlyChef {
        _mint(to, amount);
    }
}
