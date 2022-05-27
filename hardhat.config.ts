import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'
import { HardhatUserConfig } from 'hardhat/config'

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      blockGasLimit: 18e6,
      gas: 12e6,
    },
  },
  solidity: {
    compilers: [
      { version: '0.8.6' },
      { version: '0.8.9' },
      { version: '0.8.13' },
    ],
  },
}

export default config
