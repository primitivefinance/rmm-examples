import { Contract, BigNumber } from 'ethers';
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

declare global {
  export namespace Chai {
    interface Assertion {
      revertWithCustomError(errorName: string, params?: any[]): AsyncAssertion
      updateMargin(
        manager: Contract,
        account: string,
        engine: string,
        delRisky: BigNumber,
        riskyIncrease: boolean,
        delStable: BigNumber,
        stableIncrease: boolean
      ): AsyncAssertion
      increaseMargin(
        manager: Contract,
        account: string,
        engine: string,
        delRisky: BigNumber,
        delStable: BigNumber
      ): AsyncAssertion
      decreaseMargin(
        manager: Contract,
        account: string,
        engine: string,
        delRisky: BigNumber,
        delStable: BigNumber
      ): AsyncAssertion
      increasePositionLiquidity(
        manager: Contract,
        account: string,
        poolId: string,
        liquidity: BigNumber
      ): AsyncAssertion
      decreasePositionLiquidity(
        manager: Contract,
        account: string,
        poolId: string,
        liquidity: BigNumber
      ): AsyncAssertion
    }
  }
}
