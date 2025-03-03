const { expect } = require("chai");
const { MaxUint256 } = require("ethers");
const { ethers, upgrades } = require("hardhat");
const { poolConfig, networks } = require("../scripts/config");

let factoryAddress, WrapToken, owner;

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

async function setupNetwork(config) {
  console.log(`${config.name} fork config`);
  WrapToken = config.token;

  const payToken = await ethers.getContractAt("ERC20", WrapToken);
  await ethers.provider.send("hardhat_impersonateAccount", [config.whale]);
  const whaleSigner = await ethers.getSigner(config.whale);
  await payToken.connect(whaleSigner).transfer(owner.address, ethers.parseUnits("1350", 18));

  const LiquidityFactory = await ethers.getContractFactory("getLiquidityHelper");
  getLiquidity = await LiquidityFactory.deploy();
  await getLiquidity.waitForDeployment();

  const ContractMeme = await ethers.getContractFactory("ERC20MEME");
  meme = await ContractMeme.deploy();
  await meme.waitForDeployment();

  const factoryConfig = {
    factory: config.factory,
    getLiquidity: await getLiquidity.getAddress(),
    initialSupply: config.initialSupply,
    protocolFee: 2500,
    initialMintCost: config.initialMintCost,
    divider: config.divider,
    pool: poolConfig
  };
  return factoryConfig
}

before(async function () {
  [owner] = await ethers.getSigners();
  const config = await setupNetwork(networks[process.env.NETWORK] || networks.sepolia);
  MemeFactory = await ethers.getContractFactory("MemeFactory");
  factory = await upgrades.deployProxy(MemeFactory,
    [await meme.getAddress(), config]
  );
  await factory.waitForDeployment();

  const wrapedToken = await ethers.getContractAt("ERC20", WrapToken);
  console.log("Owner:", owner.address, "Balance:", await wrapedToken.balanceOf(owner.address));
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
    expect(poolBalance).to.be.gt((await factory.getConfig()).initialSupply * BigInt(99) / BigInt(100));
    expect(memeBalance + poolBalance).to.equal((await factory.getConfig()).initialSupply);
  });

  it("Mint Meme ", async function () {
    const tx = await factory.createERC20("Test", "Test", WrapToken);
    const receipt = await tx.wait();
    const meme = await getERC20Created(receipt);
    const newMEME = await ethers.getContractAt("ERC20MEME", meme);

    const wrapedToken = await ethers.getContractAt("IERC20", WrapToken);
    await wrapedToken.approve(await newMEME.getAddress(), MaxUint256);
    const amount = BigInt(1000) * BigInt(10) ** await newMEME.decimals(); //1000*10^decimals
    const Try = BigInt(1);
    for (let mintTry = 0; mintTry < Try; mintTry++) {
      await newMEME.mint(owner, amount);
    }
    expect(await newMEME.balanceOf(owner)).to.equal(amount * Try);
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
