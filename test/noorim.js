const { expect } = require("chai");
const { ethers } = require( "hardhat");


describe("Test MemeFactory", function () {
  it("Deploy", async function () {
    const ContractFactory = await ethers.getContractFactory("MemeFactory");
    const ContractMeme = await ethers.getContractFactory("ERC20MEME");

    const meme = await ContractMeme.deploy();
    await meme.waitForDeployment();

    const initialOwner = (await ethers.getSigners())[0].address;
    const instance = await ContractFactory.deploy(await meme.getAddress());
    await instance.waitForDeployment();
    expect(await instance.implementation()).to.equal(await meme.getAddress());
  });

  it("Create Meme", async function () {
    const ContractFactory = await ethers.getContractFactory("MemeFactory");
    const ContractMeme = await ethers.getContractFactory("ERC20MEME");

    const [owner] = await ethers.getSigners();
    
    // Деплой фабрики
    const meme = await ContractMeme.deploy();
    await meme.waitForDeployment();

    const factory = await ContractFactory.deploy(await meme.getAddress());
    await factory.waitForDeployment();

    const initialSupply = 10;

    // Создание токена
    const tx = await factory.createERC20("Test", "Test", initialSupply);
    await tx.wait();

    // Получение адреса созданного токена
    const tokenAddress = await factory.memelist(1);
    const ERC20 = await ethers.getContractFactory("ERC20MEME");
    const tokenInstance = ERC20.attach(tokenAddress);

    // Проверка totalSupply
    expect(await tokenInstance.totalSupply()).to.equal(initialSupply);
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

    const factory = await ContractFactory.deploy(await meme_v1.getAddress());
    await factory.waitForDeployment();

    const initialSupply = 10;

    // Создание токена
    const tx = await factory.createERC20("Test1", "Test1", initialSupply);
    await tx.wait();

    const tx2 = await factory.createERC20("Test2", "Test2", initialSupply);
    await tx2.wait();

    // Получение адреса созданного токена
    const tokenAddress = await factory.memelist(2);
    const ERC20 = await ethers.getContractFactory("ERC20MEME_V2");
    const tokenInstance = ERC20.attach(tokenAddress);

    await factory.updateImplementation(await meme_v2.getAddress());
    await tx2.wait();

    await tokenInstance.mint(owner, initialSupply);

    expect(await tokenInstance.balanceOf(owner)).to.equal(initialSupply);

    await tokenInstance.burn(initialSupply);

    // Проверка totalSupply
    expect(await tokenInstance.totalSupply()).to.equal(initialSupply);
  });
})
