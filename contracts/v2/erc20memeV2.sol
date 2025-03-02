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


import {IMemeFactory} from "../interfaces/IMemeFactory.sol";
import {Config} from "../config.sol";
import {igetLiquidity} from "../interfaces/igetLiqudity.sol";
import {ERC20PoolV3} from "../ERC20PoolV3.sol";

contract ERC20MEMEV2 is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    ERC20PoolV3,
    ReentrancyGuardUpgradeable 
{
    using SafeERC20 for IERC20;

    /// @notice Emitted when new tokens are minted.
    /// @param to Recipient of the minted tokens.
    /// @param amount Number of tokens minted.
    /// @param poolAmount Amount allocated to the liquidity pool.
    /// @param protocolFee Fee collected for the protocol.
    event Mint(address indexed to, uint256 amount, uint256 poolAmount, uint256 protocolFee);

    
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
     */
    function initialize(
        string memory name,
        string memory symbol,
        address pairedToken_
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        __ERC20Permit_init(name);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __ERC20PoolV3_init(pairedToken_, IMemeFactory(msg.sender).getConfig());
        _mint(address(this), config.initialSupply);
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
    function mint(address to, uint256 amount) public nonReentrant  {
        (uint256 poolAmount, uint256 protocolFee) = calculatePrice(amount);
        uint256 withdraw = poolAmount + protocolFee;
        require(
            withdraw > 0,
            "The withdrowAmount greater than zero is required for a mint."
        );
        IERC20(pairedToken).safeTransferFrom(msg.sender, address(this), withdraw);
        IERC20(pairedToken).safeTransfer(owner(), protocolFee);

        swap(pairedToken, poolAmount/2);
        addLiquidity();
        _mint(to, amount);

        emit Mint(to, amount, poolAmount, protocolFee);
    }

    /**
     * @notice Calculates the required pool contribution and protocol fee for minting tokens.
     * @param amount The amount of tokens to be minted.
     * @return poolAmount The required liquidity pool contribution.
     * @return protocolFee The protocol fee deducted from the pool amount.
     */
    function calculatePrice(
        uint256 amount
    ) public view returns (uint256 poolAmount, uint256 protocolFee) {
        require(amount > 0, "Amount must be greater than zero.");
        poolAmount =
            calculateValue(totalSupply() + amount) - calculateValue(totalSupply());
        protocolFee = (poolAmount * config.protocolFee) / 100000;
    }

    /**
     * @notice Computes a liquidity-based valuation using a cubic function.
     * @dev Uses the formula: factorial X = 1/2 * X^2 / divider`.
     * @param amount The token amount to calculate its value.
     * @return _price The computed value based on liquidity mechanics.
     */ 
    function calculateValue (
        uint256 amount
    ) public view returns (uint256 _price) {
        _price = ((amount * amount) / config.divider);
    }

    /**
     * @notice Collects accumulated pool fees and transfers them to the contract owner.
     * @dev Ensures at least one token amount is greater than zero.
     */
    function collectPoolFees() external onlyOwner {
        (uint256 amount0, uint256 amount1) = _collectPoolFees();
        (address token0, address token1) = getTokens();
        require(((amount0>0)||(amount1>0)), "Amount must be not 0");
        IERC20(token0).safeTransfer(owner(), amount0);
        IERC20(token1).safeTransfer(owner(), amount1);
    }

    /**
     * @notice Authorizes upgrades to the contract.
     * @dev This function ensures only the contract owner can upgrade the implementation.
     * @param newImplementation The address of the new contract implementation.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
