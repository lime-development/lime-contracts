// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Config {
    struct Pool {
        uint24 fee; 
        int24  tickSpacing;
        int24  minTick;
        int24  maxTick;
    }

    struct Token {
        address swapRouter;
        address factory;
        address getLiquidity;
        uint256 initialSupply;
        uint256 initialMintCost;
        Pool pool;
        uint256 protocolFee;
        uint256 divider;
    }
}
