const { expect } = require("chai");
const { MaxUint256 } = require("ethers");
const { ethers } = require( "hardhat");

//HAQQ Mainnet
/*
const swapRouterAddress ="0xFB7eF66a7e61224DD6FcD0D7d9C3be5C8B049b9f";
const factoryAddress = "0xc35DADB65012eC5796536bD9864eD8773aBc74C4";
const wISLMAddress = "0xeC8CC083787c6e5218D86f9FF5f28d4cC377Ac54"
const wISLMWhale = "0x47097845D0bcA6BD60f7cC4Bf524c9964DbB3140"
*/

//Sepolia
const swapRouterAddress ="0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E";
const factoryAddress = "0x0227628f3F023bb0B980b67D528571c95c6DaC1c";
const wEthAddress = "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14"
const wEthWhale = "0x284cc50eb6C93c55BA4963D0dC5097C54db71580"


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
  const transferAmount = ethers.parseUnits("3", 18); // 1 Weth
  await Weth.connect(whaleSigner).transfer(owner.address, transferAmount);
});

describe("Test MemeFactory", function () {
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

  it("Create Meme", async function () {
    const ContractFactory = await ethers.getContractFactory("MemeFactory");
    const ContractMeme = await ethers.getContractFactory("ERC20MEME");

    const [owner] = await ethers.getSigners();
    
    const meme = await ContractMeme.deploy();
    await meme.waitForDeployment();

    const factory = await ContractFactory.deploy( await meme.getAddress(), 
                                                  swapRouterAddress, 
                                                  factoryAddress,
                                                  await getLiquidity.getAddress()
                                                );
    await factory.waitForDeployment();

    const wISLM = await ethers.getContractAt("IERC20", wEthAddress);
    await wISLM.approve(factory.getAddress(), MaxUint256);                                                     

    const tx = await factory.createERC20("Test", "Test", wEthAddress);
    const receipt = await tx.wait();
    //console.log("Events:", receipt.events || receipt.logs);

    const tokenAddress = await factory.memelist(1);
    const ERC20 = await ethers.getContractFactory("ERC20MEME");
    const tokenInstance = ERC20.attach(tokenAddress);

    expect(await tokenInstance.totalSupply()).to.equal(50);
  });

  it("Update Meme Implementation", async function () {
    const ContractFactory = await ethers.getContractFactory("MemeFactory");
    const ContractMemeV1 = await ethers.getContractFactory("ERC20MEME");
    const ContractMemeV2 = await ethers.getContractFactory("ERC20MEME_V2");

    const [owner] = await ethers.getSigners();
    
    // Деплой фабрики
    const meme_v1 = await ContractMemeV1.deploy();
    await meme_v1.waitForDeployment();

    const meme_v2 = await ContractMemeV2.deploy();
    await meme_v2.waitForDeployment();

    const meme_v3 = await ContractMemeV2.deploy();
    await meme_v3.waitForDeployment();

    const meme_vv = await ContractMemeV1.deploy();
    await meme_vv.waitForDeployment();
    

    const factory = await ContractFactory.deploy( await meme_v1.getAddress(),
                                                  swapRouterAddress, 
                                                  factoryAddress,
                                                  await getLiquidity.getAddress()
                                                );

    await factory.waitForDeployment();

    const wISLM = await ethers.getContractAt("IERC20", wEthAddress);
    await wISLM.approve(factory.getAddress(), MaxUint256);                                                 

    const tx = await factory.createERC20("Test1", "Test1", wEthAddress);
    const receipt = await tx.wait();

    console.log("meme:", await factory.memelist(1));
    //If wISLMAddress > factory.memelist(1) ошибка.... 
    console.log("meme:", wEthAddress > await factory.memelist(1));
   // console.log("Events:", receipt.events || receipt.logs);

    /*const tx2 = await factory.createERC20("Test2", "Test2", wISLMAddress);
    await tx2.wait();*/
/*

    '0x763e69d24a03c0c8B256e470D9fE9e0753504D07',
    62n,
    '0xeC8CC083787c6e5218D86f9FF5f28d4cC377Ac54',
    21168924598523902360n

    '0x763e69d24a03c0c8B256e470D9fE9e0753504D07',
    1000n,
    '0xeC8CC083787c6e5218D86f9FF5f28d4cC377Ac54',
    333333333000000000000n
    21168924598523902360n

    
    const tokenAddress = await factory.memelist(2);
    const ERC20 = await ethers.getContractFactory("ERC20MEME_V2");
    const tokenInstance = ERC20.attach(tokenAddress);*/

   /* const tx3 = await factory.updateImplementation(await meme_v2.getAddress());
    await tx3.wait();     */                                    

   // await tokenInstance.mint(owner, initialSupply);

   // expect(await tokenInstance.balanceOf(owner)).to.equal(initialSupply);

    //await tokenInstance.burn(initialSupply);

   // expect(await tokenInstance.totalSupply()).to.equal(initialSupply);
  });
})
