import hre from 'hardhat';
import { constants, Contract } from 'ethers';
import { parseWei } from 'web3-units';

import { runTest } from './shared/fixture'
import expect from './shared/expect';
import { DEFAULT_CALIBRATION } from './shared/config';

let liquidityExample: Contract;

runTest('LiquidityExample', function () {
  beforeEach(async function () {
    const LiquidityExample = await hre.ethers.getContractFactory('LiquidityExample');

    liquidityExample = await LiquidityExample.deploy(
      this.contracts.primitiveManager.address,
      this.contracts.risky.address,
      this.contracts.stable.address,
    );
  });

  describe('success cases', function () {
    it('allocates risky and stable into a pool', async function () {
      /*
      await this.contracts.risky.approve(
        liquidityExample.address,
        constants.MaxUint256,
      );

      await this.contracts.stable.approve(
        liquidityExample.address,
        constants.MaxUint256,
      );
*/
      /*
      await liquidityExample.allocate(
        DEFAULT_CALIBRATION.poolId,
        parseWei(100).raw,
        parseWei(100).raw,
        0,
      );
      */
    });
  })
});
