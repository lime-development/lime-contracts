require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();
require("solidity-docgen");

const network = process.env.NETWORK || "sepolia";

const FORK_CONFIGS = {
  sepolia: {
    url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
  },
  ethereum: {
    url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
  },
  base: {
    url: `https://base-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
  },
  bnb: {
    url: `https://bnb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
  },
  haqq: {
    url: "https://rpc.eth.haqq.network",
  }
};

// Проверяем, существует ли указанная сеть
if (!FORK_CONFIGS[network]) {
  throw new Error(`❌ Unknown network: ${network}`);
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  docgen: {
    outputDir: './docs/contracts/', 
    pages: 'files',
    clear: true,
    runOnCompile: true,
    include: ['*.sol'],
    exclude: ['**/test/**'],
  },
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
          "viaIR": true,
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
