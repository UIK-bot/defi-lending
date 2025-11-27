// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Lending is ReentrancyGuard {
    address public owner;
    IERC20 public stablecoin;
    
    struct UserPosition {
        uint256 collateral;
        uint256 debt;
    }
    
    mapping(address => UserPosition) public positions;

    // === 新增：用户列表 ===
    address[] public users;
    mapping(address => bool) public isUser;

    
    // 抵押率参数
    uint256 public constant MIN_COLLATERAL_RATIO = 15000; // 150%
    uint256 public constant RATIO_DENOMINATOR = 10000;
    
    // 假设 1 ETH = 2000 DAI (简化版预言机)
    uint256 public constant ETH_PRICE = 2000 * 1e18;
    
    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Liquidated(
        address indexed user,
        address indexed liquidator,
        uint256 debtRepaid,
        uint256 collateralSeized
    );
 


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    constructor(address _stablecoin) {
        owner = msg.sender;
        stablecoin = IERC20(_stablecoin);
    }
    
    // 存款抵押函数
    function deposit() public payable nonReentrant {
        require(msg.value > 0, "Must deposit some ETH");
        positions[msg.sender].collateral += msg.value;
        _registerUser(msg.sender); 
        emit Deposited(msg.sender, msg.value);
    }
    
    // 借款函数
    function borrow(uint256 amount) public nonReentrant {
        require(amount > 0, "Must borrow positive amount");
        require(positions[msg.sender].collateral > 0, "No collateral deposited");
        
        // 检查抵押率是否足够
        uint256 newDebt = positions[msg.sender].debt + amount;
        require(_isHealthy(msg.sender, positions[msg.sender].collateral, newDebt), "Insufficient collateral ratio");
        
        _registerUser(msg.sender); 
        positions[msg.sender].debt = newDebt;

        // 检查合约是否有足够的稳定币
        uint256 contractBalance = stablecoin.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient liquidity");
        
        // 转账稳定币给用户
        require(stablecoin.transfer(msg.sender, amount), "Transfer failed");
        
        emit Borrowed(msg.sender, amount);
    }
    
    // 还款函数
    function repay(uint256 amount) public nonReentrant {
        require(amount > 0, "Must repay positive amount");
        require(positions[msg.sender].debt >= amount, "Repay amount exceeds debt");
        
        // 从用户转移稳定币到合约
        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        positions[msg.sender].debt -= amount;
        emit Repaid(msg.sender, amount);
    }
    

    // 提取抵押物函数
    function withdraw(uint256 amount) public nonReentrant {
        require(amount > 0, "Must withdraw positive amount");
        require(positions[msg.sender].collateral >= amount, "Insufficient collateral");
        
        // 检查提取后抵押率是否足够
        uint256 remainingCollateral = positions[msg.sender].collateral - amount;
        
        if (positions[msg.sender].debt > 0) {
            require(
                _isHealthy(
                    msg.sender,
                    remainingCollateral,
                    positions[msg.sender].debt
                ),
                "Insufficient ratio"
            );
        }


        
        positions[msg.sender].collateral = remainingCollateral;
        
        // 转账ETH给用户
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    //清算函数
    function liquidate(address user) external nonReentrant {
        require(isLiquidatable(user), "Position is healthy");

        uint256 debt = positions[user].debt;
        uint256 collateral = positions[user].collateral;
        require(debt > 0 && collateral > 0, "Empty position");

        // 清算人先把用户的全部债务还进合约
        require(
            stablecoin.transferFrom(msg.sender, address(this), debt),
            "Debt transfer failed"
        );

        // 将用户的仓位清空
        positions[user].debt = 0;
        positions[user].collateral = 0;

        // 把用户的全部抵押 ETH 给清算人
        (bool success, ) = msg.sender.call{value: collateral}("");
        require(success, "ETH transfer failed");

        emit Liquidated(user, msg.sender, debt, collateral);
    }


    function _registerUser(address user) internal {
        if (!isUser[user]) {
            isUser[user] = true;
            users.push(user);
        }
    }
    


    // 健康检查函数
    function _isHealthy(address user, uint256 collateralAmount, uint256 debtAmount) internal view returns (bool) {
        if (debtAmount == 0) return true;

        uint256 collateralValue = collateralAmount * ETH_PRICE / 1e18;
        uint256 ratio = (collateralValue * RATIO_DENOMINATOR) / debtAmount;
        return ratio >= MIN_COLLATERAL_RATIO;
    }

    
    function isLiquidatable(address user) public view returns (bool) {
        if (positions[user].debt == 0) return false;
        uint256 ratio = getCollateralRatio(user);
        return ratio < MIN_COLLATERAL_RATIO;
    }

    // 计算用户的抵押率
    function getCollateralRatio(address user) public view returns (uint256) {
        if (positions[user].debt == 0) return type(uint256).max;
        
        uint256 collateralValue = positions[user].collateral * ETH_PRICE / 1e18;
        return (collateralValue * RATIO_DENOMINATOR) / positions[user].debt;
    }
    
    // 获取用户可借款额度
    function getBorrowableAmount(address user) public view returns (uint256) {
        if (positions[user].collateral == 0) return 0;
        
        uint256 maxBorrowValue = (positions[user].collateral * ETH_PRICE * RATIO_DENOMINATOR) / MIN_COLLATERAL_RATIO;
        uint256 currentBorrowValue = positions[user].debt;
        
        if (maxBorrowValue > currentBorrowValue) {
            return maxBorrowValue - currentBorrowValue;
        }
        return 0;
    }
    
    // 获取合约ETH余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // 获取所有曾经交互过的用户
    function getAllUsers() external view returns (address[] memory) {
        return users;
    }

    // 获取合约稳定币余额
    function getContractStablecoinBalance() public view returns (uint256) {
        return stablecoin.balanceOf(address(this));
    }
    
    // 所有者向合约添加流动性
    function addLiquidity(uint256 amount) public onlyOwner {
        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
}