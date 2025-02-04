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

    function getLiquidity(
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity) {
        uint160 sqrtRatioX96 = uint160(
                (sqrt(amount1 * 2**192 / amount0))
            );

        int24 TICK_ = 60; 
        int24 MIN_ = -887272;
        int24 MAX_= -MIN_;    
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick((MIN_ / TICK_) * TICK_);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick((MAX_ / TICK_) * TICK_);
        liquidity = LiquidityAmounts.getLiquidityForAmounts(sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, amount0, amount1);
    }
}
