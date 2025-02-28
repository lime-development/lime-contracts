# Noorim

Noorim is a decentralized platform designed to enable anyone to launch their own meme coins with built-in protections against rug pulls. The platform ensures long-term sustainability by adding all funds obtained from minting directly into liquidity pools. Liquidity is further boosted through the partial buyback of tokens from the pool, thereby increasing both the liquidity and the value of the tokens within the pool.

The project is built on a factory pattern, where the main contract acts as a factory that creates custom meme tokens for users, making it easy for anyone to create and launch their own token.

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
npx hardhat run scripts/deploy.js --network your_network
```