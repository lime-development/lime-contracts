// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";

import "./erc20meme.sol";

interface igetLiquidity {
    function getLiquidity(
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity);

    function sqrt(
        uint256 x
    ) external pure returns (uint256);
}

contract MemeFactory  {
    struct PoolConfig {
        uint24 fee; // Fee tier (e.g., 3000 = 0.3%)
        int24 tickSpacing; // Tick spacing
        int24 minTick;
        int24 maxTick;
        uint256 initialSupply;
    }

    struct PoolData {
        IV3SwapRouter swapRouter;
        IUniswapV3Factory factory;
        address getLiquidity;
        PoolConfig config;
    }

    event ERC20Created(address proxy);
    event ERC20Upgraded(address proxy, address newImplementation);
    event Debug(address t0, uint256 token0, address t1, uint256 token1);
    event Debug2(address t0, uint256 token0, address t1, uint256 token1);


    mapping(uint256 => address) public memelist;
    mapping(address => address) public pools;
    uint256 public memeid;
    address public implementation;
    address private _token0;
    address private _token1;

    PoolData public pool;

    constructor (
        address _initialImplementation,
        address swapRouterAddress,
        address factoryAddress,
        address _getLiquidity
    ) {
        implementation = _initialImplementation;

        pool= PoolData ({
            swapRouter: IV3SwapRouter(swapRouterAddress),
            factory: IUniswapV3Factory(factoryAddress),
            getLiquidity: _getLiquidity,
            config : PoolConfig({
                fee: 3000,
                tickSpacing: 60,
                minTick: -887272,
                maxTick: 887272,
                initialSupply: 50
            })
        });
    }

    function getPoolData() external view returns (PoolData memory) {
        return pool;
    } 

    function createERC20(string memory name, string memory symbol, address tokenPair) external returns (address) {
        memeid++;
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            address(this),
            abi.encodeWithSignature("initialize(string,string,uint256,address)", name, symbol, pool.config.initialSupply, tokenPair)
        );
        address proxyAddress = address(proxy);
        initializePool(proxyAddress, tokenPair);
        memelist[memeid] = proxyAddress;
        emit ERC20Created(proxyAddress);
        return proxyAddress;
    }

    function updateImplementation(address newImplementation) external  {
        implementation = newImplementation;
         for (uint256 i = 1; i <= memeid; i++){
            address proxy = memelist[i];
            ITransparentUpgradeableProxy(payable(proxy)).upgradeToAndCall(newImplementation,"");
            emit ERC20Upgraded(proxy, newImplementation);
         }
    }

     function initializePool(address memeToken, address token) public {
        uint256 withdrow = ERC20MEME(memeToken).calculateValue(pool.config.initialSupply);
        require(IERC20(token).balanceOf(msg.sender) > withdrow, "User balance lower than InitialSupply");
        require(IERC20(token).allowance(msg.sender, address(this))>=withdrow, "User allowance lower than InitialSupply");
        require(
            IERC20(token).transferFrom(
                msg.sender, 
                address(this),
                withdrow
            ), 
            "Transfer token from user failed"
            );
        createPool(memeToken, token);
        addInitialLiquidity(memeToken, token);
    }

    //Создает Pool с переданным токеном и текущим. 
    function createPool(address memeToken, address token) private   {
        (address token0, address token1) = memeToken < token
            ? (memeToken, token)
            : (token, memeToken);

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        require(amount0 > 0, "Amount of token0 must be greater than 0");

        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount1 > 0, "Amount of token1 must be greater than 0");     

        pools[memeToken] = pool.factory.getPool(token0, token1, pool.config.fee);
        if (pools[memeToken]  == address(0)) {
            pools[memeToken] = pool.factory.createPool(token1, token0, pool.config.fee);
            require(pools[memeToken]  != address(0), "Failed to create the pool");
        }
 
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pools[memeToken]).slot0();
        if(sqrtPriceX96==0){
            sqrtPriceX96 = uint160(
                igetLiquidity(pool.getLiquidity).sqrt(amount1)*2**96/igetLiquidity(pool.getLiquidity).sqrt(amount0)
            );
            IUniswapV3Pool(pools[memeToken]).initialize(sqrtPriceX96);
            (uint160 newSqrtPriceX96, , , , , , ) = IUniswapV3Pool(pools[memeToken]).slot0();
            require(newSqrtPriceX96 != 0, "Failed to initialize the pool");
        } 
    }

    function addInitialLiquidity(address memeToken, address token) private {
        (address token0, address token1) = memeToken < token
        ? (memeToken, token)
         : (token, memeToken);

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        require(amount0 > 0, "Amount of token0 must be greater than 0");
        IERC20(token0).approve(pools[memeToken], amount0);

        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount1 > 0, "Amount of token1 must be greater than 0");
        IERC20(token1).approve(pools[memeToken], amount1);

        uint128 liquidityAmount = igetLiquidity(pool.getLiquidity).getLiquidity(amount0, amount1);

       IUniswapV3Pool(pools[memeToken]).mint(
            address(this),
            (pool.config.minTick / pool.config.tickSpacing) * pool.config.tickSpacing,
            (pool.config.maxTick / pool.config.tickSpacing) * pool.config.tickSpacing,
            liquidityAmount,
            abi.encode(token0, token1)
        );
        require(IUniswapV3Pool(pools[memeToken]).liquidity() > 0, "AddInitialLiquidity falt");

    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) public {
        (address token0, address token1) = abi.decode(data, (address, address));
        IERC20(address(token0)).transfer(msg.sender, amount0);
        IERC20(address(token1)).transfer(msg.sender, amount1);
    }
}
