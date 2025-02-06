require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-truffle5");
require("dotenv").config(); // Подключаем dotenv для загрузки переменных окружения

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.23",
        settings: {
          evmVersion: "paris",
          optimizer: {
            enabled: true,
            runs: 1000,
          }, 
        }
      },
      {
        version: "0.7.6",  
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          }, 
        }
      },
    ],
  },  
  networks: {
    local: {
      url: `http://127.0.0.1:7545`,
      accounts: [process.env.PRIVATE_KEY] // Загружаем PRIVATE_KEY из переменных окружения
    },
    hardhat: {
    /* forking: {
        url: "https://rpc.eth.haqq.network", 
        blockNumber: 15255512, 
      },*/
      forking: {
        url: "https://sepolia.drpc.org", 
        blockNumber: 7649193, 
      },
    },
    haqq_test: {
      url: `https://rpc.eth.testedge2.haqq.network`,
      accounts: [process.env.PRIVATE_KEY] // Исправлена ошибка в имени переменной
    },
    sepolia: {
      url: `https://ethereum-sepolia-rpc.publicnode.com`,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
