const { ethers } = require("hardhat");
const { poolConfig, networks } = require("./config");

async function getERC20Created(receipt) {
    const contractInterface = new ethers.Interface(["event ERC20Created(address tokenAddress, address author)"]);
  
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
  [owner, second] = await ethers.getSigners();
  factoryAddress = config.factory;
  WrapToken = config.token;

  const LiquidityFactory = await ethers.getContractFactory("getLiquidityHelper");
  getLiquidity = await LiquidityFactory.deploy();
  await getLiquidity.waitForDeployment();

  const factoryConfig = {
    factory: factoryAddress,
    getLiquidity: await getLiquidity.getAddress(),
    initialSupply: config.initialSupply,
    protocolFee: config.protocolFee,
    authorFee: config.authorFee,
    initialMintCost: config.initialMintCost,
    divider: config.divider,
    pool: poolConfig
  };
  return factoryConfig
}

async function addBalance(address, amount) {
  let currentBalance = BigInt(await ethers.provider.getBalance(address));
  let newBalance = currentBalance+BigInt(amount);
  await network.provider.send("hardhat_setBalance", [
    address,
    "0x" + newBalance.toString(16)
  ]);
}

async function getWRAP(config) {
  const [owner, second] = await ethers.getSigners();
  const WETH = await ethers.getContractAt("IWETH9", config.token);
 
  const amountOwner = config.requestedOwnerTokenAmounts;
  const amountSecond = config.requestedAuthorTokenAmounts;

  console.log(`Adding ${amountOwner} ETH to owner (${owner.address})`);
  await addBalance(owner.address, amountOwner);
  console.log(`Owner balance after funding: ${await ethers.provider.getBalance(owner.address)}`);

  console.log(`Adding ${amountSecond} ETH to second (${second.address})`);
  await addBalance(second.address, amountSecond);
  console.log(`Second balance after funding: ${await ethers.provider.getBalance(second.address)}`);

  console.log(`Depositing ${amountOwner} ETH to WETH contract`);
  await WETH.connect(owner).deposit({ value: amountOwner });

  console.log(`Depositing ${amountSecond} ETH to WETH contract`);
  await WETH.connect(second).deposit({ value: amountSecond });

  const balanceOwner = await WETH.balanceOf(owner.address);
  const balanceSecond = await WETH.balanceOf(second.address);
  console.log(`Final Owner's WETH balance: ${balanceOwner}`);
  console.log(`Final Second's WETH balance: ${balanceSecond}`);
}

module.exports = { setupNetwork, getERC20Created, getTokenPrice, getWRAP};  
