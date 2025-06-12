const { ethers, network } = require("hardhat");
const { poolConfig, networks } = require("./config");

async function main() {
  // Get factory address from environment variable
  const factoryAddress = process.env.FACTORY_ADDRESS;

  if (!factoryAddress) {
    console.error("Please set FACTORY_ADDRESS environment variable");
    console.error("Example: FACTORY_ADDRESS=0x1234...5678 npx hardhat run scripts/update-config.js --network OG");
    process.exit(1);
  }

  const networkName = network.name;
  if (!networks[networkName]) {
    throw new Error(`Unsupported or missing network. Please specify a valid network (e.g., 'ethereum', 'sepolia', 'haqq', etc.)`);
  }

  const [deployer] = await ethers.getSigners();
  console.log("Updating config with the account:", deployer.address);

  // Get configuration for the selected network
  const networkConfig = networks[networkName];

  // Connect to existing factory contract
  const factory = await ethers.getContractAt("MemeFactory", factoryAddress);
  console.log(`Connected to MemeFactory at: ${factoryAddress}`);

  // Get current configuration
  const currentConfig = await factory.getConfig();
  console.log("Current config:", currentConfig);

  // Create new configuration using existing getLiquidity value
  const newConfig = {
    factory: networkConfig.factory,
    getLiquidity: currentConfig.getLiquidity, // Use existing value
    initialSupply: networkConfig.initialSupply,
    protocolFee: networkConfig.protocolFee,
    authorFee: networkConfig.authorFee,
    initialMintCost: networkConfig.initialMintCost,
    divider: networkConfig.divider,
    pairedToken: networkConfig.token,
    pool: poolConfig
  };

  // Update configuration
  console.log("Updating config to:", newConfig);
  const tx = await factory.updateConfig(newConfig);
  await tx.wait();

  // Verify that configuration has been updated
  const updatedConfig = await factory.getConfig();
  console.log("Updated config:", updatedConfig);
  console.log("Config update completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 