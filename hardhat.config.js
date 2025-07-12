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
    url: `https://rpc.eth.haqq.network`,
  },
  boba: {
    url: `https://mainnet.boba.network`, 
  },
  OG: {
    url: `https://rpc.ankr.com/0g_galileo_testnet_evm`,
    rateLimit: {
      maxRequests: 1,
      perMilliseconds: 1000
    }
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
      },
      {
        version: "0.5.17",
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
      initialBaseFeePerGas: 0,
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
    },
    OG: {
      url: `https://rpc.ankr.com/0g_galileo_testnet_evm`,
      accounts: [process.env.PRIVATE_KEY],
      rateLimit: {
        maxRequests: 1,
        perMilliseconds: 1000
      }
    }
  },
  etherscan: {
    apiKey: {
      'sepolia': 'empty'
    },
    customChains: [
      {
        network: "sepolia",
        chainId: 11155111,
        urls: {
          apiURL: "https://eth-sepolia.blockscout.com/api",
          browserURL: "https://eth-sepolia.blockscout.com"
        }
      }
    ]
  }
};
