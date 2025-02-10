// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol';

contract getLiquidityHelper {

    function sqrt(uint256 x) public pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function getSqrtPriceX96(uint256 amountToken1, uint256 amountToken0) public pure returns (uint160) {
        require(amountToken0 > 0 && amountToken1 > 0, "Amounts must be positive");
        uint256 price = (amountToken1 * 1e18) / amountToken0; // price in token1/token0
        uint256 sqrtPrice = sqrt(price);
        return uint160((sqrtPrice * (1 << 96)) / 1e9); // Adjust for precision
    }

    function getLiquidity(
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity) {
        uint160 sqrtRatioX96 = getSqrtPriceX96(amount1, amount0);
        int24 TICK_ = 60; 
        int24 MIN_ = -887272;
        int24 MAX_= -MIN_;    
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick((MIN_ / TICK_) * TICK_);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick((MAX_ / TICK_) * TICK_);
        liquidity = LiquidityAmounts.getLiquidityForAmounts(sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, amount0, amount1);
    }
}
