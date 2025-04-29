// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20MEME {
    /// @notice Emitted when new tokens are minted.
    /// @param to Recipient of the minted tokens.
    /// @param amount Number of tokens minted.
    /// @param poolAmount Amount allocated to the liquidity pool.
    /// @param protocolFee Fee collected for the protocol.
    event Mint(
        address indexed to,
        uint256 amount,
        uint256 poolAmount,
        uint256 protocolFee
    );

    /// @notice Emitted when tokens are burned.
    /// @param from Address from which tokens were burned.
    /// @param amount Amount of tokens burned.
    event Burn(address indexed from, uint256 amount);

    /**
     * @notice Initializes the ERC20MEME contract.
     * @dev Can only be called once due to the `initializer` modifier.
     * Sets the token name, symbol, and initializes inherited upgradeable contracts.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param pairedToken_ The address of the paired token for liquidity.
     * @param author_ The address of the paired token for liquidity.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address pairedToken_,
        address author_
    ) external;

    /**
     * @notice Overrides the ERC20 decimals function to set 6 decimal places.
     * @return uint8 The number of decimal places for the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Mints new tokens and manages liquidity allocation.
     * The funds received for the mint go into the token's liquidity pool.
     * @dev Requires non-zero amounts and applies protocol fees.
     * @param to The address receiving the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burns a specific amount of tokens from the caller's account.
     * @dev Reduces the total supply.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external;

    /**
     * @notice Calculates the required pool contribution and protocol fee for minting tokens.
     * @param amount The amount of tokens to be minted.
     * @return poolAmount The required liquidity pool contribution.
     * @return protocolFee The protocol fee deducted from the pool amount.
     * @return authorFee The author fee deducted from the pool amount.
     */
    function calculatePrice(
        uint256 amount
    )
        external
        view
        returns (uint256 poolAmount, uint256 protocolFee, uint256 authorFee);

    /**
     * @notice Computes a liquidity-based valuation using a cubic function.
     * @dev Uses the formula: factorial X^2 = 1/3 * X^3 / divider`.
     * @param amount The token amount to calculate its value.
     * @return _price The computed value based on liquidity mechanics.
     */
    function calculateValue(
        uint256 amount
    ) external view returns (uint256 _price);

    /**
     * @notice Collects accumulated pool fees and transfers them to the contract owner.
     * @dev Ensures at least one token amount is greater than zero.
     */
    function collectPoolFees() external;

    ///@notice Pause mint from factory
    function pause() external;

    /// @notice Unpause mint from factory
    function unpause() external;

    /// @notice Creates and initializes the liquidity pool if it has not been initialized yet.
    /// @dev The function is separated from __ERC20PoolV3_init to perform approval on the contract address after Init.
    function initializePool() external;

    /// @notice Callback for UniswapV3Pool Swap
    /// @param data Data passed through by the addLiquidity() via the IUniswapV3PoolActions#Swap call
    function uniswapV3SwapCallback(
        int256 /*amount0Delta*/,
        int256 /*amount1Delta*/,
        bytes calldata data
    ) external;

    /// @notice Callback for UniswapV3Pool mint
    /// @param amount0 The amount of token0 due to the pool for the minted liquidity
    /// @param amount1 The amount of token1 due to the pool for the minted liquidity
    /// @param data Data passed through by the addLiquidity() via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Returns the token pair addresses in the correct order for Uniswap V3.
    function getTokens() external;

    /// @notice Returns the address of token author
    function author() external view returns (address);

    /// @notice Returns the total minted tokens
    function totalMinted() external view returns (uint256);

    /// @notice Returns the address of the Uniswap V3 pool used by this contract.
    function pool() external view returns (address);

    /// @notice Returns the address of the token paired in the liquidity pool.
    function pairedToken() external view returns (address);

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

    /// @notice Returns the lower tick boundary for the liquidity position.
    function tickLower() external view returns (int24);

    /// @notice Returns the upper tick boundary for the liquidity position.
    function tickUpper() external view returns (int24);
}
