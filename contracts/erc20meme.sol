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


import {IMemeFactory} from "./interfaces/IMemeFactory.sol";
import {Config} from "./config.sol";
import {igetLiquidity} from "./interfaces/igetLiqudity.sol";
import {ERC20PoolV3} from "./ERC20PoolV3.sol";
import {Versioned} from "./Versioned.sol";

contract ERC20MEME is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    ERC20PoolV3,
    ReentrancyGuardUpgradeable,
    Versioned 
{
    using SafeERC20 for IERC20;

    event Mint(address indexed to, uint256 amount, uint256 poolAmount, uint256 protocolFee);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

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

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
 
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

    function calculatePrice(
        uint256 amount
    ) public view returns (uint256 poolAmount, uint256 protocolFee) {
        require(amount > 0, "Amount must be greater than zero.");
        poolAmount =
            calculateValue(totalSupply() + amount) - calculateValue(totalSupply());
        protocolFee = (poolAmount * config.protocolFee) / 100000;
    }

    /// factorial X^2 = 1/3 * X^3
    function calculateValue (
        uint256 amount
    ) public view returns (uint256 _price) {
        _price = ((amount * amount * amount) / config.divider);
    }

    function collectPoolFees() external onlyOwner {
        (uint256 amount0, uint256 amount1) = _collectPoolFees();
        (address token0, address token1) = getTokens();
        require(((amount0>0)||(amount1>0)), "Amount must be not 0");
        IERC20(token0).safeTransfer(owner(), amount0);
        IERC20(token1).safeTransfer(owner(), amount1);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
