const { poolConfig, networks } = require("./config");

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

  const factoryConfig = {
    factory: config.factory,
    getLiquidity: await liquidityHelper.getAddress(),
    initialSupply: config.initialSupply,
    protocolFee: config.protocolFee,
    initialMintCost: config.initialMintCost,
    divider: config.divider,
    pool: poolConfig
  };
  const instance = await upgrades.deployProxy(ContractFactory, [await meme.getAddress(), factoryConfig]);
  await instance.waitForDeployment();
  console.log(`MemeFactory deployed to: ${await instance.getAddress()}`);
}

main().catch((error) => {
  console.error(error);
});
