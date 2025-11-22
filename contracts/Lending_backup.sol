// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ImprovedLending is ReentrancyGuard {
    address public owner;
    IERC20 public stablecoin;
    
    struct UserPosition {
        uint256 collateral;
        uint256 debt;
    }
    
    mapping(address => UserPosition) public positions;
    
    // 使用更合理的抵押率参数
    uint256 public constant MIN_COLLATERAL_RATIO = 15000; // 150%
    uint256 public constant LIQUIDATION_THRESHOLD = 12500; // 125%
    uint256 public constant LIQUIDATION_BONUS = 500; // 5%
    uint256 public constant RATIO_DENOMINATOR = 10000;
    
    // 添加价格预言机接口（简化版）
    address public priceFeed;
    uint256 public constant ETH_PRICE = 2000 * 1e18; // 1 ETH = 2000 DAI (18 decimals)
    
    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address liquidator, uint256 collateralSeized);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    constructor(address _stablecoin) {
        owner = msg.sender;
        stablecoin = IERC20(_stablecoin);
    }
    
    function deposit() public payable nonReentrant {
        require(msg.value > 0, "Invalid amount");
        positions[msg.sender].collateral += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function borrow(uint256 amount) public nonReentrant {
        require(amount > 0, "Invalid amount");
        require(positions[msg.sender].collateral > 0, "No collateral");
        
        uint256 newDebt = positions[msg.sender].debt + amount;
        require(_isHealthy(msg.sender, newDebt), "Insufficient collateral");
        
        positions[msg.sender].debt = newDebt;
        require(stablecoin.transfer(msg.sender, amount), "Transfer failed");
        
        emit Borrowed(msg.sender, amount);
    }
    
    // 改进的健康检查函数
    function _isHealthy(address user, uint256 newDebt) internal view returns (bool) {
        if (newDebt == 0) return true;
        
        uint256 collateralValue = positions[user].collateral * ETH_PRICE / 1e18;
        uint256 ratio = (collateralValue * RATIO_DENOMINATOR) / newDebt;
        return ratio >= MIN_COLLATERAL_RATIO;
    }
    
    // 获取当前抵押率
    function getCollateralRatio(address user) public view returns (uint256) {
        if (positions[user].debt == 0) return type(uint256).max;
        
        uint256 collateralValue = positions[user].collateral * ETH_PRICE / 1e18;
        return (collateralValue * RATIO_DENOMINATOR) / positions[user].debt;
    }
}