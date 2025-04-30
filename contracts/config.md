---
layout: default
title: Config
---
# Solidity API

## Config

Holds configuration parameters used during token creation by the factory and subsequently the tokens themselves.

### Pool

Structure containing Uniswap V3 pool parameters

```solidity
struct Pool {
  uint24 fee;
  int24 tickSpacing;
  int24 minTick;
  int24 maxTick;
}
```

### Token

Token creation configuration used by the factory

```solidity
struct Token {
  address factory;
  address pairedToken;
  address getLiquidity;
  uint256 initialSupply;
  uint256 initialMintCost;
  struct Config.Pool pool;
  uint256 protocolFee;
  uint256 authorFee;
  uint256 divider;
}
```

