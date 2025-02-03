// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

//import "./erc20meme.sol";

contract MemeFactory  {
    event ERC20Created(address proxy);
    event ERC20Upgraded(address proxy, address newImplementation);

    mapping(uint256 => address) public memelist;
    uint256 public memeid;
    address public implementation;

    constructor(address _initialImplementation) {
        implementation = _initialImplementation;
    }
    function createERC20(string memory name, string memory symbol, uint256 initialSupply) external returns (address) {
        memeid++;
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            address(this),
            abi.encodeWithSignature("initialize(string,string,uint256)", name, symbol, initialSupply)
        );

        address proxyAddress = address(proxy);
        memelist[memeid] = proxyAddress;
        emit ERC20Created(proxyAddress);
        return proxyAddress;
    }

    function updateImplementation(address newImplementation) external  {
        implementation = newImplementation;
         for (uint256 i = 1; i <= memeid; i++){
            address proxy = memelist[i];
            ITransparentUpgradeableProxy(payable(proxy)).upgradeToAndCall(newImplementation,"");
            emit ERC20Upgraded(proxy, newImplementation);
         }
    }
}
