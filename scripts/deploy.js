const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // 1. 部署 MockDAI
  const MockDAI = await hre.ethers.getContractFactory("MockDAI");
  const mockDAI = await MockDAI.deploy();
  await mockDAI.waitForDeployment();
  const mockDAIAddress = await mockDAI.getAddress();
  console.log("MockDAI deployed at:", mockDAIAddress);

  // 2. 部署 Lending (构造参数为 MockDAI 地址)
  const Lending = await hre.ethers.getContractFactory("Lending");
  const lending = await Lending.deploy(mockDAIAddress);
  await lending.waitForDeployment();
  const lendingAddress = await lending.getAddress();
  console.log("Lending contract deployed at:", lendingAddress);

  // 3. 给 Lending 注入流动性（10000 mDAI）
  const liquidityAmount = hre.ethers.parseUnits("10000", 18);
  const tx1 = await mockDAI.approve(lendingAddress, liquidityAmount);
  await tx1.wait();

  const tx2 = await lending.addLiquidity(liquidityAmount);
  await tx2.wait();

  console.log("Liquidity added:", liquidityAmount.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
