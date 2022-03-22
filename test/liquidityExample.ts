import hre from 'hardhat';
import { constants, Contract } from 'ethers';
import { parseWei } from 'web3-units';

import { runTest } from './shared/fixture'
import expect from './shared/expect';
import { DEFAULT_CALIBRATION } from './shared/config';

let liquidityExample: Contract;
let poolId: string;

runTest('LiquidityExample', function () {
  beforeEach(async function () {
    const LiquidityExample = await hre.ethers.getContractFactory('LiquidityExample');

    liquidityExample = await LiquidityExample.deploy(
      this.contracts.primitiveManager.address,
      this.contracts.risky.address,
      this.contracts.stable.address,
    );

    poolId = DEFAULT_CALIBRATION.poolId(this.contracts.primitiveEngine.address);
  });

  describe('success cases', function () {
    it('allocates risky and stable into a pool', async function () {
      await this.contracts.risky.approve(
        liquidityExample.address,
        constants.MaxUint256,
      );

      await this.contracts.stable.approve(
        liquidityExample.address,
        constants.MaxUint256,
      );

      const delLiquidity = parseWei(1).raw;
      const res = await this.contracts.primitiveEngine.reserves(poolId)
      const delRisky = delLiquidity.mul(res.reserveRisky).div(res.liquidity)
      const delStable = delLiquidity.mul(res.reserveStable).div(res.liquidity)

      await liquidityExample.allocate(
        poolId,
        delRisky,
        delStable,
        delLiquidity,
      );

      expect(
        await liquidityExample.liquidityOf(this.wallets.deployer.address)
      ).to.be.equal(delLiquidity);
    });
  })
});
