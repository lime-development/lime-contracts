const networks = {
  haqq: { name: "haqq", factory: "0xc35DADB65012eC5796536bD9864eD8773aBc74C4" },
  sepolia: { name: "sepolia", factory: "0x0227628f3F023bb0B980b67D528571c95c6DaC1c" },
  base: { name: "base", factory: "0x33128a8fC17869897dcE68Ed026d694621f6FDfD" },
  ethereum: { name: "ethereum", factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984" },
  bnb: { name: "bnb", factory: "0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7" }
};

async function main() {
  const ContractMEME = await ethers.getContractFactory("ERC20MEME");
  const ContractFactory = await ethers.getContractFactory("MemeFactory");
  const LiquidityFactory = await ethers.getContractFactory("getLiquidityHelper");
  
  const [initialOwner] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", initialOwner.address);

  if (!networks[hre.network.name]) {
    throw new Error(`Unsupported or missing network. Please specify a valid network (e.g., 'ethereum', 'sepolia', 'haqq', etc.)`);
  }

  const config = networks[hre.network.name];

  // Deploying LiquidityHelper contract
  const liquidityHelper = await LiquidityFactory.deploy();
  await liquidityHelper.waitForDeployment();
  console.log(`LiquidityHelper deployed to: ${await liquidityHelper.getAddress()}`);

  // Deploying ERC20MEME contract
  const meme = await ContractMEME.deploy();
  await meme.waitForDeployment();
  console.log(`ERC20MEME deployed to: ${await meme.getAddress()}`);

  // Deploying MemeFactory contract with the appropriate factory address based on network
  console.log("Deploy factory with Meme:", await meme.getAddress(), 
              " UniswapV3 Facrory:",config.factory,
              " liquidityHelper:", await liquidityHelper.getAddress());
  const instance = await upgrades.deployProxy(ContractFactory, [
    await meme.getAddress(),
    config.factory, // Используем адрес Uniswap v3 Factory для выбранной сети
    await liquidityHelper.getAddress()
  ]);
  await instance.waitForDeployment();
  console.log(`MemeFactory deployed to: ${await instance.getAddress()}`);
}

main().catch((error) => {
  console.error(error);
});
