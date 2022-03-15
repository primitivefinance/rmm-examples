import { Wallet, Contract } from 'ethers';

export interface Contracts {
  primitiveFactory: Contract;
  primitiveEngine: Contract;
  primitiveManager: Contract;
  risky: Contract;
  stable: Contract;
  weth: Contract;
}

export interface Wallets {
  deployer: Wallet;
  alice: Wallet;
  bob: Wallet;
}

declare module 'mocha' {
  export interface Context {
    contracts: Contracts;
    wallets: Wallets;
  }
}
