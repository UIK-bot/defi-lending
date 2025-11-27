# DeFi Lending — 全栈借贷项目

> 一个简单的 DeFi 借贷 / 抵押借贷应用  
> 包含智能合约 + 前端界面。合约使用 Hardhat + Solidity，前端使用 Next.js / React。

---

## 🧰 项目结构

project-root/
├── defi-lending                # 智能合约（Hardhat）
│   ├── contracts/
│   ├── scripts/
│   ├── test/
│   ├── hardhat.config.js
│   └── package.json
│
└── defi-lending-frontend       # 前端（Next.js + React + Wagmi）
    ├── src/
    ├── public/
    ├── package.json
    ├── next.config.js
    └── tailwind.config.js

## 🧩 技术栈
后端 / 智能合约

Solidity

Hardhat

Ethers.js

Local Hardhat Network

前端

Next.js 14

React

Wagmi v1.x

RainbowKit 连接钱包

TailwindCSS UI

## ✅ 环境与依赖要求

| 工具       | 版本                                                           |
| -------- | ------------------------------------------------------------ |
| Node.js  | **v24.11.1（已验证）**                                            |
| npm      | 推荐最新                                                         |
| Wagmi 套件 | wagmi@1.4.13 / @wagmi/core@1.4.13 / @wagmi/connectors@3.1.11 |


## 🚀 本地运行指南
一、准备项目

将两个项目放在同一目录下：

project/
   ├── defi-lending
   └── defi-lending-frontend


❗ 注意：不能将两个项目放在两层同名文件夹，否则 npm 会报错。

二、安装依赖
1. 安装前端依赖
cd defi-lending-frontend

npm install wagmi@1.4.13
npm install @wagmi/core@1.4.13
npm install @wagmi/connectors@3.1.11

npm install    # 安装其他依赖

2. 安装后端依赖
cd defi-lending
npm install

三、启动项目
步骤 1：启动 Hardhat 本地链
cd defi-lending
npx hardhat node

步骤 2：部署智能合约（新开一个终端）
cd defi-lending
npx hardhat run scripts/deploy.js --network localhost


部署成功后请确认前端已更新合约地址与 ABI。

步骤 3：启动前端界面（再开一个终端）
cd defi-lending-frontend
npm run dev


然后打开浏览器访问：

👉 http://localhost:3000

## ⚠️ 注意事项

运行应用时必须保持 三个终端同时运行：

Hardhat node

合约部署

前端 dev 服务

如果替换了 Lending.sol，必须重新执行：

npx hardhat compile
npx hardhat run scripts/deploy.js --network localhost


并更新前端 ABI。

## 📜 项目介绍（简短版）

支持抵押 ETH 借出 MockDAI

支持提取、还款、抵押取回

显示健康因子（Health Factor）

清算界面可检测仓位是否可被清算

清算按钮会模拟清算流程（若健康因子正常会提示 "Position is healthy"）