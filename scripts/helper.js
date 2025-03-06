const { ethers } = require("hardhat");
const { poolConfig, networks } = require("./config");

async function getERC20Created(receipt) {
    const contractInterface = new ethers.Interface(["event ERC20Created(address tokenAddress)"]);
  
    for (const log of receipt.logs) {
      try {
        const parsedLog = contractInterface.parseLog(log);
        if (parsedLog.name === "ERC20Created") return parsedLog.args[0];
      } catch (_) { }
    }
    return null;
  }

  async function getTokenPrice(token, chain) {
    if(chain == 11155111) return 10 ** 6;
    const api = String("https://api.sushi.com/price/v1/" + chain);
    console.log(api);
    try {
        const response = await fetch(api);
        const data = await response.json();
        
        if (data[token]) {
            const price = data[token];
            const scaledPrice = Math.floor(price * 10**6);
            console.log(`Price of token ${token} * 10^6:`, scaledPrice);
            return scaledPrice;
        } else {
            console.log(`Token ${token} not found in API response.`);
            return null;
        }
    } catch (error) {
        console.error('Error fetching token price:', error);
        return null;
    }
}

async function setupNetwork(config) {
  console.log(`${config.name} fork config`);
  [owner] = await ethers.getSigners();
  factoryAddress = config.factory;
  WrapToken = config.token;

  const payToken = await ethers.getContractAt("ERC20", config.token);
  await ethers.provider.send("hardhat_impersonateAccount", [config.whale]);
  const whaleSigner = await ethers.getSigner(config.whale);
  const amount = ethers.parseUnits("1350", 18);
  const whaleBalance =  await payToken.balanceOf(config.whale);
  if(amount>whaleBalance){
    console.error("Whale don't have balance");
  }
  await payToken.connect(whaleSigner).transfer(owner.address, ethers.parseUnits("1350", 18));

  const LiquidityFactory = await ethers.getContractFactory("getLiquidityHelper");
  getLiquidity = await LiquidityFactory.deploy();
  await getLiquidity.waitForDeployment();

  const factoryConfig = {
    factory: factoryAddress,
    getLiquidity: await getLiquidity.getAddress(),
    initialSupply: config.initialSupply,
    protocolFee: config.protocolFee,
    initialMintCost: config.initialMintCost,
    divider: config.divider,
    pool: poolConfig
  };
  return factoryConfig
}

module.exports = { setupNetwork, getERC20Created, getTokenPrice };  