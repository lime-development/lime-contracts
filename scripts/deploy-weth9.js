const { ethers } = require('hardhat')

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log('Deploying contracts with the account:', deployer.address)

  const WETH9 = await ethers.getContractFactory('WETH9')
  const weth = await WETH9.deploy()
  await weth.waitForDeployment()

  console.log('WETH deployed to:', await weth.getAddress())
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  }) 
