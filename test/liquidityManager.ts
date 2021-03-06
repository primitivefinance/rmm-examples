import hre from 'hardhat';
import { constants, Contract } from 'ethers';
import { parseWei } from 'web3-units';

import { runTest } from './shared/fixture'
import expect from './shared/expect';
import { DEFAULT_CALIBRATION } from './shared/config';

let liquidityManager: Contract;
let poolId: string;

runTest('LiquidityManager', function () {
  beforeEach(async function () {
    const LiquidityManager = await hre.ethers.getContractFactory('LiquidityManager');

    liquidityManager = await LiquidityManager.deploy(
      this.contracts.primitiveManager.address,
      this.contracts.risky.address,
      this.contracts.stable.address,
    );

    poolId = DEFAULT_CALIBRATION.poolId(this.contracts.primitiveEngine.address);
  });

  describe('success cases', function () {
    it('allocates risky and stable into a pool', async function () {
      await this.contracts.risky.approve(
        liquidityManager.address,
        constants.MaxUint256,
      );

      await this.contracts.stable.approve(
        liquidityManager.address,
        constants.MaxUint256,
      );

      const delLiquidity = parseWei(1).raw;
      const res = await this.contracts.primitiveEngine.reserves(poolId)
      const delRisky = delLiquidity.mul(res.reserveRisky).div(res.liquidity)
      const delStable = delLiquidity.mul(res.reserveStable).div(res.liquidity)

      await liquidityManager.allocate(
        poolId,
        delRisky,
        delStable,
        delLiquidity,
      );

      expect(
        await liquidityManager.liquidityOf(this.wallets.deployer.address)
      ).to.be.equal(delLiquidity);
    });

    it('allocates and removes', async function () {
      await this.contracts.risky.approve(
        liquidityManager.address,
        constants.MaxUint256,
      );

      await this.contracts.stable.approve(
        liquidityManager.address,
        constants.MaxUint256,
      );

      const delLiquidity = parseWei(1).raw;
      const res = await this.contracts.primitiveEngine.reserves(poolId)
      const delRisky = delLiquidity.mul(res.reserveRisky).div(res.liquidity)
      const delStable = delLiquidity.mul(res.reserveStable).div(res.liquidity)

      await liquidityManager.allocate(
        poolId,
        delRisky,
        delStable,
        delLiquidity,
      );

      expect(
        await liquidityManager.liquidityOf(this.wallets.deployer.address)
      ).to.be.equal(delLiquidity);
    });
  })
});
