const { expect } = require("chai");
const { MaxUint256 } = require("ethers");
const { ethers } = require("hardhat");

//HAQQ Mainnet
/*
const swapRouterAddress ="0xFB7eF66a7e61224DD6FcD0D7d9C3be5C8B049b9f";
const factoryAddress = "0xc35DADB65012eC5796536bD9864eD8773aBc74C4";
const wISLMAddress = "0xeC8CC083787c6e5218D86f9FF5f28d4cC377Ac54"
const wISLMWhale = "0x47097845D0bcA6BD60f7cC4Bf524c9964DbB3140"
*/

//Sepolia
const swapRouterAddress = "0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E";
const factoryAddress = "0x0227628f3F023bb0B980b67D528571c95c6DaC1c";
const wEthAddress = "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14"
const wEthWhale = "0xBaEb92889696217A3A6be2175E5a95dC4cFFC9f7"


before(async function () {
  [owner] = await ethers.getSigners();
  const LiquidityFactory = await ethers.getContractFactory("getLiquidityHelper");
  getLiquidity = await LiquidityFactory.deploy();
  await getLiquidity.waitForDeployment();
  /*//Get wISLM 
  const wISLM = await ethers.getContractAt("IERC20", wISLMAddress);
  await ethers.provider.send("hardhat_impersonateAccount", [wISLMWhale]);
  const whaleSigner = await ethers.getSigner(wISLMWhale);
  const whaleBalanceBefore = await wISLM.balanceOf(wISLMWhale);
  const transferAmount = ethers.parseUnits("1000", 18); // 1000 wISLM
  await wISLM.connect(whaleSigner).transfer(owner.address, transferAmount); */

  //Get wISLM 
  const Weth = await ethers.getContractAt("IERC20", wEthAddress);
  await ethers.provider.send("hardhat_impersonateAccount", [wEthWhale]);
  const whaleSigner = await ethers.getSigner(wEthWhale);
  const transferAmount = ethers.parseUnits("312", 18); // 1 Weth
  await Weth.connect(whaleSigner).transfer(owner.address, transferAmount);
});

describe("Test MemeFactory", function () {
  this.timeout(4000000);
  it("Deploy", async function () {
    const ContractFactory = await ethers.getContractFactory("MemeFactory");
    const ContractMeme = await ethers.getContractFactory("ERC20MEME");

    const meme = await ContractMeme.deploy();
    await meme.waitForDeployment();

    const initialOwner = (await ethers.getSigners())[0].address;
    const instance = await ContractFactory.deploy(await meme.getAddress(),
      swapRouterAddress,
      factoryAddress,
      await getLiquidity.getAddress()
    );
    await instance.waitForDeployment();
    expect(await instance.implementation()).to.equal(await meme.getAddress());
  });
  /*
    it("Manual liquidity test", async function () {
      const liquidityHelper = await ethers.getContractFactory("getLiquidityHelper");
      const iquidity = await liquidityHelper.deploy();
      await iquidity.waitForDeployment();
  
      const wISLM = await ethers.getContractAt("IERC20", wEthAddress);
  
      const MyTokenUpgradeable = await ethers.getContractFactory("ERC20MEME");
      logic = await MyTokenUpgradeable.deploy();
      await logic.waitForDeployment();
  
      const TransparentUpgradeableProxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
      const proxyAdmin = owner.address; // Админ прокси
      const initialSupply = 1000000;
      const initData = logic.interface.encodeFunctionData("initialize",
        ["MyToken", "MTK", initialSupply, await iquidity.getAddress()]);
  
  
      proxy = await TransparentUpgradeableProxy.deploy(
        await logic.getAddress(),
        proxyAdmin,
        initData
      );
      await proxy.waitForDeployment();
  
      token = await MyTokenUpgradeable.attach(await proxy.getAddress());
  
      await wISLM.approve(token.getAddress(), MaxUint256);
      await token.initializePool(await wISLM.getAddress());
      pool = await token.pool();
      expect(await token.balanceOf(pool)).to.equal(initialSupply);
  
    });
  */

  it("Create Meme", async function () {
    const ContractFactory = await ethers.getContractFactory("MemeFactory");
    const ContractMeme = await ethers.getContractFactory("ERC20MEME");

    const [owner] = await ethers.getSigners();

    const meme = await ContractMeme.deploy();
    await meme.waitForDeployment();

    const factory = await ContractFactory.deploy(await meme.getAddress(),
      swapRouterAddress,
      factoryAddress,
      await getLiquidity.getAddress()
    );

    await factory.waitForDeployment();
    const wISLM = await ethers.getContractAt("IERC20", wEthAddress);
    await wISLM.approve(factory.getAddress(), MaxUint256);
    await wISLM.transfer(factory.getAddress(), ethers.parseUnits("1", 18));
    const tx = await factory.createERC20("Test", "Test", wEthAddress);
    const receipt = await tx.wait();
    const newMEME = await ethers.getContractAt("ERC20MEME", await factory.memelist(1));
    //console.log("Meme Meme balance", await newMEME.balanceOf(newMEME.getAddress()));  
    //console.log("Meme wETH balance", await wISLM.balanceOf(newMEME.getAddress())); 
    //console.log("Pool Meme balance", );  
    //console.log("Pool wETH balance", await wISLM.balanceOf(newMEME.pool())); 
    expect(await newMEME.balanceOf(newMEME.pool())).to.equal((await factory.getConfig()).initialSupply);
  });

  it("Update Meme Implementation", async function () {
    const ContractFactory = await ethers.getContractFactory("MemeFactory");
    const ContractMemeV1 = await ethers.getContractFactory("ERC20MEME");
    const ContractMemeV2 = await ethers.getContractFactory("ERC20MEME_V2");

    const [owner] = await ethers.getSigners();

    const meme_v1 = await ContractMemeV1.deploy();
    await meme_v1.waitForDeployment();

    const meme_v2 = await ContractMemeV2.deploy();
    await meme_v2.waitForDeployment();

    const factory = await ContractFactory.deploy(await meme_v1.getAddress(),
      swapRouterAddress,
      factoryAddress,
      await getLiquidity.getAddress()
    );

    await factory.waitForDeployment();

    const wISLM = await ethers.getContractAt("IERC20", wEthAddress);
    await wISLM.approve(factory.getAddress(), MaxUint256);
    await wISLM.transfer(factory.getAddress(), ethers.parseUnits("1", 18));

    const tx = await factory.createERC20("Test1", "Test1", wEthAddress);
    const receipt = await tx.wait();
    const mem_v1 = await ethers.getContractAt("ERC20MEME", await factory.memelist(1));
    expect(await mem_v1.balanceOf(mem_v1.pool())).to.equal((await factory.getConfig()).initialSupply);

    const tx2 = await factory.createERC20("Test2", "Test2", wEthAddress);
    await tx2.wait();
    const mem_v2 = await ethers.getContractAt("ERC20MEME", await factory.memelist(2));
    expect(await mem_v2.balanceOf(mem_v2.pool())).to.equal((await factory.getConfig()).initialSupply);

    const tokenAddress = await factory.memelist(2);
    const ERC20 = await ethers.getContractFactory("ERC20MEME_V2");
    const tokenInstance = ERC20.attach(tokenAddress);

    const tx3 = await factory.updateImplementation(await meme_v2.getAddress());
    await tx3.wait();
    expect(await factory.implementation()).to.equal(await meme_v2.getAddress());
  });
})
