// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";

import "./interfaces/IMemeFactory.sol";
import "./config.sol";
import "./interfaces/igetLiqudity.sol";

contract ERC20MEME_V2 is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable, ERC20BurnableUpgradeable {
    event Mint(address to, uint256 amount, uint256 spended);
    event PoolCreated(address token0, address token1, address pool);
    event TokenInitialized(address pairedToken, address pool);

    Config.Token public config;

    IMemeFactory public memeFactory;
    address public pool;
    address public pairedToken;

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
        config = IMemeFactory(msg.sender).getConfig();
        _mint(address(this), initialSupply_);
        pairedToken = pairedToken_;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public {
        require(
            ((pairedToken != address(0)) && (pool != address(0))),
            "The token must be initialized"
        );
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

    function initializePool() public onlyOwner {
        require(pairedToken != address(0), "Token can't be empty pool");
        require(pool == address(0), "Already initialized pool");

        uint256 withdrow = calculateValue(totalSupply());

        require(
            ERC20MEME_V2(pairedToken).allowance(msg.sender, address(this)) >= withdrow,
            "Factory allowance lower than InitialSupply"
        );

        require(
            ERC20MEME_V2(pairedToken).balanceOf(msg.sender) > withdrow,
            "Transfer token from factory failed"
        );

        require(
            ERC20MEME_V2(pairedToken).transferFrom(msg.sender, address(this), withdrow),
            "Transfer token from factory failed"
        );

        createPool();
        addInitialLiquidity();
        emit TokenInitialized(pairedToken, pool);
    }

    function createPool() internal {
        (address token0, address token1) = address(this) < pairedToken
            ? (address(this), pairedToken)
            : (pairedToken, address(this));

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        require(amount0 > 0, "Amount of token0 must be greater than 0");

        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount1 > 0, "Amount of token1 must be greater than 0");

        pool = IUniswapV3Factory(config.factory).getPool(
            token0,
            token1,
            config.pool.fee
        );
        if (pool == address(0)) {
            pool = IUniswapV3Factory(config.factory).createPool(
                token1,
                token0,
                config.pool.fee
            );
            require(pool != address(0), "Failed to create the pool");
        }
        emit PoolCreated(token0, token1, pool);

        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        if (sqrtPriceX96 == 0) {
            sqrtPriceX96 = igetLiquidity(config.getLiquidity).getSqrtPriceX96(
                amount1,
                amount0
            );
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            (uint160 newSqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool)
                .slot0();
            require(newSqrtPriceX96 != 0, "Failed to initialize the pool");
        }
    }

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        require(msg.sender == pool, "Callback must be from pool");
        (address token0, address token1) = abi.decode(data, (address, address));
        IERC20(address(token0)).transfer(msg.sender, amount0);
        IERC20(address(token1)).transfer(msg.sender, amount1);
    }

    function addInitialLiquidity() internal {
        (address token0, address token1) = address(this) < pairedToken
            ? (address(this), pairedToken)
            : (pairedToken, address(this));

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        require(amount0 > 0, "Amount of token0 must be greater than 0");
        IERC20(token0).approve(pool, amount0);

        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount1 > 0, "Amount of token1 must be greater than 0");
        IERC20(token1).approve(pool, amount1);

        require(config.getLiquidity != address(0), "getLiquidity must be");
        require(pool != address(0), "pool must be");
        uint128 liquidityAmount = igetLiquidity(config.getLiquidity)
            .getLiquidity(amount0, amount1);

        IUniswapV3Pool(pool).mint(
            address(this),
            (config.pool.minTick / config.pool.tickSpacing) *
                config.pool.tickSpacing,
            (config.pool.maxTick / config.pool.tickSpacing) *
                config.pool.tickSpacing,
            liquidityAmount,
            abi.encode(token0, token1)
        );
        require(
            IUniswapV3Pool(pool).liquidity() > 0,
            "AddInitialLiquidity falt"
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
