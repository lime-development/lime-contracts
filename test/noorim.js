const { expect } = require("chai");
const { MaxUint256 } = require("ethers");
const { ethers, upgrades } = require("hardhat");
const { bigint } = require("hardhat/internal/core/params/argumentTypes");

let swapRouterAddress; 
let factoryAddress;
let WrapToken;

async function getTokenMetrics(newMEME, amount, ethers) {
  // Get total cost and fee
  const [initCost, _] = await newMEME.calculatePrice(1);
  const [cost_, fee] = await newMEME.calculatePrice(amount);

  // Get the cost for amount + 1
  const [tmp] = await newMEME.calculatePrice(amount + BigInt(1));

  const islmPrice = BigInt(37);
  const islmPriceDiv = BigInt(1000);

  // Calculate token price (per unit)
  initPrice = (initCost * islmPrice) / islmPriceDiv;
  const price = ((tmp - cost_) * islmPrice) / islmPriceDiv;

  // Get total supply and calculate market cap
  const marketCap = (price * amount);
  const feeUSD = fee * islmPrice / islmPriceDiv;

  const grow = (tmp - cost_) * BigInt(10000) / initCost  - BigInt(10000)

  //const incPrice = price * BigInt(100)/ initPrice;

  console.log("Minted:" , amount,
              "; Total spent:", ethers.formatUnits(cost_ + fee, 18), 
              "; Token price:", ethers.formatUnits(price, 18), "USD", 
              "; grow :", ethers.formatUnits(grow,2), "%", 
              "; Market cap:", ethers.formatUnits(marketCap, 18), "USD",
              "; Total fee:", ethers.formatUnits(feeUSD, 18), "USD"
            );

  return { totalSpent: cost_ + fee, tokenPrice: price, marketCap };
}

async function getERC20Created(receipt){
  const contractInterface = new ethers.Interface(["event ERC20Created(address tokenAddress)"]);

  const erc20CreatedEvents = receipt.logs.map(log => {
    try {
      const parsedLog = contractInterface.parseLog(log);
      if (parsedLog.name === "ERC20Created") {
        return parsedLog.args[0]; // Забираем сам `tokenAddress`
      }
    } catch (error) {
      return null;
    }
  }).filter(address => address !== null);

  return  erc20CreatedEvents[0];
}

async function sepolia(){
  console.log("sepolia fork config");
  swapRouterAddress = "0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E";
  factoryAddress = "0x0227628f3F023bb0B980b67D528571c95c6DaC1c";
  WrapToken = "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14"

  const wEthWhale = "0xBaEb92889696217A3A6be2175E5a95dC4cFFC9f7"
  const wETH = await ethers.getContractAt("ERC20", WrapToken);
  await ethers.provider.send("hardhat_impersonateAccount", [wEthWhale]);
  const whaleSigner = await ethers.getSigner(wEthWhale);
  const transferAmount = ethers.parseUnits("1350", 18); // 1350 wETH
  const tx = await wETH.connect(whaleSigner).transfer(owner.address, transferAmount);
}

async function haqq(){
  console.log("haqq fork config");
  swapRouterAddress = "0xFB7eF66a7e61224DD6FcD0D7d9C3be5C8B049b9f";
  factoryAddress = "0xc35DADB65012eC5796536bD9864eD8773aBc74C4";
  WrapToken = "0xeC8CC083787c6e5218D86f9FF5f28d4cC377Ac54"

  const wISLMWhale = "0x6A0ea3a37711928e646d0B3258781EB8b7732D1d"
  const wISLM = await ethers.getContractAt("ERC20", WrapToken);
  await ethers.provider.send("hardhat_impersonateAccount", [wISLMWhale]);
  const whaleSigner = await ethers.getSigner(wISLMWhale);
  const transferAmount = ethers.parseUnits("1350", 18); // 1000 wISLM
  const tx = await wISLM.connect(whaleSigner).transfer(owner.address, transferAmount);
}


