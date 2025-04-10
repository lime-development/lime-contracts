# Solidity API

## Config

### Pool

```solidity
struct Pool {
  uint24 fee;
  int24 tickSpacing;
  int24 minTick;
  int24 maxTick;
}
```

### Token

```solidity
struct Token {
  address factory;
  address getLiquidity;
  uint256 initialSupply;
  uint256 initialMintCost;
  struct Config.Pool pool;
  uint256 protocolFee;
  uint256 authorFee;
  uint256 divider;
}
```

