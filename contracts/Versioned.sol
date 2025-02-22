// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Versioned  {
    // Функция для получения хеша версии
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

        // Хешируем байткод с помощью keccak256
        return keccak256(bytecode);
    }
}