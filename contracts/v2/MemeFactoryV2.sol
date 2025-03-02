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


contract MemeFactoryV2 is 
        Initializable, 
        OwnableUpgradeable, 
        UUPSUpgradeable, 
        PausableUpgradeable,
        ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Emitted when a new meme token is created
    /// @param proxy Address of the created meme token proxy
    event ERC20Created(address proxy);

    /// @notice Emitted when an ERC20 token is upgraded
    /// @param proxy Address of the upgraded token proxy
    /// @param newImplementation New implementation contract address
    event ERC20Upgraded(address proxy, address newImplementation);

    /// @notice Emitted when the configuration is updated
    /// @param newConfig New token configuration
    event ConfigUpdated(Config.Token newConfig);

    /// @notice Emitted when protocol fees are withdrawn
    /// @param token Address of the token being withdrawn
    /// @param amount Amount of tokens withdrawn
    event ProtocolFeeWithdrawn(address indexed token, uint256 amount);

    /// @notice Emitted when the implementation address is updated
    /// @param newImplementation New implementation contract address
    event ImplementationUpdated(address newImplementation);

    /// @notice Emitted when the fee was collected from token pool 
    /// @param token token address
    event CollectedPoolFees(address token);

    /// @notice An array of contracts created through the factory.
    address[] public memeListArray;

    /// @notice Address the current implementation contract for ERC20 contracts. 
    address public implementation;

    /// @notice Congig for meme tokens
    Config.Token public config;

    /**
     * @notice Initializes the Factory with initial configuration for ERC20
     * @param _initialImplementation Address of the initial implementation contract
     * @param factoryAddress Address of the UniSwapV3 factory
     * @param _getLiquidity Address for obtaining liquidity information
     */
    function initialize(
        address _initialImplementation,
        address factoryAddress,
        address _getLiquidity
    ) public initializer() {
        __Ownable_init(msg.sender); 
        __Pausable_init();
        __ReentrancyGuard_init();
        implementation = _initialImplementation;
        config = Config.Token({
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

    /**
     * @notice Authorizes upgrades to the contract.
     * @dev This function ensures only the contract owner can upgrade the implementation.
     * @param newImplementation The address of the new contract implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Returns the current configuration for ERC20 tokens
    /// @return The current token configuration
    function getConfig() external view returns (Config.Token memory) {
        return config;
    }

    /// @notice Updates the for ERC20 tokens configuration
    /// @param _config New configuration values
    function updateConfig(Config.Token memory _config) external onlyOwner {
        config = _config;
        emit ConfigUpdated(config);
    }

    /// @notice Withdraws protocol fees to the owner
    /// @param tokenAddress Address of the token to withdraw
    /// @param amount Amount to withdraw
    function withdrawProcotolFee(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");

        token.safeTransfer(owner(), amount);
        emit ProtocolFeeWithdrawn(tokenAddress, amount);
    }

    /// @notice Creates a new ERC20 token (meme), create liquidity pool for meme
    /// and provide initial liquidity to pool
    /// @param name Name of the token
    /// @param symbol Symbol of the token
    /// @param tokenPair Address of the paired token (token with which a pool is created)
    /// @return Address of the newly created ERC20 token proxy
    function createERC20(
        string memory name,
        string memory symbol,
        address tokenPair
    ) public whenNotPaused nonReentrant returns (address) {
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

    /// @notice Updates the implementation contract
    /// @param newImplementation Address of the new implementation contract
    function updateImplementation(address newImplementation) external onlyOwner {
        require(newImplementation.code.length > 0, "Invalid implementation");
        implementation = newImplementation;
        emit ImplementationUpdated(implementation);
    }


    /// @notice Updates the implementation contract for all deployed tokens
    function updateTokens() external onlyOwner {
        uint256 length = memeListArray.length;
        for (uint256 i = 0; i < length; i++) {
            address proxy = memeListArray[i];
            try ITransparentUpgradeableProxy(payable(proxy)).upgradeToAndCall(
                implementation, "") {
                emit ERC20Upgraded(proxy, implementation);
            } catch {
                emit ERC20Upgraded(proxy, address(0));
            }
        }
    }

    /// @notice Updates the implementation contract for target tokens 
    /// @param meme Address of the target tokens
    function updateToken(address meme) external onlyOwner {
        ITransparentUpgradeableProxy(payable(meme)).upgradeToAndCall(
                implementation, "");
        emit ERC20Upgraded(meme, implementation);
    }

    /// @notice Collects pool fees from all token
    function collectPoolsFees() external onlyOwner {
        uint256 length = memeListArray.length;
        for (uint256 i = 0; i < length; i++) {
            try IERC20MEME(memeListArray[i]).collectPoolFees() {
                emit CollectedPoolFees(memeListArray[i]);
            } catch {
            }
        }
    }
    
    /// @notice Collects pool fees from meme token
    /// @param meme Address of the meme token
    function collectPoolFees(address meme) external onlyOwner {
       IERC20MEME(meme).collectPoolFees();
       emit CollectedPoolFees(meme);
    }

    function version() public pure returns (string memory) {
        return "2.1.0";
    }

}
