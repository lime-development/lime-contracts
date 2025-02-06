// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./memeFactory.sol";

contract ERC20MEME is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    MemeFactory public memeFactory;
    address public tokenPair;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol, uint256 initialSupply, address tokenPair_) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        __ERC20Permit_init("ERC20V1");
        __UUPSUpgradeable_init();
        _mint(msg.sender, initialSupply);
        tokenPair = tokenPair_;
        memeFactory = MemeFactory(msg.sender);
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
    function calculateValue(uint256 amount) public view returns (uint256 _price) {
        uint8 externalDecimals = ERC20MEME(tokenPair).decimals();
        if(externalDecimals>decimals()){
            _price = (amount * amount * amount / 3)*10**(externalDecimals-decimals());
        } else {
            _price = (amount * amount * amount / 3)/10**(decimals()-externalDecimals);
        }
        return _price;
    }  

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
