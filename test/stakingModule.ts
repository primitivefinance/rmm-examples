import hre, { waffle } from 'hardhat';

import expect from './shared/expect';

let alice, bob;
let stakingModule;
let rewardToken;
let stakingToken;

export async function mineBlocks(amount: number): Promise<void> {
  for (let i = 0; i < amount; ++i) {
    await waffle.provider.send('evm_mine', []);
  }
}

describe('StakingModule', () => {
  beforeEach(async () => {
    [alice, bob] = hre.waffle.provider.getWallets();

    const RewardToken = await hre.ethers.getContractFactory('TestERC20');
    rewardToken = await RewardToken.deploy();

    const StakingToken = await hre.ethers.getContractFactory('TestERC1155Permit');
    stakingToken = await StakingToken.deploy();
    await stakingToken.mint(alice.address, 0, 10);

    const StakingModule = await hre.ethers.getContractFactory('StakingModule');
    stakingModule = await StakingModule.deploy(rewardToken.address);
    await stakingModule.create(0, stakingToken.address, 100);
  });

  describe('success cases', () => {
    beforeEach(async () => {
      await stakingToken.setApprovalForAll(stakingModule.address, true);
      await stakingToken.connect(bob).setApprovalForAll(stakingModule.address, true);
    });

    it('deposits into a pool', async () => {
      await stakingModule.deposit(0, 10);
      const user = await stakingModule.users(alice.address, 0);
      expect(user.balance).to.be.equal(10);
    });

    it('deposits and checks the pending reward', async () => {
      await stakingModule.deposit(0, 10);
      await mineBlocks(2);
      const pending = await stakingModule.pending(alice.address, 0);
      expect(pending).to.be.equal(200);
    });

    it('deposits', async () => {
      await stakingToken.mint(bob.address, 0, 10);

      await stakingModule.deposit(0, 10);
      await stakingModule.connect(bob).deposit(0, 10);

      {
        const pendingOfAlice = await stakingModule.pending(alice.address, 0);
        expect(pendingOfAlice).to.be.equal(100);

        const pendingOfBob = await stakingModule.pending(bob.address, 0);
        expect(pendingOfBob).to.be.equal(0);
      }

      await mineBlocks(2);

      {
        const pendingOfAlice = await stakingModule.pending(alice.address, 0);
        expect(pendingOfAlice).to.be.equal(200);

        const pendingOfBob = await stakingModule.pending(bob.address, 0);
        expect(pendingOfBob).to.be.equal(100);
      }
    });
  });
});
