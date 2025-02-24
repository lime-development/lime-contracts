// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";

import "../interfaces/IMemeFactory.sol";
import "../config.sol";
import "../interfaces/igetLiqudity.sol";
import "../ERC20PoolV3.sol";
import "../Versioned.sol";

contract ERC20MEMEV2 is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    ERC20PoolV3,
    Versioned 
{
    event Mint(address to, uint256 amount, uint256 spended);

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
        __ERC20PoolV3_init(pairedToken_, IMemeFactory(msg.sender).getConfig());
        _mint(address(this), config.initialSupply**decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
 
    function mint(address to, uint256 amount) public {
        (uint256 poolAmount, uint256 protocolFee) = calculatePrice(amount);
        uint256 withdrow = poolAmount + protocolFee;
        require(
            withdrow > 0,
            "The withdrowAmount greater than zero is required for a mint."
        );
        require(
            IERC20(pairedToken).transferFrom(msg.sender, address(this), poolAmount),
            "Transfer token failed"
        );
        require(
            IERC20(pairedToken).transferFrom(msg.sender, owner(), protocolFee),
            "Transfer token failed"
        );

        swap(pairedToken, poolAmount/2);
        addLiquidity();
        _mint(to, amount);
        emit Mint(to, amount, withdrow);
    }

    function calculatePrice(
        uint256 amount
    ) public view returns (uint256 poolAmount, uint256 protocolFee) {
        poolAmount =
            calculateValue(totalSupply() + amount) - calculateValue(totalSupply());
        protocolFee = (poolAmount * config.protocolFee) / 100000;
    }

    /// factorial X^2 = 1/3 * X^3
    function calculateValue(
        uint256 amount
    ) public view returns (uint256 _price) {
        uint8 externalDecimals = ERC20Upgradeable(pairedToken).decimals();
        if (externalDecimals > decimals()) {
            _price =
                ((amount * amount * amount) / 30000000 ) *
                10 ** (externalDecimals - decimals());
        } else {
            _price =
                ((amount * amount * amount) / 30000000 ) /
                10 ** (decimals() - externalDecimals);
        }
        return _price;
    }

    function collectPoolFees() external onlyOwner{
        (uint256 amount0, uint256 amount1) = _collectPoolFees();
        (address token0, address token1) = getTokens();
        IERC20(token0).transferFrom(msg.sender, owner(), amount0);
        IERC20(token1).transferFrom(msg.sender, owner(), amount1);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
