async function main() {
  const ContractMEME = await ethers.getContractFactory("ERC20Meme");
  const ContractFactory = await ethers.getContractFactory("MemeFactory");
      
  const [initialOwner] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", initialOwner.address);
  const meme  = await ContractMEME.deploy();
  await meme.waitForDeployment();

  const instance = await ContractFactory.deploy(meme.getAddress());
  await instance.waitForDeployment();
      
  console.log(`Contract memeFactory deployed to ${await instance.getAddress()}, implementation is ${await meme.getAddress()}`);
}
      
main().catch((error) => {
  console.error(error);
});