import hre, { ethers } from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import expect from './utils/expect';
import { TestERC1155Permit, LiquidityWrapper } from '../typechain';
import { getERC1155PermitSignature } from './utils/permit';

let lpToken: TestERC1155Permit;
let wrappedLpToken: LiquidityWrapper;
let signers: SignerWithAddress[];
let deployer: SignerWithAddress;

let poolId = 0;

async function deploy(contractName: string, deployer: SignerWithAddress, args: any[] = []): Promise<Contract> {
  const artifact = await hre.artifacts.readArtifact(contractName)
  const contract = await hre.waffle.deployContract(deployer, artifact, args, { gasLimit: 9500000 })
  return contract
}

describe('LiquidityWrapper', () => {
  beforeEach(async () => {
    signers = await ethers.getSigners();
    [deployer] = signers;

    lpToken = await deploy('TestERC1155Permit', deployer) as TestERC1155Permit;

    wrappedLpToken = await deploy('LiquidityWrapper', deployer, [
      'NAME',
      'SYMBOL',
      lpToken.address,
      poolId,
    ]) as LiquidityWrapper;

    await lpToken.mint(deployer.address, poolId, 100);
  });

  describe('success cases', () => {
    it('wraps liquidity pool tokens', async () => {
      await lpToken.setApprovalForAll(wrappedLpToken.address, true);
      await wrappedLpToken.wrap(deployer.address, 100);

      expect(
        await wrappedLpToken.balanceOf(deployer.address),
      ).to.be.equal(100);
    });

    it('wraps liquidity pool tokens (using the Multicall)', async () => {
      const sig = await getERC1155PermitSignature(
        deployer,
        lpToken.address,
        wrappedLpToken.address,
        true,
        999999999999999, {
          nonce: 0,
          name: 'PrimitiveManager',
          chainId: await deployer.getChainId(),
          version: '1',
        },
      );

      const selfPermitData = wrappedLpToken.interface.encodeFunctionData(
        'selfPermit', [
          deployer.address,
          true,
          999999999999999,
          sig.v,
          sig.r,
          sig.s
        ],
      );

      const wrapData = wrappedLpToken.interface.encodeFunctionData(
        'wrap', [
          deployer.address,
          100,
        ],
      );

      await wrappedLpToken.multicall([selfPermitData, wrapData]);

      expect(
        await wrappedLpToken.balanceOf(deployer.address),
      ).to.be.equal(100);
    });
  });
});
