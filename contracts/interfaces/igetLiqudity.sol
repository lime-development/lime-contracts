// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface igetLiquidity {
    function getLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint160 sqrtRatioX96
    ) external pure returns (uint128 liquidity);

    function getSqrtPriceX96(
        uint256 amountToken1,
        uint256 amountToken0
    ) external pure returns (uint160);

    function sqrt(uint256 x) external pure returns (uint256);
}