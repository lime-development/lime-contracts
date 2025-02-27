// SPDX-License-Identifier: MIT
// 
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IERC20MEME.sol";
import "../config.sol";
import "../Versioned.sol";


contract MemeFactoryV2  is 
        Initializable, 
        OwnableUpgradeable, 
        UUPSUpgradeable, 
        PausableUpgradeable,
        ReentrancyGuardUpgradeable  {
using SafeERC20 for IERC20;

    event ERC20Created(address proxy);
    event ERC20Upgraded(address proxy, address newImplementation);
    event ConfigUpdated(Config.Token newConfig);
    event ProtocolFeeWithdrawn(address indexed token, uint256 amount);
    event ImplementationUpdated(address newImplementation);

    address[] public memeListArray;
    address public implementation;

    Config.Token public config;

     function initialize(
        address _initialImplementation,
        address swapRouterAddress,
        address factoryAddress,
        address _getLiquidity
    ) public initializer() {
        __Ownable_init(msg.sender); 
        __Pausable_init();
        __ReentrancyGuard_init();
        implementation = _initialImplementation;
        config = Config.Token({
            swapRouter: swapRouterAddress,
            factory: factoryAddress,
            getLiquidity: _getLiquidity,
            initialSupply: 10000000,
            protocolFee: 2500,
            initialMintCost: 10000000000000000,
            divider: 30000000,
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

    function updateConfig(Config.Token memory _config) external onlyOwner {
        config = _config;
        emit ConfigUpdated(config);
    }

    function withdrawProcotolFee(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");

        token.safeTransfer(owner(), amount);
        emit ProtocolFeeWithdrawn(tokenAddress, amount);
    }

    function collectPoolsFees() external onlyOwner {
        uint256 length = memeListArray.length;
        for (uint256 i = 0; i < length; i++) {
            IERC20MEME(memeListArray[i]).collectPoolFees();
        }
    }

    function createERC20(
        string memory name,
        string memory symbol,
        address tokenPair
    ) public whenNotPaused nonReentrant returns (address) {
        //ToDo tokenPair check
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

        uint256 toPool = config.initialMintCost;
        uint256 protocolFee = (toPool * config.protocolFee) / 100000;
        require(
            IERC20(tokenPair).allowance(msg.sender, address(this)) >= (toPool + protocolFee),
            "Insufficient allowance"
        );

        IERC20(tokenPair).safeTransferFrom(msg.sender, address(this), protocolFee);
        IERC20(tokenPair).safeTransferFrom(msg.sender, proxyAddress, toPool);

        memeListArray.push(proxyAddress);

        require(IERC20MEME(proxyAddress).pool() == address(0), "Pool already initialized");
        IERC20MEME(proxyAddress).initializePool();

        emit ERC20Created(proxyAddress);
        return proxyAddress;
    }

    function updateImplementation(address newImplementation) external onlyOwner {
        require(newImplementation.code.length > 0, "Invalid implementation");
        implementation = newImplementation;
        emit ImplementationUpdated(newImplementation);

        uint256 length = memeListArray.length;
        for (uint256 i = 0; i < length; i++) {
            address proxy = memeListArray[i];
            try ITransparentUpgradeableProxy(payable(proxy)).upgradeToAndCall(
                newImplementation, "") {
                emit ERC20Upgraded(proxy, newImplementation);
            } catch {
                emit ERC20Upgraded(proxy, address(0));
            }
        }
    }

    function version() public pure returns (string memory) {
        return "2.1.0";
    }
}
