require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-truffle5");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config(); 

const network = process.env.NETWORK || "sepolia";

const FORK_CONFIGS = {
  sepolia: {
    url: "https://sepolia.drpc.org", 
    blockNumber: 7807110, 
  },
  ethereum: {
    url: "https://eth.drpc.org", 
    blockNumber: 21954300, 
  },
  base: {
    url: "https://rpc.ankr.com/base", 
    blockNumber: 27035700, 
  },
  bnb: {
    url: "https://rpc.ankr.com/bsc",
    blockNumber: 47093000, 
  },
  haqq: {
    url: "https://rpc.eth.haqq.network",
    blockNumber: 15687757,
  }
};

// Проверяем, существует ли указанная сеть
if (!FORK_CONFIGS[network]) {
  throw new Error(`❌ Unknown network: ${network}`);
}

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
      }
    ],
  },  
  networks: {
    hardhat: {
      forking: {
        url: FORK_CONFIGS[network].url,
        blockNumber: FORK_CONFIGS[network].blockNumber,
      },
      
    },
    'haqq-testedge2': {
      url: `https://rpc.eth.testedge2.haqq.network`,
      accounts: [process.env.PRIVATE_KEY],
    },
    sepolia: {
      url: "https://sepolia.drpc.org",
      accounts: [process.env.PRIVATE_KEY],
    },
    haqq: {
      url: "https://rpc.eth.haqq.network",
      accounts: [process.env.PRIVATE_KEY],
    }
  }
};
