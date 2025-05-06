---
layout: default
title: ERC20PoolV3
---
# Solidity API

## ERC20PoolV3

### PoolCreated

```solidity
event PoolCreated(address token0, address token1, address pool)
```

Emitted when a new liquidity pool is created.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token0 | address | The address of the token0 token in the pool. |
| token1 | address | The address of the token1 token in the pool. |
| pool | address | The address of the created pool. |

### TokenInitialized

```solidity
event TokenInitialized(address pairedToken, address pool)
```

Emitted when the pool is initialized with a paired token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pairedToken | address | The address of the paired token. |
| pool | address | The address of the initialized pool. |

### PriceSetuped

```solidity
event PriceSetuped(address pool, uint160 sqrtPriceX96)
```

Emitted when the initial price of the pool is set.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the pool. |
| sqrtPriceX96 | uint160 | The square root price in X96 format. |

### Swapped

```solidity
event Swapped(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut)
```

Emitted when a token swap occurs.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenIn | address | The address of the input token. |
| amountIn | uint256 | The amount of input tokens swapped. |
| tokenOut | address | The address of the output token. |
| amountOut | uint256 | The amount of output tokens received. |

### AddedLiquidity

```solidity
event AddedLiquidity(address token0, uint256 amount0, address token1, uint256 amount1)
```

Emitted when liquidity is added to the pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token0 | address | The address of the token0 token. |
| amount0 | uint256 | The amount of the token0 token added. |
| token1 | address | The address of the token1 token. |
| amount1 | uint256 | The amount of the token1 token added. |

### CollectedPoolFees

```solidity
event CollectedPoolFees(uint256 amount0, uint256 amount1)
```

Emitted when pool fees are collected.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of the token0 token collected as fees. |
| amount1 | uint256 | The amount of the token1 token collected as fees. |

### MIN_SQRT_RATIO

```solidity
uint160 MIN_SQRT_RATIO
```

Const for Uniswapv3 calculations

### MAX_SQRT_RATIO

```solidity
uint160 MAX_SQRT_RATIO
```

Const for Uniswapv3 calculations

### pool

```solidity
address pool
```

The address of the Uniswap V3 pool associated with this contract.

### poolToken

```solidity
address poolToken
```

The address of the token paired with this contract's token in the liquidity pool.

### config

```solidity
struct Config.Token config
```

The configuration parameters used for pool and liquidity management.

### tickLower

```solidity
int24 tickLower
```

tickLower The lower tick of the position in which to add liquidity

### tickUpper

```solidity
int24 tickUpper
```

tickUpper The upper tick of the position in which to add liquidity

### __ERC20PoolV3_init

```solidity
function __ERC20PoolV3_init(address poolTokenAddr, struct Config.Token tokenConfig) internal
```

Initializes the contract with the paired token and configuration.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolTokenAddr | address | The address of the token with which the pool is to be created. |
| tokenConfig | struct Config.Token | The configuration structure containing pool settings. |

### initializePool

```solidity
function initializePool() public
```

Creates and initializes the liquidity pool if it has not been initialized yet.

_The function is separated from __ERC20PoolV3_init to perform approval on the contract address after Init._

### createPool

```solidity
function createPool() internal
```

Creates a Uniswap V3 liquidity pool if it does not exist.

### setupPrice

```solidity
function setupPrice() internal
```

Sets the initial price for the liquidity pool base on token balanceOf on this address

### swap

```solidity
function swap(address tokenIn, uint256 amount, uint256 minAmountOut) internal returns (uint256 amountOut)
```

Performs a token swap directly via Uniswap V3 pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenIn | address | The address of the token to swap from. |
| amount | uint256 | The amount of the input token to swap. |
| minAmountOut | uint256 | The minium amount of the out token from swap. |

### uniswapV3SwapCallback

```solidity
function uniswapV3SwapCallback(int256, int256, bytes data) external
```

Callback for UniswapV3Pool Swap

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | int256 |  |
|  | int256 |  |
| data | bytes | Data passed through by the addLiquidity() via the IUniswapV3PoolActions#Swap call |

### addLiquidity

```solidity
function addLiquidity() internal
```

Adds liquidity to the Uniswap V3 pool.

### uniswapV3MintCallback

```solidity
function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes data) external
```

Callback for UniswapV3Pool mint

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of token0 due to the pool for the minted liquidity |
| amount1 | uint256 | The amount of token1 due to the pool for the minted liquidity |
| data | bytes | Data passed through by the addLiquidity() via the IUniswapV3PoolActions#mint call |

### getTokens

```solidity
function getTokens() public view returns (address token0, address token1)
```

Returns the token pair addresses in the correct order for Uniswap V3.

### _collectPoolFees

```solidity
function _collectPoolFees() internal returns (uint256 amount0, uint256 amount1)
```

Collects accumulated trading fees from the liquidity pool.

