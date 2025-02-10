// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";

import "./erc20meme.sol";

interface iLiquidity {
    function getLiquidity(
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity);

    function sqrt(uint256 x) external pure returns (uint256);
}

contract MemeFactory {
    struct PoolConfig {
        uint24 fee; // Fee tier (e.g., 3000 = 0.3%)
        int24 tickSpacing; // Tick spacing
        int24 minTick;
        int24 maxTick;
        uint256 initialSupply;
    }

    struct PoolData {
        IV3SwapRouter swapRouter;
        IUniswapV3Factory factory;
        address getLiquidity;
        PoolConfig config;
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

    PoolData public pool;

    constructor(
        address _initialImplementation,
        address swapRouterAddress,
        address factoryAddress,
        address _getLiquidity
    ) {
        implementation = _initialImplementation;

        pool = PoolData({
            swapRouter: IV3SwapRouter(swapRouterAddress),
            factory: IUniswapV3Factory(factoryAddress),
            getLiquidity: _getLiquidity,
            config: PoolConfig({
                fee: 3000,
                tickSpacing: 60,
                minTick: -887272,
                maxTick: 887272,
                initialSupply: 1000000
            })
        });
    }

    function getPoolData() external view returns (PoolData memory) {
        return pool;
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
                "initialize(string,string,uint256,address)",
                name,
                symbol,
                pool.config.initialSupply,
                pool.getLiquidity
            )
        );
        address proxyAddress = address(proxy);
        IERC20(tokenPair).approve(proxyAddress, 2 ** 256 - 1);
        ERC20MEME(proxyAddress).initializePool(tokenPair);
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
