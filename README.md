# Lime

Lime is a decentralized platform designed to enable anyone to launch their own meme coins with built-in protections against rug pulls. The platform ensures long-term sustainability by adding all funds obtained from minting directly into liquidity pools. Liquidity is further boosted through the partial buyback of tokens from the pool, thereby increasing both the liquidity and the value of the tokens within the pool.

The project is built on a factory pattern, where the main contract acts as a factory that creates custom meme tokens for users, making it easy for anyone to create and launch their own token.

## Tokentomics 

Lime democratizes meme coin creation, making it accessible to everyday users and enabling local communities to launch their own meme and social tokens. Unlike traditional token launches where the creator retains control over initial liquidity, Lime - decentralizing the coin meme and removes the author's control - enforces a mandatory issuance fee. This fee applies whether the token is minted by its creator or any other participant in the network. The collected issuance fees are not allocated to the token creator but instead deposited directly into a Uniswap V3 liquidity pool alongside the meme coin. This mechanism prevents rug pulls, ensuring that liquidity is always present to support market activity.

Beyond token issuance, Lime aims to integrate existing Web3 infrastructure with meme coins, leveraging them as instruments to generate total value locked (TVL) across multiple blockchain networks. By utilizing meme tokens as liquidity drivers within Uniswap V3 pools, Lime enhances liquidity provisioning, facilitates ecosystem growth, and stimulates higher transaction volumes and user engagement within the broader Web3 landscape.

### Key Economic Principles
1. **Mandatory Liquidity Provision:**
   - Every minted meme token incurs a fixed issuance fee.
   - This fee is automatically converted into liquidity within a Uniswap V3 pool.
   - The liquidity is permanently locked, protecting against rug pulls and ensuring market depth.
   - The influx of new liquidity fosters higher TVL, increasing protocol utility and sustainability.

2. **Market Impact and Adoption:**
   - By ensuring fair liquidity allocation, Lime reduces entry barriers for users interested in meme coins.
   - Encourages organic TVL and engagement by establishing sustainable liquidity pools.
   - Meme coins become an accessible gateway for users to explore and participate in Web3 ecosystems.


Comprehensive breakdowns of meme coin mining costs across different networks ([BNB](./docs/tokenomics/bnb.md), [Ethereum](./docs/tokenomics/ethereum.md), [HAQQ](./docs/tokenomics/ethereum.md), [BASE](./docs/tokenomics/base.md)) are available in the documentation: 📂 /docs/tokenomics
These calculations illustrate the relationships between meme coin supply, liquidity provision, and the resulting impact on TVL within each supported blockchain network.

## Dev

### Automated Cross-Network SmartContract Testing

This project includes an automated testing setup for smart contracts, ensuring they are tested across all supported networks with every commit to the repository. Whenever a change is made to the smart contracts, tests are executed on multiple networks to guarantee that the updates work correctly across all environments. This process provides confidence that any contract modifications will perform as expected, regardless of the network.

## Build

### NVM

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
nvm install 20
nvm use 20
nvm alias default 20
npm install npm --global # Upgrade npm to the latest version
```

### HardHat

```
npx hardhat compile
npx hardhat test
NETWORK=your_network npx hardhat test
npx hardhat run scripts/deploy.js --network your_network
```