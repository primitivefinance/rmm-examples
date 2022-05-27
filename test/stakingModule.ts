import hre, { waffle } from 'hardhat';

import expect from './shared/expect';

let alice, bob;
let stakingModule;

export async function mineBlocks(amount: number): Promise<void> {
  for (let i = 0; i < amount; ++i) {
    await waffle.provider.send('evm_mine', []);
  }
}


describe('StakingModule', () => {
  beforeEach(async () => {
    [alice, bob] = hre.waffle.provider.getWallets();

    const StakingModule = await hre.ethers.getContractFactory('StakingModule');
    stakingModule = await StakingModule.deploy();
    await stakingModule.create(0, stakingModule.address, 100);
  });

  it('deposits into a pool', async () => {
    await stakingModule.deposit(0, 100);
    const user = await stakingModule.users(alice.address, 0);
    expect(user.balance).to.be.equal(100);
  });

  it('deposits', async () => {
    await stakingModule.deposit(0, 100);
    await mineBlocks(2);
    const pending = await stakingModule.pending(alice.address, 0);
    expect(pending).to.be.equal(200);
  });

  it('deposits', async () => {
    await stakingModule.deposit(0, 100);
    await stakingModule.connect(bob).deposit(0, 100);

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
