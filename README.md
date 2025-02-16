# Noorim
Noorim

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