const { expect } = require("chai");
const { MaxUint256 } = require("ethers");
const { ethers, upgrades, hre } = require("hardhat");
const { poolConfig, networks } = require("./config");
const Decimal = require('decimal.js');
const { setupNetwork, getERC20Created, getTokenPrice, getWRAP } = require("./helper");
const fs = require('fs');
//ABI
const IUniswapV3Pool = require('@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json');
const IUniswapV3SwapRouter = require('@uniswap/v3-periphery/artifacts/contracts/interfaces/ISwapRouter.sol/ISwapRouter.json');
const PositionManager = require('@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json');
const { Console } = require("console");
const { platform } = require("os");

let router, pool, positionManager, meme, wrapedToken, networkConfig

async function getPoolMetrics() {

    const [token0, token1, fee, slot0] = await Promise.all([
        pool.token0(),
        pool.token1(),
        pool.fee(),
        pool.slot0(),
    ]);

    const token0Contract = await ethers.getContractAt("ERC20", token0);
    const token1Contract = await ethers.getContractAt("ERC20", token1);

    const [decimals0, decimals1, rawBalance0, rawBalance1] = await Promise.all([
        token0Contract.decimals(),
        token1Contract.decimals(),
        token0Contract.balanceOf(await pool.getAddress()),
        token1Contract.balanceOf(await pool.getAddress()),
    ]);

    const balance0 = ethers.formatUnits(rawBalance0, decimals0);
    const balance1 = ethers.formatUnits(rawBalance1, decimals1);

    const sqrtPriceX96 = Decimal(slot0[0]);
    const Decimal0 = Decimal(decimals0);
    const Decimal1 = Decimal(decimals1);

    const buyOneOfToken0 = ((sqrtPriceX96 / 2 ** 96) ** 2) / (10 ** Decimal1 / 10 ** Decimal0);
    const buyOneOfToken1 = (1 / buyOneOfToken0);

    let token0Price = 0;
    let token1Price = 0;
    let memePrice = 0;
    const tokenPrice = Decimal(await getTokenPrice(networkConfig.token, networkConfig.networkID)) / 1000000.0;
    if (networkConfig.token == token0) {
        token0Price = tokenPrice;
        token1Price = Decimal.mul(tokenPrice, buyOneOfToken1);
        memePrice = token1Price;
    } else {
        token0Price = Decimal.mul(tokenPrice, buyOneOfToken0);
        token1Price = tokenPrice;
        memePrice = token0Price;
    }

    tvl = Decimal.sum(Decimal.mul(balance0, token0Price), Decimal.mul(balance1, token1Price));

    const metrics = {
        token0: token0,
        decimals0: decimals0,
        token1: token1,
        decimals1: decimals1,
        balance0: balance0,
        balance1: balance1,
        priceToken1PerToken0: buyOneOfToken0,
        priceToken0PerToken1: buyOneOfToken1,
        token0Price: token0Price,
        token1Price: token1Price,
        memePrice: memePrice,
        fee: fee,
        tvl: tvl,
    };
    return metrics;
}

async function swap(tokenIn, amountIn) {
    const [token0, token1, fee] = await Promise.all([
        pool.token0(),
        pool.token1(),
        pool.fee()])

    let tokenOut;
    if (tokenIn == token0) {
        tokenOut = token1;
    } else {
        tokenOut = token0;
    }
    const params = {
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: fee,
        recipient: owner.address,
        deadline: Math.floor(Date.now() / 1000) + 60 * 10,
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
    };
    await router.connect(owner).exactInputSingle(params);
}


async function getContractPrice() {
    const decimal = Decimal(10n ** (await wrapedToken.decimals()));
    const [poolAmountPer1, protocolFeePer1, authorFeePer1] = await meme.calculatePrice(BigInt(10n ** 6n));
    const contractPrice = Decimal(poolAmountPer1 + protocolFeePer1 + authorFeePer1) / decimal
    return contractPrice;
}

async function sell() {
    let metrics = await getPoolMetrics();
    let contractPrice = await getContractPrice();
    let startAmount = await meme.balanceOf(owner.address);
    let userAmount = startAmount;

    while (contractPrice < metrics.priceToken1PerToken0) {
        userAmount = await meme.balanceOf(owner.address);
        await swap(await meme.getAddress(), (userAmount / 1000n))
        metrics = await getPoolMetrics();
        contractPrice = await getContractPrice();
        //console.log("SELL: contractPrice", Decimal(contractPrice).toFixed(16), "In Pool", metrics.priceToken1PerToken0.toFixed(16) )
    }
    //console.log("Price", "In Pool:",metrics.priceToken1PerToken0.toFixed(8), "In SmartContract",contractPrice.toFixed(8));

}

async function addLiquidity(amount0Desired, amount1Desired) {

    const [token0, token1, fee] = await Promise.all([
        pool.token0(),
        pool.token1(),
        pool.fee(),
    ]);
    // Mint a new position
    const params = {
        token0,
        token1,
        fee,
        tickLower: -887220, // full range
        tickUpper: 887220,  // full range
        amount0Desired: amount0Desired,
        amount1Desired: amount1Desired,
        amount0Min: 0,
        amount1Min: 0,
        recipient: owner.address,
        deadline: Math.floor(Date.now() / 1000) + 60 * 10,
    };
    console.log(await positionManager.getAddress())

    const tx = await positionManager.mint(params);
    console.log("Liquidity position NFT minted. Tx hash:", tx.hash);
}


