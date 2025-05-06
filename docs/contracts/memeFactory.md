---
layout: default
title: MemeFactory
---
# Solidity API

## MemeFactory

_Factory contract for deploying ERC20 tokens with upgradeable functionality.
It also accumulates fees received from token issuance and minting._

### ERC20Created

```solidity
event ERC20Created(address proxy, address author)
```

Emitted when a new meme token is created

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proxy | address | Address of the created meme token proxy |
| author | address | Meme author address |

### ERC20Upgraded

```solidity
event ERC20Upgraded(address proxy, address newImplementation)
```

Emitted when an ERC20 token is upgraded

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proxy | address | Address of the upgraded token proxy |
| newImplementation | address | New implementation contract address |

### ConfigUpdated

```solidity
event ConfigUpdated(struct Config.Token newConfig)
```

Emitted when the configuration is updated

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newConfig | struct Config.Token | New token configuration |

### ProtocolFeeWithdrawn

```solidity
event ProtocolFeeWithdrawn(address token, uint256 amount)
```

Emitted when protocol fees are withdrawn

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Address of the token being withdrawn |
| amount | uint256 | Amount of tokens withdrawn |

### ERC20ImplementationUpdated

```solidity
event ERC20ImplementationUpdated(address newImplementation)
```

Emitted when the implementation address for ERC20 tokens is updated

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newImplementation | address | New implementation contract address |

### CollectedPoolFees

```solidity
event CollectedPoolFees(address token)
```

Emitted when the fee was collected from token pool

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | token address |

### FEE_DENOMINATOR

```solidity
uint256 FEE_DENOMINATOR
```

### memeListArray

```solidity
address[] memeListArray
```

An array of contracts created through the factory.

### implementation

```solidity
address implementation
```

Address the current implementation contract for ERC20 contracts.

### config

```solidity
struct Config.Token config
```

Congig for meme tokens

### constructor

```solidity
constructor() public
```

This contract should be deployed via a proxy using OpenZeppelin's upgradeable mechanism.

### initialize

```solidity
function initialize(address initialImplementation, struct Config.Token tokensConfig) public
```

Initializes the Factory with initial configuration for ERC20.
Called once during proxy deployment by OpenZeppelin Upgrades plugin. DO NOT call directly.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| initialImplementation | address | Address of the initial implementation contract for ERC20 tokens |
| tokensConfig | struct Config.Token | Factory and meme token configuration |

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

### getConfig

```solidity
function getConfig() external view returns (struct Config.Token)
```

Returns the current configuration for ERC20 tokens

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Config.Token | The current token configuration |

### updateConfig

```solidity
function updateConfig(struct Config.Token tokensConfig) external
```

Updates the for ERC20 tokens configuration

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokensConfig | struct Config.Token | New configuration values |

### withdrawProcotolFee

```solidity
function withdrawProcotolFee(address tokenAddress, uint256 amount) external
```

Withdraws protocol fees to the owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | Address of the token to withdraw |
| amount | uint256 | Amount to withdraw |

### createERC20

```solidity
function createERC20(string name, string symbol) public returns (address)
```

Creates a new ERC20 token (meme), create liquidity pool for meme
and provide initial liquidity to pool

_The token is created by the author, so in this method only the platform receives a commission._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | Name of the token |
| symbol | string | Symbol of the token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Address of the newly created ERC20 token proxy |

### updateImplementation

```solidity
function updateImplementation(address newImplementation) external
```

Updates the implementation contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newImplementation | address | Address of the new implementation contract |

### updateTokensBatch

```solidity
function updateTokensBatch(uint256 startIndex, uint256 batchSize) external
```

Updates the implementation contract for a batch of tokens

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startIndex | uint256 | Start index of memeListArray |
| batchSize | uint256 | batch size for memeListArray |

### collectPoolsFees

```solidity
function collectPoolsFees(uint256 startIndex, uint256 batchSize) external
```

Collects pool fees from all token

### collectPoolFees

```solidity
function collectPoolFees(address meme) external
```

Collects pool fees from meme token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| meme | address | Address of the meme token |

### pause

```solidity
function pause() public
```

Pause create new token

### unpause

```solidity
function unpause() public
```

Unpause create new token

### pauseTokensBatch

```solidity
function pauseTokensBatch(uint256 startIndex, uint256 batchSize) external
```

Pause token batch

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startIndex | uint256 | Start index of memeListArray |
| batchSize | uint256 | batch size for memeListArray |

### unpauseTokensBatch

```solidity
function unpauseTokensBatch(uint256 startIndex, uint256 batchSize) external
```

Unpause token batch

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startIndex | uint256 | Start index of memeListArray |
| batchSize | uint256 | batch size for memeListArray |

### memeListArrayLength

```solidity
function memeListArrayLength() external view returns (uint256)
```

Returns the number of meme tokens created

