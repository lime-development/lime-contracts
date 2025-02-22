// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../config.sol";

interface IMemeFactory {
    event ERC20Created(address proxy);
    event ERC20Upgraded(address proxy, address newImplementation);

    function initialize(
        address _initialImplementation,
        address swapRouterAddress,
        address factoryAddress,
        address _getLiquidity
    ) external;

    function getConfig() external view returns (Config.Token memory);

    function createERC20(
        string memory name,
        string memory symbol,
        address tokenPair
    ) external returns (address);

    function updateImplementation(address newImplementation) external;

    function version() external view returns (bytes32);
}