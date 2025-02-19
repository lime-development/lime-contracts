// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./erc20meme.sol";
import "./config.sol";

contract MemeFactory {

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

    Config.Token public config;

    constructor(
        address _initialImplementation,
        address swapRouterAddress,
        address factoryAddress,
        address _getLiquidity
    ) {
        implementation = _initialImplementation;

        config = Config.Token({
            swapRouter: swapRouterAddress,
            factory: factoryAddress,
            getLiquidity: _getLiquidity,
            initialSupply: 10,
            protocolFee: 3000,
            initialMintCost: 1,
            pool: Config.Pool({
                fee: 3000,
                tickSpacing: 60,
                minTick: -887272,
                maxTick: 887272
            })
        });
    }

    function getConfig() external view returns (Config.Token memory) {
        return config;
    }

    function createERC20(
        string memory name,
        string memory symbol,
        address tokenPair
    ) public returns (address) {
        memeid++;
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            address(this),
            abi.encodeWithSignature(
                "initialize(string,string,uint256,address)",
                name,
                symbol,
                config.initialSupply,
                tokenPair
            )
        );
        address proxyAddress = address(proxy);
        uint256 toPool = config.initialMintCost**ERC20(tokenPair).decimals();
        uint256 procolFee = (toPool * config.protocolFee) / 100000;
        require(IERC20(tokenPair).transferFrom(msg.sender, proxyAddress, toPool),"Error transferring funds to pool creation.");
        require(IERC20(tokenPair).transferFrom(msg.sender, address(this), procolFee),"Error in transferring funds");
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
