// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
import "./config.sol";
import "./interfaces/igetLiqudity.sol";

contract ERC20PoolV3 is Initializable {
    event PoolCreated(address token0, address token1, address pool);
    event TokenInitialized(address pairedToken, address pool);
    event PriceSetuped(address pool, uint160 sqrtPriceX96);

    address public pool;
    address public pairedToken;
    Config.Token public config;

    bool public poolInitialized = false;

    function __ERC20PoolV3_init(address _pairedToken, Config.Token memory _config) internal onlyInitializing {
        pairedToken = _pairedToken;
        config = _config;
    }

    function initializePool() public {
        require(pool == address(0), "Already initialized pool");
        createPool();
        setupPrice();
        addInitialLiquidity();
        poolInitialized = true;
        emit TokenInitialized(pairedToken, pool);
    }

    function createPool() internal {
        (address token0, address token1) = address(this) < pairedToken
            ? (address(this), pairedToken)
            : (pairedToken, address(this)); 

        pool = IUniswapV3Factory(config.factory).getPool(token0, token1, config.pool.fee);
        if (pool == address(0)) {
            pool = IUniswapV3Factory(config.factory).createPool(token0, token1, config.pool.fee);
            require(pool != address(0), "Failed to create the pool");
        }
        emit PoolCreated(token0, token1, pool);
    }

    function setupPrice() internal {
        (address token0, address token1) = address(this) < pairedToken
            ? (address(this), pairedToken)
            : (pairedToken, address(this));

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        require(amount0 > 0, "Amount of token0 must be greater than 0");

        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount1 > 0, "Amount of token1 must be greater than 0");

        require(pool != address(0), "Pool must be created");

        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        if (sqrtPriceX96 == 0) {
            sqrtPriceX96 = igetLiquidity(config.getLiquidity).getSqrtPriceX96(
                amount1,
                amount0
            );
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            (uint160 newSqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool)
                .slot0();
            require(newSqrtPriceX96 != 0, "Failed to initialize the pool");
        }
        emit PriceSetuped(pool, sqrtPriceX96);
    }


    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        require(msg.sender == pool, "Callback must be from pool");
        (address token0, address token1) = abi.decode(data, (address, address));
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);
    }

    function addInitialLiquidity() internal {
        (address token0, address token1) = address(this) < pairedToken
            ? (address(this), pairedToken)
            : (pairedToken, address(this));

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        require(amount0 > 0, "Amount of token0 must be greater than 0");
        IERC20(token0).approve(pool, amount0);

        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount1 > 0, "Amount of token1 must be greater than 0");
        IERC20(token1).approve(pool, amount1);

        uint128 liquidityAmount = igetLiquidity(config.getLiquidity).getLiquidity(amount0, amount1);

        IUniswapV3Pool(pool).mint(
            address(this),
            (config.pool.minTick / config.pool.tickSpacing) * config.pool.tickSpacing,
            (config.pool.maxTick / config.pool.tickSpacing) * config.pool.tickSpacing,
            liquidityAmount,
            abi.encode(token0, token1)
        );

        require(
            IUniswapV3Pool(pool).liquidity() > 0,
            "AddInitialLiquidity falt"
        );
    }
}