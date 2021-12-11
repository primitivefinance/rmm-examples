// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefi/rmm-manager/contracts/base/ERC1155Permit.sol";

contract TestERC1155Permit is ERC1155Permit {
    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        bytes memory data;
        _mint(account, id, amount, data);
    }
}
