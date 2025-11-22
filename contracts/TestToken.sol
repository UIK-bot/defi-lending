// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("Test DAI", "tDAI") {
        _mint(msg.sender, 1000000 * 10**18); // 铸造100万个测试代币
    }
    
    // 为了方便测试，添加一个铸币函数
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}