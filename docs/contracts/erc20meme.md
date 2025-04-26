# Solidity API

## ERC20MEME

_An upgradeable ERC20 token with minting, liquidity management, and protocol fee collection.
This contract extends multiple OpenZeppelin upgradeable modules and integrates Uniswap V3 liquidity management.

Features:
- UUPS (Universal Upgradeable Proxy Standard) upgradeability.
- Ownable functionality with restricted access control.
- Reentrancy protection for secure token minting.
- Liquidity pool interaction via ERC20PoolV3.
- Uses `SafeERC20` for safe token transfers._

### author

```solidity
address author
```

Token author

### totalMinted

```solidity
uint256 totalMinted
```

Total minted tokens

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

### constructor

```solidity
constructor() public
```

_Constructor disables initializers to prevent direct deployment.
This contract should be deployed via a proxy using OpenZeppelin's upgradeable mechanism._

### initialize

```solidity
function initialize(string name, string symbol, address pairedToken_, address author_) public
```

Initializes the ERC20MEME contract.

_Can only be called once due to the `initializer` modifier.
Sets the token name, symbol, and initializes inherited upgradeable contracts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| pairedToken_ | address | The address of the paired token for liquidity. |
| author_ | address | The address of the paired token for liquidity. |

### decimals

```solidity
function decimals() public view virtual returns (uint8)
```

Overrides the ERC20 decimals function to set 6 decimal places.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | uint8 The number of decimal places for the token. |

### mint

```solidity
function mint(address to, uint256 amount) public
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
function calculatePrice(uint256 amount) public view returns (uint256 poolAmount, uint256 protocolFee, uint256 authorFee)
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
| authorFee | uint256 |  |

### calculateValue

```solidity
function calculateValue(uint256 amount) public view returns (uint256 _price)
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

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

Authorizes upgrades to the contract.

_This function ensures only the contract owner can upgrade the implementation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newImplementation | address | The address of the new contract implementation. |

### pause

```solidity
function pause() public
```

Pause mint from factory

### unpause

```solidity
function unpause() public
```

Unpause mint from factory

