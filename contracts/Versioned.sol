// SPDX-License-Identifier: MIT
// 
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.
pragma solidity ^0.8.20;

contract Versioned  {
    function version() public view returns (bytes32) {
        address _address = address(this);
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }

        bytes memory bytecode = new bytes(size);
        assembly {
            extcodecopy(_address, add(bytecode, 0x20), 0, size)
        }
        return keccak256(bytecode);
    }
}