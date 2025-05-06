// SPDX-License-Identifier: MIT
//
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.
pragma solidity ^0.8.22;

/// @title Config
/// @notice Holds configuration parameters used during token creation by the factory and subsequently the tokens themselves.
contract Config {
    /// @notice Structure containing Uniswap V3 pool parameters
    struct Pool {
        uint24 fee; // Pool fee (in hundredths of a bip, e.g., 500 = 0.05%)
        int24 tickSpacing; // Tick spacing that determines the granularity of price changes (e.g., 60)
        int24 minTick; // Minimum tick value (defines lower price boundary)
        int24 maxTick; // Maximum tick value (defines upper price boundary)
    }

    /// @notice Token creation configuration used by the factory
    struct Token {
        address factory; // Address of the Factory contract responsible for token deployment
        address pairedToken; // Token with which pools will be created on this network.
        address getLiquidity; // Address of the liquidity management contract
        uint256 initialSupply; // Total supply minted when the token is first created
        uint256 initialMintCost; // Cost to mint or launch the token (denominated in base currency)
        Pool pool; // Liquidity pool parameters used for creating the Uniswap V3 pool
        uint256 protocolFee; // Portion of funds allocated to the Noorim protocol (relative to the divider)
        uint256 authorFee; // Portion of funds allocated to the token creator (relative to the divider)
        uint256 divider; // Precision divider for fee calculation (e.g., 1000 = 0.1% increments)
    }
}
