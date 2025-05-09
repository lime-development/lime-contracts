// SPDX-License-Identifier: MIT
//
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.

// This pragma version is intentionally fixed to 0.7.6 to maintain compatibility
// with Uniswap V3 core and periphery libraries, which were originally written
// for Solidity 0.7.x. This contract is not intended to be upgraded to 0.8.x
// to preserve compatibility with these dependencies.
// slither-disable-start solc-version
pragma solidity =0.7.6;

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

/**
 * @title GetLiquidityHelper
 * @dev Helper contract for calculating liquidity in Uniswap V3.
 * This contract serves as an intermediary for utilizing TickMath.sol
 * and LiquidityAmounts.sol from Uniswap V3. It simplifies the process
 * of computing liquidity and relevant values for Uniswap V3 pools.
 * @author Vorobev Sergei
 */
contract GetLiquidityHelper {
    /**
     * @notice Computes the integer square root of a number.
     * @dev Uses Newton's method (binary search) for an approximate sqrt(x) calculation.
     * @param x The number to compute the square root of.
     * @return uint256 The approximate integer square root of x.
     */
    function sqrt(uint256 x) public pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    /**
     * @notice Calculates sqrtPriceX96 based on token reserves.
     * @dev Formula: sqrt(price) * 2^96, where price = amountToken1 / amountToken0.
     * This is used to obtain the current price ratio in Uniswap V3.
     * @param amountToken1 Amount of token 1.
     * @param amountToken0 Amount of token 0.
     * @return uint160 The calculated sqrtPriceX96.
     */
    function getSqrtPriceX96(
        uint256 amountToken1,
        uint256 amountToken0
    ) public pure returns (uint160) {
        require(amountToken0 > 0 && amountToken1 > 0, "L0");
        uint256 price = (amountToken1 * 1e18) / amountToken0; // price in token1/token0
        uint256 sqrtPrice = sqrt(price);
        return uint160((sqrtPrice * (1 << 96)) / 1e9); // Adjust for precision
    }

    /**
     * @notice Computes the liquidity of a Uniswap V3 position.
     * @dev Uses TickMath to determine sqrtRatio at the range boundaries
     * and LiquidityAmounts to calculate liquidity.
     * @param amount0 Amount of token 0.
     * @param amount1 Amount of token 1.
     * @param sqrtRatioX96 Current price ratio in sqrtPriceX96 format.
     * @param min The minimum tick of the liquidity range.
     * @param max The maximum tick of the liquidity range.
     * @return liquidity The calculated liquidity value.
     */
    function getLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint160 sqrtRatioX96,
        int24 min,
        int24 max
    ) external pure returns (uint128 liquidity) {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(min);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(max);
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            amount0,
            amount1
        );
    }
}
// slither-disable-end solc-version
