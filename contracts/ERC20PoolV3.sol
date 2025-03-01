// SPDX-License-Identifier: MIT
// 
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IV3SwapRouter} from "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";

import {Config} from "./config.sol";
import {igetLiquidity} from "./interfaces/igetLiqudity.sol";

contract ERC20PoolV3 is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Emitted when a new liquidity pool is created.
    /// @param token0 The address of the token0 token in the pool.
    /// @param token1 The address of the token1 token in the pool.
    /// @param pool The address of the created pool.
    event PoolCreated(address token0, address token1, address pool);

    /// @notice Emitted when the pool is initialized with a paired token.
    /// @param pairedToken The address of the paired token.
    /// @param pool The address of the initialized pool.
    event TokenInitialized(address pairedToken, address pool);

    /// @notice Emitted when the initial price of the pool is set.
    /// @param pool The address of the pool.
    /// @param sqrtPriceX96 The square root price in X96 format.
    event PriceSetuped(address pool, uint160 sqrtPriceX96);

    /// @notice Emitted when a token swap occurs.
    /// @param tokenIn The address of the input token.
    /// @param amountIn The amount of input tokens swapped.
    /// @param tokenOut The address of the output token.
    /// @param amountOut The amount of output tokens received.
    event Swapped(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    /// @notice Emitted when liquidity is added to the pool.
    /// @param token0 The address of the token0 token.
    /// @param amount0 The amount of the token0 token added.
    /// @param token1 The address of the token1 token.
    /// @param amount1 The amount of the token1 token added.
    event AddedLiquidity(address token0, uint256 amount0, address token1, uint256 amount1);

    /// @notice Emitted when pool fees are collected.
    /// @param amount0 The amount of the token0 token collected as fees.
    /// @param amount1 The amount of the token1 token collected as fees.
    event CollectedPoolFees(uint256 amount0, uint256 amount1);


    address public pool;
    address public pairedToken;
    Config.Token public config;

    /// @notice Initializes the contract with the paired token and configuration.
    /// @param _pairedToken The address of the token with which the pool is to be created.
    /// @param _config The configuration structure containing pool settings.
    function __ERC20PoolV3_init(address _pairedToken, Config.Token memory _config) internal onlyInitializing {
        __Ownable_init(msg.sender);
        pairedToken = _pairedToken;
        config = _config;
    }

    /// @notice Creates and initializes the liquidity pool if it has not been initialized yet.
    /// @dev The function is separated from __ERC20PoolV3_init to perform approval on the contract address after Init. 
    function initializePool() public onlyOwner {
        require(pool == address(0), "Pool already initialized");
        createPool();
        setupPrice();
        addLiquidity();
        emit TokenInitialized(pairedToken, pool);
    }

    /// @notice Creates a Uniswap V3 liquidity pool if it does not exist.
    function createPool() internal {
        (address token0, address token1) = getTokens();

        pool = IUniswapV3Factory(config.factory).getPool(token0, token1, config.pool.fee);
        if (pool == address(0)) {
            pool = IUniswapV3Factory(config.factory).createPool(token0, token1, config.pool.fee);
            require(pool != address(0), "Pool creation failed");
        }
        emit PoolCreated(token0, token1, pool);
    }

    /// @notice Sets the initial price for the liquidity pool base on token balanceOf on this address
    function setupPrice() internal {
        require(pool != address(0), "Pool must exist");

        (address token0, address token1) = getTokens();
        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount0 > 0 && amount1 > 0, "Both tokens must have balance");

        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        if (sqrtPriceX96 == 0) {
            sqrtPriceX96 = igetLiquidity(config.getLiquidity).getSqrtPriceX96(amount1, amount0);
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            (uint160 newSqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
            require(newSqrtPriceX96 != 0, "Pool initialization failed");
        }
        emit PriceSetuped(pool, sqrtPriceX96);
    }

    /// @notice Performs a token swap directly via Uniswap V3 pool.
    /// @param tokenIn The address of the token to swap from.
    /// @param amount The amount of the input token to swap.
    function swap(address tokenIn, uint256 amount) internal {
        require(pool != address(0), "Pool must be created");
        require(IERC20(tokenIn).balanceOf(address(this)) >= amount, "Insufficient balance for swap");
    
        IERC20(tokenIn).safeIncreaseAllowance(pool, amount);
    
        address tokenOut = (tokenIn == address(this)) ? pairedToken : address(this);
    
        bool zeroForOne = tokenIn < tokenOut;

        uint160 MIN_SQRT_RATIO = 4295128739;
        uint160 MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

        uint160 sqrtPriceLimitX96 = zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1;
    
        (int256 amount0Delta, int256 amount1Delta) = IUniswapV3Pool(pool).swap(
            address(this),
            zeroForOne,
            int256(amount),
            sqrtPriceLimitX96,
            abi.encode(tokenIn, amount)  
        );

        uint256 amountOut = uint256(zeroForOne ? -amount1Delta : -amount0Delta);
        require(amountOut > 0, "Swap failed");
    
        emit Swapped(tokenIn, amount, tokenOut, amountOut);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        require(msg.sender == pool, "Callback must be from pool");
        (address tokenIn, uint256 amount) = abi.decode(data, (address, uint256));
        IERC20(tokenIn).safeTransfer(msg.sender, amount);
    }

    /// @notice Adds liquidity to the Uniswap V3 pool.
    function addLiquidity() internal {
        require(pool != address(0), "Pool must exist");
        (address token0, address token1) = getTokens();

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount0 > 0 && amount1 > 0, "Insufficient token balance");

        IERC20(token0).safeIncreaseAllowance(pool, amount0);
        IERC20(token1).safeIncreaseAllowance(pool, amount1);

        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        uint256 liquidity = IUniswapV3Pool(pool).liquidity();
        uint128 liquidityIn = igetLiquidity(config.getLiquidity).getLiquidity(
            amount0, 
            amount1, 
            sqrtPriceX96,
            config.pool.tickSpacing,
            config.pool.minTick,
            config.pool.maxTick
        );

        IUniswapV3Pool(pool).mint(
            address(this),
            (config.pool.minTick / config.pool.tickSpacing) * config.pool.tickSpacing,
            (config.pool.maxTick / config.pool.tickSpacing) * config.pool.tickSpacing,
            liquidityIn,
            abi.encode(token0, token1)
        );

        require(
            IUniswapV3Pool(pool).liquidity() > liquidity,"AddLiquidity falt"
        );
    }

    /// @notice Callback for UniswapV3Pool mint  
    /// @param amount0 The amount of token0 due to the pool for the minted liquidity
    /// @param amount1 The amount of token1 due to the pool for the minted liquidity
    /// @param data Data passed through by the addLiquidity() via the IUniswapV3PoolActions#mint call 
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        require(msg.sender == pool, "Callback must be from pool");
        (address token0, address token1) = abi.decode(data, (address, address));
        IERC20(token0).safeTransfer(msg.sender, amount0);
        IERC20(token1).safeTransfer(msg.sender, amount1);
        emit AddedLiquidity(token0, amount0, token1, amount1);
    }

    /// @notice Returns the token pair addresses in the correct order for Uniswap V3.
    function getTokens() public view returns (address token0, address token1) {
        (token0, token1) = address(this) < pairedToken
            ? (address(this), pairedToken)
            : (pairedToken, address(this));
    }

    /// @notice Collects accumulated trading fees from the liquidity pool.
    function _collectPoolFees() internal returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = IUniswapV3Pool(pool).collect(
            address(this),
            (config.pool.minTick / config.pool.tickSpacing) * config.pool.tickSpacing,
            (config.pool.maxTick / config.pool.tickSpacing) * config.pool.tickSpacing,
            type(uint128).max,
            type(uint128).max
        );
        emit CollectedPoolFees(amount0, amount1);
    }
}