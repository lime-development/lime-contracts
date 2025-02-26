// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20MEME {
    event Mint(address to, uint256 amount, uint256 spended);

    function initialize(
        string memory name,
        string memory symbol,
        address pairedToken_
    ) external;

    function decimals() external view returns (uint8);

    function mint(address to, uint256 amount) external;

    function initializePool() external;

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external; 

    function calculatePrice(
        uint256 amount
    ) external view returns (uint256 poolAmount, uint256 protocolFee);

    function calculateValue(uint256 amount) external view returns (uint256 _price);
    
    function collectPoolFees() external;

    function version() external view returns (bytes32);

    function pool() external view returns (address);
}
