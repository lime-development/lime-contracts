// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IERC20MEME.sol";
import "./config.sol";
import "./Versioned.sol";

contract MemeFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable, Versioned {
    event ERC20Created(address proxy);
    event ERC20Upgraded(address proxy, address newImplementation);

    mapping(uint256 => address) public memelist;
    mapping(address => address) public pools;
    uint256 public memeid;
    address public implementation;

    Config.Token public config;

    function initialize(
        address _initialImplementation,
        address swapRouterAddress,
        address factoryAddress,
        address _getLiquidity
    ) public initializer {
        __Ownable_init(msg.sender); 
        implementation = _initialImplementation;
        config = Config.Token({
            swapRouter: swapRouterAddress,
            factory: factoryAddress,
            getLiquidity: _getLiquidity,
            initialSupply: 10,
            protocolFee: 2500,
            initialMintCost: 1,
            pool: Config.Pool({
                fee: 3000,
                tickSpacing: 60,
                minTick: -887272,
                maxTick: 887272
            })
        });
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getConfig() external view returns (Config.Token memory) {
        return config;
    }

    function updateConfig(Config.Token memory _config) external onlyOwner  {
        config = _config;
    }

    function withdrawProcotolFee(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");

        bool success = token.transfer(owner(), amount);
        require(success, "Transfer failed");
    }

    function createERC20(
        string memory name,
        string memory symbol,
        address tokenPair
    ) public returns (address) {
        memeid++;
        ERC1967Proxy proxy = new ERC1967Proxy(
            implementation,
            abi.encodeWithSignature(
                "initialize(string,string,address)",
                name,
                symbol,
                tokenPair
            )
        );
        address proxyAddress = address(proxy);
        uint256 toPool = config.initialMintCost**ERC20(tokenPair).decimals();
        uint256 protocolFee = (toPool * config.protocolFee) / 100000;
        require(
            IERC20(tokenPair).transferFrom(msg.sender, proxyAddress, toPool),
            "Error transferring funds to pool creation."
        );
        require(
            IERC20(tokenPair).transferFrom(msg.sender, address(this), protocolFee),
            "Error in transferring funds"
        );
        IERC20MEME(proxyAddress).initializePool();
        memelist[memeid] = proxyAddress;
        emit ERC20Created(proxyAddress);
        return proxyAddress;
    }

    function updateImplementation(address newImplementation) external onlyOwner {
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
