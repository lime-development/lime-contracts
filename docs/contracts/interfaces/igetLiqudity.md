---
layout: default
title: IgetLiqudity
---
# Solidity API

## igetLiquidity

### getLiquidity

```solidity
function getLiquidity(uint256 amount0, uint256 amount1, uint160 sqrtRatioX96, int24 min, int24 max) external pure returns (uint128 liquidity)
```

Computes the liquidity of a Uniswap V3 position.

_Uses TickMath to determine sqrtRatio at the range boundaries
and LiquidityAmounts to calculate liquidity._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | Amount of token 0. |
| amount1 | uint256 | Amount of token 1. |
| sqrtRatioX96 | uint160 | Current price ratio in sqrtPriceX96 format. |
| min | int24 | The minimum tick of the liquidity range. |
| max | int24 | The maximum tick of the liquidity range. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidity | uint128 | The calculated liquidity value. |

### getSqrtPriceX96

```solidity
function getSqrtPriceX96(uint256 amountToken1, uint256 amountToken0) external pure returns (uint160)
```

Calculates sqrtPriceX96 based on token reserves.

_Formula: sqrt(price) * 2^96, where price = amountToken1 / amountToken0.
This is used to obtain the current price ratio in Uniswap V3._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountToken1 | uint256 | Amount of token 1. |
| amountToken0 | uint256 | Amount of token 0. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint160 | uint160 The calculated sqrtPriceX96. |

