const { ethers } = require('hardhat')

async function main() {
  // Get contract name from environment variable
  const contractName = process.env.CONTRACT_NAME
  
  if (!contractName) {
    console.error('Error: Contract name must be specified')
    console.log('Usage: CONTRACT_NAME=<contract_name> npx hardhat run scripts/deploy-weth9.js --network <network>')
    console.log('Example: CONTRACT_NAME=WETH9 npx hardhat run scripts/deploy-weth9.js --network sepolia')
    process.exit(1)
  }

  const [deployer] = await ethers.getSigners()
  console.log('Deploying contracts with account:', deployer.address)
  console.log('Deploying contract:', contractName)

  try {
    const ContractFactory = await ethers.getContractFactory(contractName)
    const contract = await ContractFactory.deploy()
    await contract.waitForDeployment()

    console.log(`${contractName} deployed to:`, await contract.getAddress())
  } catch (error) {
    console.error(`Error deploying contract ${contractName}:`, error.message)
    process.exit(1)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  }) 
