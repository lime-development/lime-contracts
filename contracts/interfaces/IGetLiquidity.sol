// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IGetLiquidity {
    /**
     * @notice Computes the integer square root of a number.
     * @dev Uses Newton's method (binary search) for an approximate sqrt(x) calculation.
     * @param x The number to compute the square root of.
     * @return uint256 The approximate integer square root of x.
     */
    function sqrt(uint256 x) external pure returns (uint256);

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
    ) external pure returns (uint160);

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
    ) external pure returns (uint128 liquidity);
}
