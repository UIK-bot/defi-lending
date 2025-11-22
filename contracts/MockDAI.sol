// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockDAI is ERC20 {
    constructor() ERC20("Mock DAI", "mDAI") {
        // 初始铸造给部署者 1,000,000 代币
        _mint(msg.sender, 1_000_000 * 1e18);
    }
}
