// SPDX-License-Identifier: MIT
//
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.
pragma solidity ^0.8.22;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IV3SwapRouter} from "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";

import {Config} from "./config.sol";
import {IGetLiquidity} from "./interfaces/IGetLiquidity.sol";

contract ERC20PoolV3 is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Emitted when a new liquidity pool is created.
    /// @param token0 The address of the token0 token in the pool.
    /// @param token1 The address of the token1 token in the pool.
    /// @param pool The address of the created pool.
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        address indexed pool
    );

    /// @notice Emitted when the pool is initialized with a paired token.
    /// @param pairedToken The address of the paired token.
    /// @param pool The address of the initialized pool.
    event TokenInitialized(address indexed pairedToken, address indexed pool);

    /// @notice Emitted when the initial price of the pool is set.
    /// @param pool The address of the pool.
    /// @param sqrtPriceX96 The square root price in X96 format.
    event PriceSetuped(address indexed pool, uint160 indexed sqrtPriceX96);

    /// @notice Emitted when a token swap occurs.
    /// @param tokenIn The address of the input token.
    /// @param amountIn The amount of input tokens swapped.
    /// @param tokenOut The address of the output token.
    /// @param amountOut The amount of output tokens received.
    event Swapped(
        address indexed tokenIn,
        uint256 amountIn,
        address indexed tokenOut,
        uint256 amountOut
    );

    /// @notice Emitted when liquidity is added to the pool.
    /// @param token0 The address of the token0 token.
    /// @param amount0 The amount of the token0 token added.
    /// @param token1 The address of the token1 token.
    /// @param amount1 The amount of the token1 token added.
    event AddedLiquidity(
        address indexed token0,
        uint256 amount0,
        address indexed token1,
        uint256 amount1
    );

    /// @notice Emitted when pool fees are collected.
    /// @param amount0 The amount of the token0 token collected as fees.
    /// @param amount1 The amount of the token1 token collected as fees.
    event CollectedPoolFees(uint256 amount0, uint256 amount1);

    /// @notice Const for Uniswapv3 calculations
    uint160 public constant MIN_SQRT_RATIO = 4295128739;
    /// @notice Const for Uniswapv3 calculations
    uint160 public constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice The address of the Uniswap V3 pool associated with this contract.
    address public pool;

    /// @notice The address of the token paired with this contract's token in the liquidity pool.
    address public poolToken;

    /// @notice The configuration parameters used for pool and liquidity management.
    Config.Token public config;

    /// @notice tickLower The lower tick of the position in which to add liquidity
    int24 tickLower;
    /// @notice tickUpper The upper tick of the position in which to add liquidity
    int24 tickUpper;

    /// @notice Initializes the contract with the paired token and configuration.
    /// @param poolTokenAddr The address of the token with which the pool is to be created.
    /// @param tokenConfig The configuration structure containing pool settings.
    // slither-disable-next-line naming-convention
    function __ERC20PoolV3_init(
        address poolTokenAddr,
        Config.Token memory tokenConfig
    ) internal onlyInitializing {
        __Ownable_init(msg.sender);
        poolToken = poolTokenAddr;
        config = tokenConfig;
        // The lower tick for the liquidity position, rounded down to the nearest multiple of the tick spacing.
        // The rounding is intentional
        // slither-disable-next-line divide-before-multiply
        tickLower =
            (config.pool.minTick / config.pool.tickSpacing) *
            config.pool.tickSpacing;

        // The upper tick for the liquidity position, rounded down to the nearest multiple of the tick spacing.
        // The rounding is intentional
        // slither-disable-next-line divide-before-multiply
        tickUpper =
            (config.pool.maxTick / config.pool.tickSpacing) *
            config.pool.tickSpacing;
    }

    /// @notice Creates and initializes the liquidity pool if it has not been initialized yet.
    /// @dev The function is separated from __ERC20PoolV3_init to perform approval on the contract address after Init.
    // slither-disable-next-line reentrancy-events
    function initializePool() public onlyOwner {
        require(pool == address(0), "P0");
        createPool();
        setupPrice();
        addLiquidity();
        emit TokenInitialized(poolToken, pool);
    }

    /// @notice Creates a Uniswap V3 liquidity pool if it does not exist.
    // slither-disable-next-line reentrancy-events
    function createPool() internal {
        (address token0, address token1) = getTokens();

        pool = IUniswapV3Factory(config.factory).getPool(
            token0,
            token1,
            config.pool.fee
        );
        if (pool == address(0)) {
            pool = IUniswapV3Factory(config.factory).createPool(
                token0,
                token1,
                config.pool.fee
            );
            require(pool != address(0), "P1");
        }
        emit PoolCreated(token0, token1, pool);
    }

    /// @notice Sets the initial price for the liquidity pool base on token balanceOf on this address
    // slither-disable-next-line reentrancy-events
    function setupPrice() internal {
        require(pool != address(0), "P2");

        (address token0, address token1) = getTokens();
        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount0 > 0 && amount1 > 0, "P3");

        // Only sqrtPriceX96 and unlocked are used here, the other parameters like
        // tick, observationIndex, observationCardinality, observationCardinalityNext, and feeProtocol
        // are not necessary for the current logic of this function
        // slither-disable-next-line unused-return
        (uint160 sqrtPriceX96, , , , , , bool unlocked) = IUniswapV3Pool(pool)
            .slot0();
        require(!unlocked, "P4");

        if (sqrtPriceX96 == 0) {
            sqrtPriceX96 = IGetLiquidity(config.getLiquidity).getSqrtPriceX96(
                amount1,
                amount0
            );
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);

            // Only sqrtPriceX96 and unlocked are used here, the other parameters like
            // tick, observationIndex, observationCardinality, observationCardinalityNext, and feeProtocol
            // are not necessary for the current logic of this function
            // slither-disable-next-line unused-return
            (
                uint160 newSqrtPriceX96,
                ,
                ,
                ,
                ,
                ,
                bool newUnlocked
            ) = IUniswapV3Pool(pool).slot0();
            require(newSqrtPriceX96 != 0 && newUnlocked, "P5");
        }
        emit PriceSetuped(pool, sqrtPriceX96);
    }

    /// @notice Performs a token swap directly via Uniswap V3 pool.
    /// @param tokenIn The address of the token to swap from.
    /// @param amount The amount of the input token to swap.
    /// @param minAmountOut The minium amount of the out token from swap.
    // slither-disable-next-line reentrancy-events
    function swap(
        address tokenIn,
        uint256 amount,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        require(pool != address(0), "P6");
        require(IERC20(tokenIn).balanceOf(address(this)) >= amount, "P7");

        IERC20(tokenIn).safeIncreaseAllowance(pool, amount);

        address tokenOut = (tokenIn == address(this))
            ? poolToken
            : address(this);

        bool zeroForOne = tokenIn < tokenOut;

        uint160 sqrtPriceLimitX96 = zeroForOne
            ? MIN_SQRT_RATIO + 1
            : MAX_SQRT_RATIO - 1;

        (int256 amount0Delta, int256 amount1Delta) = IUniswapV3Pool(pool).swap(
            address(this),
            zeroForOne,
            int256(amount),
            sqrtPriceLimitX96,
            abi.encode(tokenIn, amount)
        );

        amountOut = uint256(zeroForOne ? -amount1Delta : -amount0Delta);
        require(amountOut >= minAmountOut, "P8");

        emit Swapped(tokenIn, amount, tokenOut, amountOut);
        return amountOut;
    }

    /// @notice Callback for UniswapV3Pool Swap
    /// @param data Data passed through by the addLiquidity() via the IUniswapV3PoolActions#Swap call
    function uniswapV3SwapCallback(
        int256 /*amount0Delta*/,
        int256 /*amount1Delta*/,
        bytes calldata data
    ) external {
        require(msg.sender == pool, "Callback must be from pool");
        (address tokenIn, uint256 amount) = abi.decode(
            data,
            (address, uint256)
        );
        IERC20(tokenIn).safeTransfer(msg.sender, amount);
    }

    /// @notice Adds liquidity to the Uniswap V3 pool.
    function addLiquidity() internal {
        require(pool != address(0), "PA");
        (address token0, address token1) = getTokens();

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount0 > 0 && amount1 > 0, "PB");

        IERC20(token0).safeIncreaseAllowance(pool, amount0);
        IERC20(token1).safeIncreaseAllowance(pool, amount1);

        // Only sqrtPriceX96 and unlocked are used here, the other parameters like
        // tick, observationIndex, observationCardinality, observationCardinalityNext, and feeProtocol
        // are not necessary for the current logic of this function
        // slither-disable-next-line unused-return
        (uint160 sqrtPriceX96, , , , , , bool unlocked) = IUniswapV3Pool(pool)
            .slot0();
        require(unlocked, "PC");

        uint256 liquidity = IUniswapV3Pool(pool).liquidity();
        uint128 liquidityIn = IGetLiquidity(config.getLiquidity).getLiquidity(
            amount0,
            amount1,
            sqrtPriceX96,
            tickLower,
            tickUpper
        );

        (uint256 added0, uint256 added1) = IUniswapV3Pool(pool).mint(
            address(this),
            tickLower,
            tickUpper,
            liquidityIn,
            abi.encode(token0, token1)
        );

        require((added0 > 0) && (added1 > 0), "PD");

        require(IUniswapV3Pool(pool).liquidity() > liquidity, "PE");
    }

    /// @notice Callback for UniswapV3Pool mint
    /// @param amount0 The amount of token0 due to the pool for the minted liquidity
    /// @param amount1 The amount of token1 due to the pool for the minted liquidity
    /// @param data Data passed through by the addLiquidity() via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        require(msg.sender == pool, "PF");
        (address token0, address token1) = abi.decode(data, (address, address));
        IERC20(token0).safeTransfer(msg.sender, amount0);
        IERC20(token1).safeTransfer(msg.sender, amount1);
        emit AddedLiquidity(token0, amount0, token1, amount1);
    }

    /// @notice Returns the token pair addresses in the correct order for Uniswap V3.
    function getTokens() public view returns (address token0, address token1) {
        (token0, token1) = address(this) < poolToken
            ? (address(this), poolToken)
            : (poolToken, address(this));
    }

    /// @notice Collects accumulated trading fees from the liquidity pool.
    // slither-disable-next-line reentrancy-events
    function _collectPoolFees()
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = IUniswapV3Pool(pool).collect(
            address(this),
            tickLower,
            tickUpper,
            type(uint128).max,
            type(uint128).max
        );
        emit CollectedPoolFees(amount0, amount1);
    }
}
