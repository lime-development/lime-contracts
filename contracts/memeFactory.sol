// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./erc20meme.sol";

contract MemeFactory {

    struct PoolConfig {
        uint24 fee; // Fee tier (e.g., 3000 = 0.3%)
        int24  tickSpacing; // Tick spacing
        int24  minTick;
        int24  maxTick;
    }

    struct TokenConfig {
        address swapRouter;
        address factory;
        address getLiquidity;
        uint256 initialSupply;
        PoolConfig pool;
        uint256 fee;
    }

    event ERC20Created(address proxy);
    event ERC20Upgraded(address proxy, address newImplementation);
    event Debug(address t0, uint256 token0, address t1, uint256 token1);
    event Debug2(address t0, uint256 token0, address t1, uint256 token1);

    mapping(uint256 => address) public memelist;
    mapping(address => address) public pools;
    uint256 public memeid;
    address public implementation;
    address private _token0;
    address private _token1;

    TokenConfig public config;

    constructor(
        address _initialImplementation,
        address swapRouterAddress,
        address factoryAddress,
        address _getLiquidity
    ) {
        implementation = _initialImplementation;

        config = TokenConfig({
            swapRouter: swapRouterAddress,
            factory: factoryAddress,
            getLiquidity: _getLiquidity,
            initialSupply: 10,
            fee: 0,
            pool: PoolConfig({
                fee: 3000,
                tickSpacing: 60,
                minTick: -887272,
                maxTick: 887272
            })
        });
    }

    function getConfig() external view returns (TokenConfig memory) {
        return config;
    }

    function createERC20(
        string memory name,
        string memory symbol,
        address tokenPair
    ) external returns (address) {
        memeid++;
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            address(this),
            abi.encodeWithSignature(
                "initialize(string,string,uint256,address,address,address,address)",
                name,
                symbol,
                config.initialSupply,
                config.getLiquidity,
                tokenPair,
                config.swapRouter,
                config.factory
            )
        );
        address proxyAddress = address(proxy);
        IERC20(tokenPair).approve(proxyAddress, 2 ** 256 - 1);
        ERC20MEME(proxyAddress).initializePool();
        memelist[memeid] = proxyAddress;
        emit ERC20Created(proxyAddress);
        return proxyAddress;
    }

    function updateImplementation(address newImplementation) external {
        implementation = newImplementation;
        for (uint256 i = 1; i <= memeid; i++) {
            address proxy = memelist[i];
            ITransparentUpgradeableProxy(payable(proxy)).upgradeToAndCall(
                newImplementation,
                ""
            );
            emit ERC20Upgraded(proxy, newImplementation);
        }
    }
}
