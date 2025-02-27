// SPDX-License-Identifier: MIT
// 
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.
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
