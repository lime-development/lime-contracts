// This script interacts with an already deployed MemeFactory and calls the creation of an ERC20 token
// Usage: FACTORY_ADDRESS=0x45Af664A7DEfa2F124950DE4aFde16b74c33276d  npx hardhat run scripts/onchain-test.js --network bobaTestnet

const { ethers, upgrades } = require("hardhat");
const { networks } = require("./config");

async function main() {  // Get signer (first account from hardhat)
  if (!networks[hre.network.name]) {
    throw new Error(`Unsupported or missing network. Please specify a valid network (e.g., 'ethereum', 'sepolia', 'haqq', etc.)`);
  }
  const networkConfig = networks[hre.network.name];
  
  const [signer] = await ethers.getSigners();
  console.log("Testing contracts with the account:", signer.address);
  // MemeFactory address can be set via environment variable or directly in the script
  const FACTORY_ADDRESS = process.env.FACTORY_ADDRESS || "<INSERT_ADDRESS_HERE>";

  const FEE_DENOMINATOR = BigInt(100000);

  // Debug output for config values
  console.log("initialMintCost:", networkConfig.initialMintCost);
  console.log("protocolFee:", networkConfig.protocolFee);
  console.log("FEE_DENOMINATOR:", FEE_DENOMINATOR.toString());

  // Wrap token (e.g., WETH)
  const WRAP_TOKEN_ADDRESS = networkConfig.token;
  console.log("WRAP_TOKEN_ADDRESS:", WRAP_TOKEN_ADDRESS);
  
  const initialMintCost = BigInt(networkConfig.initialMintCost);
  const protocolFee = (initialMintCost * BigInt(networkConfig.protocolFee)) / FEE_DENOMINATOR;
  const approveAmount = initialMintCost + protocolFee;
  const WETH = await ethers.getContractAt("IWETH9", WRAP_TOKEN_ADDRESS, signer);
  console.log(`Wrapping ${initialMintCost} wei to WETH at: ${WRAP_TOKEN_ADDRESS}`);
  const wrapTx = await WETH.deposit({ value: initialMintCost });
  await wrapTx.wait();
  console.log(`Wrapped successfully!`);

  // Approve MemeFactory to spend WETH (initialMintCost + protocolFee)
  console.log(`Approving MemeFactory at ${FACTORY_ADDRESS} to spend WETH: ${approveAmount} wei...`);
  const approveTx = await WETH.approve(FACTORY_ADDRESS, approveAmount);
  await approveTx.wait();
  console.log(`Approve successful!`);

  // Connect to MemeFactory contract
  const MemeFactory = await ethers.getContractAt("MemeFactory", FACTORY_ADDRESS, signer);

  // Parameters for the new token
  const name = "OnchainTestToken";
  const symbol = "OCTT";

  // Call token creation
  console.log(`Creating token ${name} (${symbol}) via MemeFactory at: ${FACTORY_ADDRESS}`);
  const tx = await MemeFactory.createERC20(name, symbol);
  const receipt = await tx.wait();

  // Get the address of the created token from the event
  const event = receipt.logs.find(log => log.fragment && log.fragment.name === "ERC20Created");
  const tokenAddress = event ? event.args[0] : null;

  if (tokenAddress) {
    console.log(`Token successfully created! Address: ${tokenAddress}`);
  } else {
    console.log("Failed to get the address of the created token from the event.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
}); 