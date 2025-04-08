const { expect } = require("chai");
const { MaxUint256 } = require("ethers");
const { ethers, upgrades, hre } = require("hardhat");
const { poolConfig, networks } = require("../scripts/config");
const { setupNetwork, getERC20Created, getTokenPrice, getWRAP} = require("../scripts/helper");
const fs = require('fs');

async function getTokenMetrics(newMEME, amount, tokenPrice ) {
  const decimals = BigInt(10) ** await newMEME.decimals();
  tokens = BigInt(amount) * decimals;
  const [initCost] = await newMEME.calculatePrice(decimals);
  const [cost_, platformFee, authorRevenue] = await newMEME.calculatePrice(tokens);
  const [nextCost] = await newMEME.calculatePrice(tokens + decimals);

  const tokenPriceDiv = BigInt(10 ** 6);

  const price = ((nextCost - cost_) * tokenPrice) / tokenPriceDiv;
  const initPrice = initCost * tokenPrice / tokenPriceDiv;
  const marketCap = price * BigInt(amount);
  const platformFeeUSD = (platformFee * tokenPrice) / tokenPriceDiv;
  const authorRevenueUSD = (authorRevenue * tokenPrice) / tokenPriceDiv;
  const growth = (BigInt(100) * price / initPrice - BigInt(100)) * BigInt(100);

  const metrics = {
      marketCap: (Number(marketCap) / 1e18).toFixed(2),
      price: (Number(price) / 1e18).toFixed(6),
      priceGrowth: (Number(growth) / 100).toFixed(2), 
      totalSupply: amount.toString(),
      tokenSpend: (Number(platformFeeUSD + authorRevenueUSD + cost_) / 1e18).toFixed(2),
      authorRevenue: (Number(authorRevenueUSD) / 1e18).toFixed(2),
      platformFee: (Number(platformFeeUSD) / 1e18).toFixed(2)
  };
  return metrics;
}

async function main() {
    [owner] = await ethers.getSigners();

    const ContractMeme = await ethers.getContractFactory("ERC20MEME");
    const memeImplimentation = await ContractMeme.deploy();
    await memeImplimentation.waitForDeployment();

    const networkConfig = networks[process.env.NETWORK] || networks.sepolia
    const factoryConfig = await setupNetwork(networkConfig);
    await getWRAP(networkConfig)

    MemeFactory = await ethers.getContractFactory("MemeFactory");
    factory = await upgrades.deployProxy(MemeFactory,
        [await memeImplimentation.getAddress(), factoryConfig]
    );
    await factory.waitForDeployment();
    
    const wrapedToken = await ethers.getContractAt("ERC20", WrapToken);
    console.log("Owner:", owner.address, "Balance:", await wrapedToken.balanceOf(owner.address));
    await wrapedToken.approve(await factory.getAddress(), MaxUint256);
    
    const tx = await factory.createERC20("Test", "Test", WrapToken);
    const receipt = await tx.wait();
    const meme = await getERC20Created(receipt);
    const newMEME = await ethers.getContractAt("ERC20MEME", meme);
    
    let markdown = `| Market Cap (USD) | Token Price (USD) | Token Price Growth (%) | Minted Token (Amount) | Total Spent (Token) | Author Revenue (USD) | Platform Mint Fee (USD) |\r\n`;
    markdown += `|------------------|-------------------|------------------------|-----------------------|--------------------|-------------------------|-------------------------|\r\n`;
    const tokenPrice = BigInt(await getTokenPrice(networks[process.env.NETWORK].token, networks[process.env.NETWORK].networkID));
    for (let amount = BigInt(100000); amount < BigInt(200000000); amount = BigInt(2) * amount) {
        const metrics = await getTokenMetrics(newMEME, amount, tokenPrice);
        markdown += `| ${metrics.marketCap} | ${metrics.price} | ${metrics.priceGrowth} | ${metrics.totalSupply} | ${metrics.tokenSpend} | ${metrics.authorRevenue} | ${metrics.platformFee} |\r\n`;
    }
    
    fs.writeFileSync(`docs/tokenomics/`+process.env.NETWORK+`.md`, markdown);
}


main().catch(console.error);