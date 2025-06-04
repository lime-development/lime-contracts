---
layout: default
title: IERC20MEME
---
# Solidity API

## IERC20MEME

### Mint

```solidity
event Mint(address to, uint256 amount, uint256 poolAmount, uint256 protocolFee)
```

Emitted when new tokens are minted.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Recipient of the minted tokens. |
| amount | uint256 | Number of tokens minted. |
| poolAmount | uint256 | Amount allocated to the liquidity pool. |
| protocolFee | uint256 | Fee collected for the protocol. |

### Burn

```solidity
event Burn(address from, uint256 amount)
```

Emitted when tokens are burned.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | Address from which tokens were burned. |
| amount | uint256 | Amount of tokens burned. |

### FEE_DENOMINATOR

```solidity
function FEE_DENOMINATOR() external pure returns (uint256)
```

### INITIAL_SUPPLY_SCALE_FACTOR

```solidity
function INITIAL_SUPPLY_SCALE_FACTOR() external pure returns (uint256)
```

Precision denominator for fee calculations (0.001%)

### MIN_SQRT_RATIO

```solidity
function MIN_SQRT_RATIO() external pure returns (uint256)
```

Const for Uniswapv3 calculations

### MAX_SQRT_RATIO

```solidity
function MAX_SQRT_RATIO() external pure returns (uint256)
```

Const for Uniswapv3 calculations

### author

```solidity
function author() external view returns (address)
```

Returns the address of token author

### totalMinted

```solidity
function totalMinted() external view returns (uint256)
```

Returns the total minted tokens

### pool

```solidity
function pool() external view returns (address)
```

Returns the address of the Uniswap V3 pool used by this contract.

### poolToken

```solidity
function poolToken() external view returns (address)
```

Returns the address of the token paired in the liquidity pool.

### config

```solidity
function config() external view returns (struct Config.Token)
```

The configuration parameters used for pool and liquidity management.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Config.Token | The current token configuration |

### tickLower

```solidity
function tickLower() external view returns (int24)
```

Returns the lower tick boundary for the liquidity position.

### tickUpper

```solidity
function tickUpper() external view returns (int24)
```

Returns the upper tick boundary for the liquidity position.

### initialize

```solidity
function initialize(string memeName, string memeSymbol, address poolTokenAddr, address user) external
```

Initializes the ERC20MEME contract.

_Can only be called once due to the `initializer` modifier.
Sets the token name, symbol, and initializes inherited upgradeable contracts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| memeName | string | The name of the token. |
| memeSymbol | string | The symbol of the token. |
| poolTokenAddr | address | The address of the paired token for liquidity. |
| user | address | The address of the paired token for liquidity. |

### decimals

```solidity
function decimals() external view returns (uint8)
```

Overrides the ERC20 decimals function to set 6 decimal places.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | uint8 The number of decimal places for the token. |

### mint

```solidity
function mint(address to, uint256 amount) external
```

Mints new tokens and manages liquidity allocation.
The funds received for the mint go into the token's liquidity pool.

_Requires non-zero amounts and applies protocol fees._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address receiving the minted tokens. |
| amount | uint256 | The amount of tokens to mint. |

### burn

```solidity
function burn(uint256 amount) external
```

Burns a specific amount of tokens from the caller's account.

_Reduces the total supply._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens to burn. |

### calculatePrice

```solidity
function calculatePrice(uint256 amount) external view returns (uint256 poolAmount, uint256 protocolFee, uint256 authorFee)
```

Calculates the required pool contribution and protocol fee for minting tokens.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens to be minted. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAmount | uint256 | The required liquidity pool contribution. |
| protocolFee | uint256 | The protocol fee deducted from the pool amount. |
| authorFee | uint256 | The author fee deducted from the pool amount. |

### calculateValue

```solidity
function calculateValue(uint256 amount) external view returns (uint256 _price)
```

Computes a liquidity-based valuation using a cubic function.

_Uses the formula: factorial X^2 = 1/3 * X^3 / divider`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The token amount to calculate its value. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| _price | uint256 | The computed value based on liquidity mechanics. |

### collectPoolFees

```solidity
function collectPoolFees() external
```

Collects accumulated pool fees and transfers them to the contract owner.

_Ensures at least one token amount is greater than zero._

### pause

```solidity
function pause() external
```

Pause mint from factory

### unpause

```solidity
function unpause() external
```

Unpause mint from factory

### initializePool

```solidity
function initializePool() external
```

Creates and initializes the liquidity pool if it has not been initialized yet.

_The function is separated from __ERC20PoolV3_init to perform approval on the contract address after Init._

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
function getTokens() external view returns (address token0, address token1)
```

Returns the token pair addresses in the correct order for Uniswap V3.

### userSwap

```solidity
function userSwap(address tokenIn, uint256 amountIn, uint256 amountOut) external
```

Swap token on the UniSwapV3 liquidity pool.

_Requires non-zero amounts and applies protocol fees._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenIn | address | The address receiving the minted tokens. |
| amountIn | uint256 | The amount of tokens to mint. |
| amountOut | uint256 | The amount of tokens to mint. |

### transfer

```solidity
function transfer(address to, uint256 amount) external returns (bool)
```

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external returns (bool)
```

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

### name

```solidity
function name() external view returns (string)
```

### symbol

```solidity
function symbol() external view returns (string)
```

### permit

```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
```

### nonces

```solidity
function nonces(address owner) external view returns (uint256)
```

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() external view returns (bytes32)
```

### upgradeTo

```solidity
function upgradeTo(address newImplementation) external
```

### upgradeToAndCall

```solidity
function upgradeToAndCall(address newImplementation, bytes data) external payable
```

### paused

```solidity
function paused() external view returns (bool)
```