async function main() {
    [owner, author, lime] = await ethers.getSigners();

    console.log("=========Init config============");
    const ContractMeme = await ethers.getContractFactory("ERC20MEME");
    const memeImplimentation = await ContractMeme.deploy();
    await memeImplimentation.waitForDeployment();

    networkConfig = networks[process.env.NETWORK] || networks.sepolia
    const factoryConfig = await setupNetwork(networkConfig);

    networkConfig.requestedOwnerTokenAmounts = BigInt(1 * 10 ** 24),
        await getWRAP(networkConfig)

    MemeFactory = await ethers.getContractFactory("MemeFactory");
    factory = await upgrades.deployProxy(MemeFactory.connect(lime),
        [await memeImplimentation.getAddress(), factoryConfig]
    );
    await factory.waitForDeployment();

    wrapedToken = await ethers.getContractAt("ERC20", networkConfig.token);
    //Get price from Sushi
    const price = Decimal(await getTokenPrice(networkConfig.token, networkConfig.networkID)).div(Decimal(1000000))

    console.log("Owner:", owner.address, "Wrap balance:", await wrapedToken.balanceOf(owner.address) / 10n ** 18n);
    console.log("Author:", owner.address, "Wrap Balance:", await wrapedToken.balanceOf(author.address) / 10n ** 18n);
    console.log("Lime Platform:", lime.address, "Wrap Balance:", await wrapedToken.balanceOf(lime.address) / 10n ** 18n);
    console.log("Token price USD", price.toFixed(4));

    console.log("=========Create meme token============");
    await wrapedToken.connect(author).approve(await factory.getAddress(), MaxUint256);
    const tx = await factory.connect(author).createERC20("Test", "Test", WrapToken);
    const receipt = await tx.wait();
    const memeContract = await getERC20Created(receipt);
    meme = await ethers.getContractAt("ERC20MEME", memeContract);

    console.log("=========Uniswap v3 Config============");
    router = await ethers.getContractAt(IUniswapV3SwapRouter.abi, networkConfig.swapRouter);
    pool = await ethers.getContractAt(IUniswapV3Pool.abi, await meme.pool());
    positionManager = await ethers.getContractAt(PositionManager.abi, networkConfig.positionManager);
    //Approve for mint
    await wrapedToken.approve(await meme.getAddress(), MaxUint256);
    //Approve for router (swap)
    await wrapedToken.approve(await router.getAddress(), MaxUint256);
    await meme.approve(await router.getAddress(), MaxUint256);
    //Approve for positionManager 
    await wrapedToken.approve(await positionManager.getAddress(), MaxUint256);
    await meme.approve(await positionManager.getAddress(), MaxUint256);

    metrics = await getPoolMetrics();
    console.log("Price in contract", Decimal(await getContractPrice()).toFixed(10), "Price in pool", metrics.priceToken1PerToken0.toFixed(10));
    console.log("=========Tokenomics calculation============");

    const decimal0 = Decimal(10n ** (await meme.decimals()));
    const decimal1 = Decimal(10n ** (await wrapedToken.decimals()));

    let markdown = '| MCap (USD) | Token Price (USD) | TVL (USD) | AuthorFee (USD) | ProtocolFee (USD) | Total Supply Meme |\r\n';
    markdown += '| ---- | --- | --- | --- | --- | --- |\r\n';

    let totalCost = Decimal(0.0);
    factoryAddress = await factory.getAddress()
    startAuthorBalance = await wrapedToken.balanceOf(author.address);
    startPlatformBalance = await wrapedToken.balanceOf(factoryAddress);

    const amount = [3372000n, 1500000n, 3000000n, 3000000n, 4000000n, 8500000n, 10000000n, 13500000n, 27000000n, 75000000n]
    for (let i = 0; i < amount.length; i++) {
        const amountBefore = await wrapedToken.balanceOf(owner.address);
        amount[i] = amount[i] * 10n ** 6n
        await meme.connect(owner).mint(owner, amount[i]);
        await sell();
        await factory.connect(lime).collectPoolsFees();
        metrics = await getPoolMetrics();

        authorFeeBalance = Decimal.sum(
            Decimal(await wrapedToken.balanceOf(author.address) - startAuthorBalance).mul(price).div(decimal1),
            Decimal(await meme.balanceOf(author.address)).mul(metrics.memePrice).div(decimal0));
        platformFeeBalance = Decimal.sum(
            Decimal(await wrapedToken.balanceOf(factoryAddress) - startPlatformBalance).mul(price).div(decimal1),
            Decimal(await meme.balanceOf(factoryAddress)).mul(metrics.memePrice).div(decimal0));

        const amountAfter = await wrapedToken.balanceOf(owner.address);
        const cost = new Decimal(amountBefore.toString()).minus(amountAfter.toString()).div(decimal1);
        totalCost = totalCost.plus(cost.mul(price));
        metrics = await getPoolMetrics();
        totalSupply = Decimal.div(Decimal(await meme.totalSupply()), decimal0);
        newString = `| ${metrics.memePrice.mul(totalSupply).toFixed(2)}` +
            `| ${metrics.memePrice.toFixed(8)}` +    
            `| ${metrics.tvl.toFixed(2)}` +
            `| ${authorFeeBalance.toFixed(2)}` +
            `| ${platformFeeBalance.toFixed(2)}` +
            `| ${totalSupply.toFixed(2)}` +
            `| \r\n`;
        console.log("Done", Decimal((i+1) * 100).div(Decimal(amount.length)).toFixed(1), "%");
        markdown += newString;

    }
    fs.writeFileSync(`docs/pool/` + process.env.NETWORK + `.md`, markdown);
}

main().catch(console.error);