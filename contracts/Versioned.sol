// SPDX-License-Identifier: MIT
// 
// This software is licensed under the MIT License for non-commercial use only.
// Commercial use requires a separate agreement with the author.
pragma solidity ^0.8.20;

 * @title Versioned
 * @dev Contract that provides a unique version identifier based on its deployed bytecode.
 * @author Vorobev Sergei
 */
contract Versioned  {
    /**
     * @notice Returns a unique identifier (hash) of the contract's bytecode.
     * @dev Uses inline assembly to retrieve the contract's deployed bytecode and compute its keccak256 hash.
     * This allows tracking of different contract versions based on their actual code.
     * @return bytes32 Keccak256 hash of the contract's bytecode.
     */
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
