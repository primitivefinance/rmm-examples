// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20("TestERC20", "TEST") {
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
