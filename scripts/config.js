const poolConfig = {
    fee: 3000,
    tickSpacing: 60,
    minTick: -887272,
    maxTick: 887272
  };
  
  const networks = {
    haqq: {
      name: "haqq",
      networkID: 11235,
      initialSupply: BigInt(10000 * 10 ** 6), 
      initialMintCost: BigInt(100 * 10 ** 18),
      divider: 35,
      protocolFee: 2500,
      factory: "0xc35DADB65012eC5796536bD9864eD8773aBc74C4",
      token: "0xeC8CC083787c6e5218D86f9FF5f28d4cC377Ac54",
      whale: "0x6A0ea3a37711928e646d0B3258781EB8b7732D1d"
    },
    sepolia: { 
      name: "sepolia",
      networkID: 11155111,
      initialSupply: BigInt(100000 * 10 ** 6), 
      initialMintCost: BigInt(200 * 10 ** 14),
      divider: 3500000,
      protocolFee: 1000,
      factory: "0x0227628f3F023bb0B980b67D528571c95c6DaC1c",
      token: "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14",
      whale: "0xBaEb92889696217A3A6be2175E5a95dC4cFFC9f7" 
    },
    base: {
      name: "base",
      networkID: 8453,
      initialSupply: BigInt(100000 * 10 ** 6), 
      initialMintCost: BigInt(200 * 10 ** 14),
      divider: 3500000,
      protocolFee: 1000,
      factory: "0x33128a8fC17869897dcE68Ed026d694621f6FDfD",
      token: "0x4200000000000000000000000000000000000006",
      whale: "0xC1233286aCdb6bed1A1C902d3ed01960Aaf34e0D" 
    },
    ethereum: { 
      name: "ethereum",
      networkID: 1,
      initialSupply: BigInt(100000 * 10 ** 6), 
      initialMintCost: BigInt(200 * 10 ** 14),
      divider: 3500000,
      protocolFee: 1000,
      factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984",
      token: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      whale: "0x6B44ba0a126a2A1a8aa6cD1AdeeD002e141Bcd44"
    },
    bnb: { 
      name: "bnb", 
      networkID: 56,
      initialSupply: BigInt(100000 * 10 ** 6), 
      initialMintCost: BigInt(200 * 10 ** 14),
      divider: 500000,
      protocolFee: 1000,
      factory: "0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7", 
      token: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", 
      whale: "0x308000D0169Ebe674B7640f0c415f44c6987d04D"
    }
  };
  
  module.exports = { poolConfig, networks };  