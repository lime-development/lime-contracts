// SPDX-License-Identifier: MIT
//
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable, IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import {IMemeFactory} from "./interfaces/IMemeFactory.sol";
import {Config} from "./config.sol";
import {igetLiquidity} from "./interfaces/igetLiqudity.sol";
import {ERC20PoolV3} from "./ERC20PoolV3.sol";

/**
 * @title ERC20MEME
 * @dev An upgradeable ERC20 token with minting, liquidity management, and protocol fee collection.
 * This contract extends multiple OpenZeppelin upgradeable modules and integrates Uniswap V3 liquidity management.
 *
 * Features:
 * - UUPS (Universal Upgradeable Proxy Standard) upgradeability.
 * - Ownable functionality with restricted access control.
 * - Reentrancy protection for secure token minting.
 * - Liquidity pool interaction via ERC20PoolV3.
 * - Uses `SafeERC20` for safe token transfers.
 */
contract ERC20MEME is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    ERC20PoolV3,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    /// @notice Token author
    address author;

    /// @notice Total minted tokens
    uint256 totalMinted;

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

    /// @dev Constructor disables initializers to prevent direct deployment.
    /// This contract should be deployed via a proxy using OpenZeppelin's upgradeable mechanism.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

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
    ) public initializer {
        require(pairedToken_ != address(0), "pairedToken must be not 0x0");
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        __ERC20Permit_init(name);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __ERC20PoolV3_init(pairedToken_, IMemeFactory(msg.sender).getConfig());
        _mint(address(this), config.initialSupply);
        totalMinted = config.initialSupply;
        require(author_ != address(0), "author_ must be not 0x0");
        author = author_;
    }

    /**
     * @notice Overrides the ERC20 decimals function to set 6 decimal places.
     * @return uint8 The number of decimal places for the token.
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @notice Mints new tokens and manages liquidity allocation.
     * The funds received for the mint go into the token's liquidity pool.
     * @dev Requires non-zero amounts and applies protocol fees.
     * @param to The address receiving the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(
        address to,
        uint256 amount
    ) public nonReentrant whenNotPaused {
        (
            uint256 poolAmount,
            uint256 protocolFee,
            uint256 authorFee
        ) = calculatePrice(amount);
        uint256 withdraw = poolAmount + protocolFee + authorFee;

        require(
            withdraw > 0,
            "The withdrawAmount greater than zero is required for a mint."
        );

        IERC20(pairedToken).safeTransferFrom(
            msg.sender,
            address(this),
            withdraw
        );

        _mint(to, amount);
        totalMinted += amount;

        IERC20(pairedToken).safeTransfer(author, authorFee);
        IERC20(pairedToken).safeTransfer(owner(), protocolFee);

        swap(pairedToken, poolAmount / 2, 0);
        addLiquidity();

        emit Mint(to, amount, poolAmount, protocolFee);
    }

    /**
     * @notice Burns a specific amount of tokens from the caller's account.
     * @dev Reduces the total supply.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero.");
        _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }

    /**
     * @notice Calculates the required pool contribution and protocol fee for minting tokens.
     * @param amount The amount of tokens to be minted.
     * @return poolAmount The required liquidity pool contribution.
     * @return protocolFee The protocol fee deducted from the pool amount.
     */
    function calculatePrice(
        uint256 amount
    )
        public
        view
        returns (uint256 poolAmount, uint256 protocolFee, uint256 authorFee)
    {
        require(amount > 0, "Amount must be greater than zero.");
        poolAmount =
            calculateValue(totalMinted + amount) -
            calculateValue(totalMinted);
        protocolFee = (poolAmount * config.protocolFee) / 100000;
        authorFee = (poolAmount * config.authorFee) / 100000;
    }

    /**
     * @notice Computes a liquidity-based valuation using a cubic function.
     * @dev Uses the formula: factorial X^2 = 1/3 * X^3 / divider`.
     * @param amount The token amount to calculate its value.
     * @return _price The computed value based on liquidity mechanics.
     */
    function calculateValue(
        uint256 amount
    ) public view returns (uint256 _price) {
        require(amount < type(uint128).max, "Amount too large");
        _price =
            ((amount ** 2) / config.divider) +
            ((config.initialMintCost * amount) /
                (config.initialSupply * 10000));
    }

    /**
     * @notice Collects accumulated pool fees and transfers them to the contract owner.
     * @dev Ensures at least one token amount is greater than zero.
     */
    function collectPoolFees() external nonReentrant onlyOwner {
        address currentOwner = owner();

        (uint256 amount0, uint256 amount1) = _collectPoolFees();
        (address token0, address token1) = getTokens();

        require(((amount0 > 0) || (amount1 > 0)), "Amount must be not 0");

        uint256 authorAmount0 = (amount0 * config.authorFee) /
            (config.protocolFee + config.authorFee);
        uint256 authorAmount1 = (amount1 * config.authorFee) /
            (config.protocolFee + config.authorFee);

        IERC20(token0).safeTransfer(author, authorAmount0);
        IERC20(token1).safeTransfer(author, authorAmount1);
        IERC20(token0).safeTransfer(currentOwner, amount0 - authorAmount0);
        IERC20(token1).safeTransfer(currentOwner, amount1 - authorAmount1);
    }

    /**
     * @notice Authorizes upgrades to the contract.
     * @dev This function ensures only the contract owner can upgrade the implementation.
     * @param newImplementation The address of the new contract implementation.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @notice Pause mint from factory
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause mint from factory
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
