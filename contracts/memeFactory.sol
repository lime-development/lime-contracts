// SPDX-License-Identifier: MIT
//
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.
pragma solidity ^0.8.22;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IERC20MEME.sol";
import "./config.sol";

/**
 * @title MemeFactory
 * @dev Factory contract for deploying ERC20 tokens with upgradeable functionality.
 * It also accumulates fees received from token issuance and minting.
 * @author Vorobev Sergei
 */
contract MemeFactory is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    /// @notice Emitted when a new meme token is created
    /// @param proxy Address of the created meme token proxy
    /// @param author Meme author address
    event ERC20Created(address indexed proxy, address indexed author);

    /// @notice Emitted when an ERC20 token is upgraded
    /// @param proxy Address of the upgraded token proxy
    /// @param newImplementation New implementation contract address
    event ERC20Upgraded(
        address indexed proxy,
        address indexed newImplementation
    );

    /// @notice Emitted when the configuration is updated
    /// @param newConfig New token configuration
    event ConfigUpdated(Config.Token indexed newConfig);

    /// @notice Emitted when protocol fees are withdrawn
    /// @param token Address of the token being withdrawn
    /// @param amount Amount of tokens withdrawn
    event ProtocolFeeWithdrawn(address indexed token, uint256 indexed amount);

    /// @notice Emitted when the implementation address for ERC20 tokens is updated
    /// @param newImplementation New implementation contract address
    event ERC20ImplementationUpdated(address indexed newImplementation);

    /// @notice Emitted when the fee was collected from token pool
    /// @param token token address
    event CollectedPoolFees(address indexed token);

    uint256 public constant FEE_DENOMINATOR = 100_000; // precision: 0.001%

    /// @notice An array of contracts created through the factory.
    address[] public memeListArray;

    /// @notice Address the current implementation contract for ERC20 contracts.
    address public implementation;

    /// @notice Congig for meme tokens
    Config.Token public config;

    // @dev Constructor disables initializers to prevent direct deployment.
    /// This contract should be deployed via a proxy using OpenZeppelin's upgradeable mechanism.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the Factory with initial configuration for ERC20.
     * Called once during proxy deployment by OpenZeppelin Upgrades plugin. DO NOT call directly.
     * @param initialImplementation Address of the initial implementation contract for ERC20 tokens
     * @param tokensConfig Factory and meme token configuration
     */
    function initialize(
        address initialImplementation,
        Config.Token calldata tokensConfig
    ) public initializer {
        require(initialImplementation != address(0), "F0");
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        implementation = initialImplementation;
        config = tokensConfig;
    }

    /**
     * @notice Authorizes upgrades to the contract.
     * @dev This function ensures only the contract owner can upgrade the implementation.
     * @param newImplementation The address of the new contract implementation.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /// @notice Returns the current configuration for ERC20 tokens
    /// @return The current token configuration
    function getConfig() external view returns (Config.Token memory) {
        return config;
    }

    /// @notice Updates the for ERC20 tokens configuration
    /// @param tokensConfig New configuration values
    function updateConfig(Config.Token memory tokensConfig) external onlyOwner {
        config = tokensConfig;
        emit ConfigUpdated(config);
    }

    /// @notice Withdraws protocol fees to the owner
    /// @param tokenAddress Address of the token to withdraw
    /// @param amount Amount to withdraw
    function withdrawProcotolFee(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "F1");

        token.safeTransfer(owner(), amount);
        emit ProtocolFeeWithdrawn(tokenAddress, amount);
    }

    /// @notice Creates a new ERC20 token (meme), create liquidity pool for meme
    /// and provide initial liquidity to pool
    /// @param name Name of the token
    /// @param symbol Symbol of the token
    /// @return Address of the newly created ERC20 token proxy
    /// @dev The token is created by the author, so in this method only the platform receives a commission.
    // Reentrancy guarded via `nonReentrant` modifier
    // slither-disable-next-line reentrancy-benign,reentrancy-events
    function createERC20(
        string memory name,
        string memory symbol
    ) public whenNotPaused nonReentrant returns (address) {
        ERC1967Proxy proxy = new ERC1967Proxy(
            implementation,
            abi.encodeWithSignature(
                "initialize(string,string,address,address)",
                name,
                symbol,
                config.pairedToken,
                msg.sender
            )
        );
        address proxyAddress = address(proxy);

        memeListArray.push(proxyAddress);

        uint256 toPool = config.initialMintCost;
        uint256 protocolFee = (toPool * config.protocolFee) / FEE_DENOMINATOR;
        require(
            IERC20(config.pairedToken).allowance(msg.sender, address(this)) >=
                (toPool + protocolFee),
            "F2"
        );

        IERC20(config.pairedToken).safeTransferFrom(
            msg.sender,
            address(this),
            protocolFee
        );
        IERC20(config.pairedToken).safeTransferFrom(
            msg.sender,
            proxyAddress,
            toPool
        );

        IERC20MEME(proxyAddress).initializePool();

        emit ERC20Created(proxyAddress, msg.sender);
        return proxyAddress;
    }

    /// @notice Updates the implementation contract
    /// @param newImplementation Address of the new implementation contract
    function updateImplementation(
        address newImplementation
    ) external onlyOwner {
        require(newImplementation.code.length > 0, "F4");
        implementation = newImplementation;
        emit ERC20ImplementationUpdated(implementation);
    }

    /// @notice Updates the implementation contract for a batch of tokens
    /// @param startIndex Start index of memeListArray
    /// @param batchSize batch size for memeListArray
    // Reentrancy guarded via `nonReentrant` modifier
    // slither-disable-next-line reentrancy-events
    function updateTokensBatch(
        uint256 startIndex,
        uint256 batchSize
    ) external nonReentrant onlyOwner {
        require(startIndex < memeListArray.length, "F5");
        address newProxyImplementation = implementation;
        uint256 length = memeListArray.length;
        uint256 endIndex = startIndex + batchSize;
        if (endIndex > length) {
            endIndex = length;
        }

        for (uint256 i = startIndex; i < endIndex; i++) {
            address proxy = memeListArray[i];
            // External upgrade inside a controlled loop with capped batchSize.
            // We acknowledge the risk and control gas usage via external batch processing.
            // slither-disable-next-line calls-loop
            try
                ITransparentUpgradeableProxy(payable(proxy)).upgradeToAndCall(
                    newProxyImplementation,
                    ""
                )
            {
                emit ERC20Upgraded(proxy, newProxyImplementation);
            } catch {
                emit ERC20Upgraded(proxy, address(0));
            }
        }
    }

    /// @notice Collects pool fees from all token
    // Reentrancy guarded via `nonReentrant` modifier
    // slither-disable-next-line reentrancy-events
    function collectPoolsFees(
        uint256 startIndex,
        uint256 batchSize
    ) external nonReentrant onlyOwner {
        require(startIndex < memeListArray.length, "F6");
        uint256 length = memeListArray.length;
        uint256 endIndex = startIndex + batchSize;
        if (endIndex > length) {
            endIndex = length;
        }

        for (uint256 i = startIndex; i < endIndex; i++) {
            address token = memeListArray[i];
            // External collectPoolFees inside a controlled loop with capped batchSize.
            // We acknowledge the risk and control gas usage via external batch processing.
            // slither-disable-next-line calls-loop
            try IERC20MEME(token).collectPoolFees() {
                emit CollectedPoolFees(memeListArray[i]);
            } catch {}
        }
    }

    /// @notice Collects pool fees from meme token
    /// @param meme Address of the meme token
    function collectPoolFees(address meme) external {
        emit CollectedPoolFees(meme);
        IERC20MEME(meme).collectPoolFees();
    }

    /**
     * @notice Pause create new token
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause create new token
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Pause token batch
     * @param startIndex Start index of memeListArray
     * @param batchSize batch size for memeListArray
     */
    function pauseTokensBatch(
        uint256 startIndex,
        uint256 batchSize
    ) external nonReentrant onlyOwner {
        require(startIndex < memeListArray.length, "F7");
        uint256 length = memeListArray.length;
        uint256 endIndex = startIndex + batchSize;
        if (endIndex > length) {
            endIndex = length;
        }

        for (uint256 i = startIndex; i < endIndex; i++) {
            address token = memeListArray[i];
            // External pause inside a controlled loop with capped batchSize.
            // We acknowledge the risk and control gas usage via external batch processing.
            // slither-disable-next-line calls-loop
            IERC20MEME(token).pause();
        }
    }

    /**
     * @notice Unpause token batch
     * @param startIndex Start index of memeListArray
     * @param batchSize batch size for memeListArray
     */
    function unpauseTokensBatch(
        uint256 startIndex,
        uint256 batchSize
    ) external nonReentrant onlyOwner {
        require(startIndex < memeListArray.length, "F8");
        uint256 length = memeListArray.length;
        uint256 endIndex = startIndex + batchSize;
        if (endIndex > length) {
            endIndex = length;
        }

        for (uint256 i = startIndex; i < endIndex; i++) {
            address token = memeListArray[i];
            // External unpause inside a controlled loop with capped batchSize.
            // We acknowledge the risk and control gas usage via external batch processing.
            // slither-disable-next-line calls-loop
            IERC20MEME(token).unpause();
        }
    }

    /// @notice Returns the number of meme tokens created
    function memeListArrayLength() external view returns (uint256) {
        return memeListArray.length;
    }
}
