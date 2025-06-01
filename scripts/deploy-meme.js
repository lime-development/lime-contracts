const { poolConfig, networks } = require("./config");

async function main() {
  const ContractMEME = await ethers.getContractFactory("ERC20MEME");
  const ContractFactory = await ethers.getContractFactory("MemeFactory");

  const [initialOwner] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", initialOwner.address);

  if (!networks[hre.network.name]) {
    throw new Error(`Unsupported or missing network. Please specify a valid network (e.g., 'ethereum', 'sepolia', 'haqq', etc.)`);
  }

  const config = networks[hre.network.name];

  // Deploy ERC20MEME
  const meme = await ContractMEME.deploy();
  await meme.waitForDeployment();
  console.log(`ERC20MEME deployed to: ${await meme.getAddress()}`);

  const existingFactoryAddress = "0x08B298F85aF3D5e01e5bF700E23eE28e3690c29f";
  const instance = await ethers.getContractAt("MemeFactory", existingFactoryAddress);
  console.log(`Connected to existing MemeFactory at: ${instance.target}`);
  console.log(`Old Meme implementation at: ${await instance.implementation()}`);

  await instance.updateImplementation(await meme.getAddress());
  console.log(`New Meme implementation at: ${await instance.implementation()}`);

  try {
    await instance.updateTokensBatch(0, 10);
  } catch (e) {
    console.error("Batch update failed:", e);
  } 
  console.log(`Update complite`);
  
}

main().catch((error) => {
  console.error(error);
});
