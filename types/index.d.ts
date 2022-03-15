import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export interface Contracts {
  primitiveFactory: Contract;
  primitiveEngine: Contract;
  primitiveManager: Contract;
  weth: Contract;
  stable: Contract;
  risky: Contract;
}

export interface Wallets {
  deployer: SignerWithAddress;
  alice: SignerWithAddress;
  bob: SignerWithAddress;
}

declare module 'mocha' {
  export interface Context {
    contracts: Contracts;
    wallets: Wallets;
  }
}
