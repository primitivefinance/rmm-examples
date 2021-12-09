// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@primitivefi/rmm-manager/contracts/interfaces/IERC1155Permit.sol";
import "@primitivefi/rmm-manager/contracts/base/Multicall.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract WLP is ERC20, ERC1155Holder, Multicall {
    address public house;
    uint256 public poolId;

    bytes private data;

    constructor(
        string memory name_,
        string memory symbol_,
        address house_,
        uint256 poolId_
    ) ERC20(name_, symbol_) {
        house = house_;
        poolId = poolId_;
    }

    function selfPermit(
        address owner,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC1155Permit(house).permit(owner, address(this), approved, deadline, v, r, s);
    }

    function wrap(address to, uint256 amount) external {
        IERC1155(house).safeTransferFrom(msg.sender, address(this), poolId, amount, data);
        _mint(to, amount);
    }

    function unwrap(address to, uint256 amount) external {
        _burn(msg.sender, amount);
        IERC1155(house).safeTransferFrom(address(this), to, poolId, amount, data);
    }
}
