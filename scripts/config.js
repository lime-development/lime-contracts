const fs = require('fs');
const path = require('path');

const poolConfig = JSON.parse(fs.readFileSync(path.join(__dirname, '../config/pool.config.json'), 'utf-8'));
const rawNetworks = JSON.parse(fs.readFileSync(path.join(__dirname, '../config/networks.config.json'), 'utf-8'));

// Преобразуем строковые BigInt обратно в BigInt
const networks = {};
for (const [key, config] of Object.entries(rawNetworks)) {
  networks[key] = {
    ...config,
    initialSupply: BigInt(config.initialSupply),
    initialMintCost: BigInt(config.initialMintCost),
    requestedOwnerTokenAmounts: BigInt(config.requestedOwnerTokenAmounts),
    requestedAuthorTokenAmounts: BigInt(config.requestedAuthorTokenAmounts),
  };
}

module.exports = { poolConfig, networks };