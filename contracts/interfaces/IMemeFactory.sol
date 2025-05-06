// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "../config.sol";

interface IMemeFactory {
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

    /// @notice Precision denominator for fee calculations (0.001%)
    // slither-disable-next-line naming-convention
    function FEE_DENOMINATOR() external pure returns (uint256);

    /// @notice Returns the address of a meme token at the given index in the list.
    function memeListArray(uint256 index) external view returns (address);

    /// @notice Address the current implementation contract for ERC20 contracts.
    function implementation() external pure returns (address);

    /// @notice Returns the current configuration for ERC20 tokens
    /// @return The current token configuration
    function config() external view returns (Config.Token memory);

    /**
     * @notice Initializes the Factory with initial configuration for ERC20.
     * Called once during proxy deployment by OpenZeppelin Upgrades plugin. DO NOT call directly.
     * @param initialImplementation Address of the initial implementation contract for ERC20 tokens
     * @param tokensConfig Factory and meme token configuration
     */
    function initialize(
        address initialImplementation,
        Config.Token calldata tokensConfig
    ) external;

    /// @notice Returns the current configuration for ERC20 tokens
    /// @return The current token configuration
    function getConfig() external view returns (Config.Token memory);

    /// @notice Updates the for ERC20 tokens configuration
    /// @param tokensConfig New configuration values
    function updateConfig(Config.Token memory tokensConfig) external;

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
    function collectPoolsFees(uint256 startIndex, uint256 batchSize) external;

    /// @notice Collects pool fees from meme token
    /// @param meme Address of the meme token
    function collectPoolFees(address meme) external;

    /**
     * @notice Pause create new token
     */
    function pause() external;

    /**
     * @notice Unpause create new token
     */
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

    /// @notice Returns the number of meme tokens created
    function memeListArrayLength() external view returns (uint256);
}
