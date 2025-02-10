// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./memeFactory.sol";

interface igetLiquidity {
    function getLiquidity(
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity);
}

contract ERC20MEME is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    MemeFactory public memeFactory;
    address public pool;
    address public getLiquidity;
    address public tokenPair;

    IV3SwapRouter swapRouter;
    IUniswapV3Factory factory;

    uint256 public initialSupply;

    uint24  public constant poolFee = 3000 ; // Fee tier (e.g., 3000 = 0.3%)
    int24 public constant TICK_SPACING = 60; // примерное значение
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply_,
        address getLiquidity_/*,
        address swapRouter_,
        address factory_*/

    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        __ERC20Permit_init("ERC20V1");
        __UUPSUpgradeable_init();
        getLiquidity = getLiquidity_;
        memeFactory = MemeFactory(msg.sender);
        initialSupply = initialSupply_;
        swapRouter = IV3SwapRouter(0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E);
        factory = IUniswapV3Factory(0x0227628f3F023bb0B980b67D528571c95c6DaC1c);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public {  
        require(tokenPair!=address(0), "The token must be initialized");
        uint256 withdrow = calculateValue(totalSupply()+amount)-calculateValue(totalSupply());
        require(withdrow > 0 , "The withdrowAmount greater than zero is required for a mint.");
    

        require(IERC20(tokenPair).balanceOf(msg.sender) >= withdrow, "Insufficient BTC balance");
        require(IERC20(tokenPair).allowance(msg.sender,address(this)) >= withdrow, "No BTC allowance has been issued");
        require(IERC20(tokenPair).transferFrom(msg.sender, address(this),withdrow), "Transfer WBTC failed");

        IERC20(tokenPair).approve(address(memeFactory.getPoolData().swapRouter), withdrow);
        
        uint256 toPool = memeFactory.getPoolData().swapRouter.exactInputSingle(  IV3SwapRouter.ExactInputSingleParams ({
        tokenIn:  address(tokenPair),
        tokenOut: address(this),
        fee: memeFactory.getPoolData().config.fee,
        recipient: address(this),
        amountIn: withdrow,
        amountOutMinimum: 0,
        sqrtPriceLimitX96:0
        }));
        require(toPool>0, "Swap to mint failed");

        _burn(address(this), toPool);
        _mint(to, amount);
    }
    
    /// factorial X^2 = 1/3 * X^3
    function calculateValue(
        uint256 amount
    ) public view returns (uint256 _price) {
        _price = amount;
        /*
        uint8 externalDecimals = ERC20Upgradeable(tokenPair).decimals();
        if(externalDecimals>decimals()){
            _price = (amount * amount * amount / 3)*10**(externalDecimals-decimals());
        } else {
            _price = (amount * amount * amount / 3)/10**(decimals()-externalDecimals);
        }
        return _price;*/
    }

    function initializePool(address token) public onlyOwner {
        require(token != address(0), "Token can't be empty pool");
        require(pool == address(0), "Already initialized pool");
        tokenPair = token;

        uint256 withdrow = calculateValue(initialSupply);
        _mint(address(this), initialSupply);

        require(
            IERC20(token).allowance(msg.sender, address(this)) >= withdrow,
            "Factory allowance lower than InitialSupply"
        );

        require(
            IERC20(token).transferFrom(msg.sender, address(this), withdrow),
            "Transfer token from factory failed"
        );

        createPool(token);
        addInitialLiquidity(token);
    }
    
    function createPool(address token) internal {
        (address token0, address token1) = address(this) < token
            ? (address(this), token)
            : (token, address(this));

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        require(amount0 > 0, "Amount of token0 must be greater than 0");

        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount1 > 0, "Amount of token1 must be greater than 0");

        pool = factory.getPool(
            token0,
            token1,
            3000
        );
        if (pool == address(0)) {
            pool = factory.createPool(
                token1,
                token0,
                3000
            );
            require(pool != address(0), "Failed to create the pool");
        }

        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        if (sqrtPriceX96 == 0) {
            sqrtPriceX96 = uint160(
                (sqrt(
                    amount1
                ) * 2 ** 96) /
                    sqrt(
                        amount0
                    )
            );
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            (uint160 newSqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool)
                .slot0();
            require(newSqrtPriceX96 != 0, "Failed to initialize the pool");
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) public {
        (address token0, address token1) = abi.decode(data, (address, address));
        IERC20(address(token0)).transfer(msg.sender, amount0);
        IERC20(address(token1)).transfer(msg.sender, amount1);
    }

    function addInitialLiquidity(address token) internal {
        (address token0, address token1) = address(this) < token
        ? (address(this), token)
         : (token, address(this));

        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        require(amount0 > 0, "Amount of token0 must be greater than 0");
        IERC20(token0).approve(pool, amount0);

        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        require(amount1 > 0, "Amount of token1 must be greater than 0");
        IERC20(token1).approve(pool, amount1);

        require(getLiquidity !=  address(0), "getLiquidity must be");
        require(pool !=  address(0), "pool must be");
        uint128 liquidityAmount = igetLiquidity(getLiquidity).getLiquidity(amount0, amount1);

       IUniswapV3Pool(pool).mint(
            address(this),
            (MIN_TICK / TICK_SPACING) * TICK_SPACING,
            (MAX_TICK / TICK_SPACING) * TICK_SPACING,
            liquidityAmount,
            abi.encode(token0, token1)
        );
        require(IUniswapV3Pool(pool).liquidity() > 0, "AddInitialLiquidity falt");
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