before(async function () {
  [owner] = await ethers.getSigners();
  const network = process.env.NETWORK 
  switch (network) {
    case "haqq":
      await haqq();
      break;
    case "sepolia":
      await sepolia();
      break;
    default:
      await sepolia();
  }
  
  const wrapedToken = await ethers.getContractAt("IERC20", WrapToken);
  const wrapBalance = await wrapedToken.balanceOf(owner.address);
  const gasBalance = await ethers.provider.getBalance(owner.address);
  console.log("Owner:", owner.address, "wrapBalance:", wrapBalance, "gasBalance:", gasBalance);

  const LiquidityFactory = await ethers.getContractFactory("getLiquidityHelper");
  getLiquidity = await LiquidityFactory.deploy();
  await getLiquidity.waitForDeployment();
 
  const ContractMeme = await ethers.getContractFactory("ERC20MEME");
  meme = await ContractMeme.deploy();
  await meme.waitForDeployment();

  MemeFactory = await ethers.getContractFactory("MemeFactory");
  factory = await upgrades.deployProxy( MemeFactory,
    [await meme.getAddress(), swapRouterAddress, factoryAddress, await getLiquidity.getAddress()]
  );
  await factory.waitForDeployment();

  await wrapedToken.approve(factory.getAddress(), MaxUint256);
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
    expect(await newMEME.balanceOf(newMEME.pool())).to.equal((await factory.getConfig()).initialSupply);
  });
  /*
  it("Math test", async function () {
    const wISLM = await ethers.getContractAt("IERC20", WrapToken);
    await wISLM.approve(factory.getAddress(), MaxUint256);

    const tx = await factory.createERC20("Test", "Test", WrapToken);
    const receipt = await tx.wait();
    const meme = await getERC20Created(receipt);
    const newMEME = await ethers.getContractAt("ERC20MEME", meme);
  
    for (let amount = BigInt(1000); amount < BigInt(100000000000); amount=amount*BigInt(10)) {
      await getTokenMetrics(newMEME, amount, ethers);
    }
  });*/
  
  it("Mint Meme ", async function () {
    const tx = await factory.createERC20("Test", "Test", WrapToken);
    const receipt = await tx.wait();
    const meme = await getERC20Created(receipt);
    const newMEME = await ethers.getContractAt("ERC20MEME", meme);
    expect(await newMEME.balanceOf(newMEME.pool())).to.equal((await factory.getConfig()).initialSupply);

    const wrapedToken = await ethers.getContractAt("IERC20", WrapToken);
    await wrapedToken.approve(await newMEME.getAddress(), MaxUint256);
    const amount = 1000000;
    const Try = 100;
    for (let mintTry = 0; mintTry < Try; mintTry++) {
      await newMEME.mint(owner, amount);
    }
    expect(await newMEME.balanceOf(owner)).to.equal(amount*Try);
    await factory.createERC20("Test2", "Test2", WrapToken);
    await factory.createERC20("Test3", "Test3", WrapToken);
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
    expect(await mem_v1.balanceOf(mem_v1.pool())).to.equal((await factory.getConfig()).initialSupply);

    const tx2 = await factory.createERC20("Test2", "Test2", WrapToken);
    const receipt2 = await tx2.wait();
    const meme2 = await getERC20Created(receipt2);
    const mem_v2 = await ethers.getContractAt("ERC20MEME", meme2);
    expect(await mem_v2.balanceOf(mem_v2.pool())).to.equal((await factory.getConfig()).initialSupply);

    const ERC20 = await ethers.getContractFactory("ERC20MEMEV2");
    const tokenInstance = ERC20.attach(meme2);

    const tx3 = await factory.updateImplementation(await meme_v2.getAddress());
    await tx3.wait();
    expect(await factory.implementation()).to.equal(await meme_v2.getAddress());

    const tx4 = await factory.updateTokens();
    await tx4.wait();
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
