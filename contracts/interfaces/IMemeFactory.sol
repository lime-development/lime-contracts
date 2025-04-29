// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../config.sol";

interface IMemeFactory {
    /// @notice Emitted when a new meme token is created
    /// @param proxy Address of the created meme token proxy
    /// @param author Meme author address
    event ERC20Created(address proxy, address author);

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
    event ERC20ImplementationUpdated(address newImplementation);

    /// @notice Emitted when the fee was collected from token pool
    /// @param token token address
    event CollectedPoolFees(address token);

    /**
     * @notice Initializes the Factory with initial configuration for ERC20.
     * Called once during proxy deployment by OpenZeppelin Upgrades plugin. DO NOT call directly.
     * @param initialImplementation_ Address of the initial implementation contract
     * @param config_ Factory and meme token configuration
     */
    function initialize(
        address initialImplementation_,
        Config.Token calldata config_
    ) external;

    /// @notice Returns the current configuration for ERC20 tokens
    /// @return The current token configuration
    function getConfig() external view returns (Config.Token memory);

    /// @notice Updates the for ERC20 tokens configuration
    /// @param _config New configuration values
    function updateConfig(Config.Token memory _config) external;

    /// @notice Withdraws protocol fees to the owner
    /// @param tokenAddress Address of the token to withdraw
    /// @param amount Amount to withdraw
    function withdrawProcotolFee(address tokenAddress, uint256 amount) external;

    /// @notice Creates a new ERC20 token (meme), create liquidity pool for meme
    /// and provide initial liquidity to pool
    /// @param name Name of the token
    /// @param symbol Symbol of the token
    /// @return Address of the newly created ERC20 token proxy
    /// @dev The token is created by the author, so in this method only the platform receives a commission.
    function createERC20(
        string memory name,
        string memory symbol
    ) external returns (address);

    /// @notice Updates the implementation contract
    /// @param newImplementation Address of the new implementation contract
    function updateImplementation(address newImplementation) external;

    /// @notice Updates the implementation contract for a batch of tokens
    /// @param startIndex Start index of memeListArray
    /// @param batchSize batch size for memeListArray
    function updateTokensBatch(uint256 startIndex, uint256 batchSize) external;

    /// @notice Collects pool fees from all token
    function collectPoolsFees() external;

    /// @notice Collects pool fees from meme token
    /// @param meme Address of the meme token
    function collectPoolFees(address meme) external;

    ///@notice Pause create new token
    function pause() external;

    ///@notice Unpause create new token
    function unpause() external;

    /**
     * @notice Pause token batch
     * @param startIndex Start index of memeListArray
     * @param batchSize batch size for memeListArray
     */
    function pauseTokensBatch(uint256 startIndex, uint256 batchSize) external;

    /**
     * @notice Unpause token batch
     * @param startIndex Start index of memeListArray
     * @param batchSize batch size for memeListArray
     */
    function unpauseTokensBatch(uint256 startIndex, uint256 batchSize) external;

    /// @notice Returns the configuration parameters for pool and liquidity management.
    function config()
        external
        view
        returns (
            address factory,
            address pairedToken,
            address getLiquidity,
            uint256 initialSupply,
            uint256 initialMintCost,
            uint24 fee,
            int24 tickSpacing,
            int24 minTick,
            int24 maxTick,
            uint256 protocolFee,
            uint256 authorFee,
            uint256 divider
        );

    /// @notice Returns the address of a meme token at the given index in the list.
    function memeListArray(uint256 index) external view returns (address);

    /// @notice Returns the address of implementation.
    function implementation() external view returns (address);
}
