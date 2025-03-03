const { expect } = require("chai");
const { MaxUint256 } = require("ethers");
const { ethers, upgrades } = require("hardhat");

const networks = {
  haqq: { name: "haqq", factory: "0xc35DADB65012eC5796536bD9864eD8773aBc74C4", token: "0xeC8CC083787c6e5218D86f9FF5f28d4cC377Ac54", whale: "0x6A0ea3a37711928e646d0B3258781EB8b7732D1d" },
  sepolia: { name: "sepolia", factory: "0x0227628f3F023bb0B980b67D528571c95c6DaC1c", token: "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14", whale: "0xBaEb92889696217A3A6be2175E5a95dC4cFFC9f7" },
  base: { name: "base", factory: "0x33128a8fC17869897dcE68Ed026d694621f6FDfD", token: "0x4200000000000000000000000000000000000006", whale: "0x621e7c767004266c8109e83143ab0Da521B650d6" },
  ethereum: { name: "ethereum", factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984", token: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", whale: "0x6B44ba0a126a2A1a8aa6cD1AdeeD002e141Bcd44" },
  bnb: { name: "bnb", factory: "0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7", token: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", whale: "0x308000D0169Ebe674B7640f0c415f44c6987d04D" }
};

let factoryAddress, WrapToken, owner;

async function getTokenMetrics(newMEME, amount) {
  const decimals = BigInt(10) ** await newMEME.decimals();
  tokens = BigInt(amount) * decimals;
  const [initCost] = await newMEME.calculatePrice(decimals);
  const [cost_, fee] = await newMEME.calculatePrice(tokens);
  const [nextCost] = await newMEME.calculatePrice(tokens + decimals);

  const islmPrice = BigInt(33070);
  const islmPriceDiv = BigInt(10**6);

  const price = ((nextCost - cost_) * islmPrice) / islmPriceDiv;
  const initPrice = initCost * islmPrice / islmPriceDiv;
  const marketCap = price * BigInt(amount);
  const feeUSD = (fee * islmPrice) / islmPriceDiv;
  const costUSD = (cost_ * islmPrice) / islmPriceDiv;
  const growth = (BigInt(100)*price / initPrice - BigInt(100))*BigInt(100);

  console.log(
    "Minted:", amount,
    "; Total spent:", ethers.formatUnits(feeUSD + costUSD, 18),
    "; Token price:", ethers.formatUnits(price, 18), "USD",
    "; Growth:", ethers.formatUnits(growth, 2), "%",
    "; Market cap:", ethers.formatUnits(marketCap, 18), "USD",
    "; Total fee:", ethers.formatUnits(feeUSD, 18), "USD"
  );

  return { totalSpent: cost_ + fee, tokenPrice: price, marketCap };
}

async function getERC20Created(receipt) {
  const contractInterface = new ethers.Interface(["event ERC20Created(address tokenAddress)"]);
  
  for (const log of receipt.logs) {
    try {
      const parsedLog = contractInterface.parseLog(log);
      if (parsedLog.name === "ERC20Created") return parsedLog.args[0];
    } catch (_) {}
  }
  return null;
}

async function setupNetwork(config) {
  console.log(`${config.name} fork config`);
  factoryAddress = config.factory;
  WrapToken = config.token;

  const payToken = await ethers.getContractAt("ERC20", WrapToken);
  await ethers.provider.send("hardhat_impersonateAccount", [config.whale]);
  const whaleSigner = await ethers.getSigner(config.whale);
  await payToken.connect(whaleSigner).transfer(owner.address, ethers.parseUnits("1350", 18));
}

before(async function () {
  [owner] = await ethers.getSigners();
  await setupNetwork(networks[process.env.NETWORK] || networks.sepolia);

  const wrapedToken = await ethers.getContractAt("IERC20", WrapToken);
  console.log("Owner:", owner.address, "Balance:", await wrapedToken.balanceOf(owner.address));

  const LiquidityFactory = await ethers.getContractFactory("getLiquidityHelper");
  getLiquidity = await LiquidityFactory.deploy();
  await getLiquidity.waitForDeployment();
 
  const ContractMeme = await ethers.getContractFactory("ERC20MEME");
  meme = await ContractMeme.deploy();
  await meme.waitForDeployment();

  const config = {
    factory: factoryAddress,
    getLiquidity: await getLiquidity.getAddress(),
    initialSupply: BigInt(1000000) * await meme.decimals(),
    protocolFee: 2500,
    initialMintCost: ethers.parseUnits("0.02", "ether"),
    divider: 300,
    pool: {
        fee: 3000,
        tickSpacing: 60,
        minTick: -887272,
        maxTick: 887272
    }
};

  MemeFactory = await ethers.getContractFactory("MemeFactory");
  factory = await upgrades.deployProxy( MemeFactory,
    [await meme.getAddress(), config]
  );
  await factory.waitForDeployment();
  await wrapedToken.approve(await factory.getAddress(), MaxUint256);
});

describe("Test MemeFactory", function () {
  it("Deploy factory", async function () {
    expect(await factory.implementation()).to.equal(await meme.getAddress());
  });

  it("Create Meme", async function () {
    const tx = await factory.createERC20("Test", "Test", WrapToken);
    const receipt = await tx.wait();
    const meme = await getERC20Created(receipt);
    const newMEME = await ethers.getContractAt("ERC20MEME", meme);
    const poolBalance = await newMEME.balanceOf(newMEME.pool());
    const memeBalance = await newMEME.balanceOf(meme);
    expect(poolBalance).to.be.gt((await factory.getConfig()).initialSupply*BigInt(99)/BigInt(100));
    expect(memeBalance+poolBalance).to.equal((await factory.getConfig()).initialSupply);
  });
  /*
  it("Math test", async function () {
    const wISLM = await ethers.getContractAt("IERC20", WrapToken);
    await wISLM.approve(factory.getAddress(), MaxUint256);

    const tx = await factory.createERC20("Test", "Test", WrapToken);
    const receipt = await tx.wait();
    const meme = await getERC20Created(receipt);
    const newMEME = await ethers.getContractAt("ERC20MEME", meme);
  
    for (let amount = BigInt(1000); amount < BigInt(100000000); amount=amount*BigInt(5)) {
      await getTokenMetrics(newMEME, amount, ethers);
    }
  });*/

  it("Mint Meme ", async function () {
    const tx = await factory.createERC20("Test", "Test", WrapToken);
    const receipt = await tx.wait();
    const meme = await getERC20Created(receipt);
    const newMEME = await ethers.getContractAt("ERC20MEME", meme);
 
    const wrapedToken = await ethers.getContractAt("IERC20", WrapToken);
    await wrapedToken.approve(await newMEME.getAddress(), MaxUint256);
    const amount = BigInt(1000) * BigInt(10) ** await newMEME.decimals(); //1000*10^decimals
    const Try =  BigInt(100);
    for (let mintTry = 0; mintTry < Try; mintTry++) {
      await newMEME.mint(owner, amount);
    }
    expect(await newMEME.balanceOf(owner)).to.equal(amount*Try);
    const balanceBefore = await wrapedToken.balanceOf(await factory.getAddress());
    await factory.collectPoolFees(await newMEME.getAddress());
    await factory.collectPoolsFees();
    const balanceAfter = await wrapedToken.balanceOf(await factory.getAddress());
    expect(balanceAfter).to.be.gt(balanceBefore);
  });

  it("Update Meme Implementation", async function () {
    const ContractMemeV1 = await ethers.getContractFactory("ERC20MEME");
    const ContractMemeV2 = await ethers.getContractFactory("ERC20MEMEV2");

    const meme_v1 = await ContractMemeV1.deploy();
    await meme_v1.waitForDeployment();

    const meme_v2 = await ContractMemeV2.deploy();
    await meme_v2.waitForDeployment();

    const tx = await factory.createERC20("Test1", "Test1", WrapToken);
    const receipt = await tx.wait();
    const meme = await getERC20Created(receipt);
    const mem_v1 = await ethers.getContractAt("ERC20MEME", meme);
    const value_v1 = await mem_v1.calculateValue(10000);

    const tx2 = await factory.updateImplementation(await meme_v2.getAddress());
    await tx2.wait();
    expect(await factory.implementation()).to.equal(await meme_v2.getAddress());

    const tx3 = await factory.updateTokens();
    await tx3.wait();

    const value_v2 = await mem_v1.calculateValue(10000);
    expect(value_v1).to.not.equal(value_v2);
  });

  it("Update factory", async function () {
    MemeFactoryV2 = await ethers.getContractFactory("MemeFactoryV2");
    factory = await upgrades.upgradeProxy(await factory.getAddress(), MemeFactoryV2);
    expect(await factory.version()).to.equal("2.1.0");

    const [_, nonOwner] = await ethers.getSigners();
    const nonOwnerFactory = await ethers.getContractAt("MemeFactoryV2", await factory.getAddress(), nonOwner);
   
    try {
      await nonOwnerFactory.upgradeProxy(await nonOwnerFactory.getAddress(), MemeFactory);
      assert.fail("Non-owner should not be able to upgrade the contract");
    } catch (error) {
      
    }
    expect(await nonOwnerFactory.version()).to.equal("2.1.0");
  });
})
