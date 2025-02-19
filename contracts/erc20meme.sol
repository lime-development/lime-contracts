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

import "./memeFactory.sol";
import "./config.sol";
import "./igetLiqudity.sol";
import "./ERC20PoolV3.sol";

contract ERC20MEME is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    ERC20PoolV3
{
    event Mint(address to, uint256 amount, uint256 spended);
    MemeFactory public memeFactory;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply_,
        address pairedToken_
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        __ERC20Permit_init(name);
        __UUPSUpgradeable_init();
        __ERC20PoolV3_init(pairedToken_, MemeFactory(msg.sender).getConfig());
        _mint(address(this), initialSupply_**decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public {
        require( poolInitialized, "The token pool must be initialized" );
        (uint256 poolAmount, uint256 protocolFee) = calculatePrice(amount);
        uint256 withdrow = poolAmount + protocolFee;
        require(
            withdrow > 0,
            "The withdrowAmount greater than zero is required for a mint."
        );

        require(
            IERC20(pairedToken).balanceOf(msg.sender) >= withdrow,
            "Insufficient token balance"
        );
        require(
            IERC20(pairedToken).allowance(msg.sender, address(this)) >= withdrow,
            "No token allowance has been issued"
        );
        require(
            IERC20(pairedToken).transferFrom(msg.sender, address(this), poolAmount),
            "Transfer token failed"
        );
        require(
            IERC20(pairedToken).transferFrom(msg.sender, owner(), protocolFee),
            "Transfer token failed"
        );

        IERC20(pairedToken).approve(config.swapRouter, poolAmount);

        uint256 toPool = IV3SwapRouter(config.swapRouter).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: address(pairedToken),
                tokenOut: address(this),
                fee: config.pool.fee,
                recipient: address(this),
                amountIn: poolAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        require(toPool > 0, "Swap to mint failed");

        _burn(address(this), toPool);
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
                ((amount * amount) / 2) *
                10 ** (externalDecimals - decimals());
        } else {
            _price =
                ((amount * amount) / 2) /
                10 ** (decimals() - externalDecimals);
        }
        return _price;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
