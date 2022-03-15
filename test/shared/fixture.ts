import { ethers } from 'hardhat';
import { utils, constants } from 'ethers';
import { parseWei } from 'web3-units';

import PrimitiveFactoryArtifact from '@primitivefi/rmm-core/artifacts/contracts/PrimitiveFactory.sol/PrimitiveFactory.json';
import PrimitiveEngineArtifact from '@primitivefi/rmm-core/artifacts/contracts/PrimitiveEngine.sol/PrimitiveEngine.json';
import PrimitiveManagerArtifact from '@primitivefi/rmm-manager/artifacts/contracts/PrimitiveManager.sol/PrimitiveManager.json';

import { computeEngineAddress } from './utils';
import { DEFAULT_CALIBRATION } from './config';

export async function fixture([deployer, alice], provider) {
  const PrimitiveFactory = await ethers.getContractFactory(
    PrimitiveFactoryArtifact.abi,
    PrimitiveFactoryArtifact.bytecode,
    deployer,
  );
  const primitiveFactory = await PrimitiveFactory.deploy();

  const TestERC20 = await ethers.getContractFactory('TestERC20', deployer);
  const risky = await TestERC20.deploy();
  const stable = await TestERC20.deploy();

  await primitiveFactory.deploy(risky, stable);

  const engineAddress = computeEngineAddress(
    primitiveFactory.address,
    risky.address,
    stable.address,
    PrimitiveEngineArtifact.bytecode,
  )

  const primitiveEngine = await ethers.getContractAt(PrimitiveEngineArtifact.abi, engineAddress, deployer);

  const Weth = await ethers.getContractFactory('WETH9', deployer);
  const weth = await Weth.deploy();

  const PrimitiveManager = await ethers.getContractFactory(
    PrimitiveManagerArtifact.abi,
    PrimitiveManagerArtifact.bytecode,
    deployer
  );

  const primitiveManager = await PrimitiveManager.deploy(
    primitiveFactory.address,
    weth.address,
    ethers.constants.AddressZero,
  );

  await risky.mint(deployer.address, parseWei('1000000').raw)
  await stable.mint(deployer.address, parseWei('1000000').raw)
  await risky.approve(primitiveManager.address, constants.MaxUint256)
  await stable.approve(primitiveManager.address, constants.MaxUint256)

  await primitiveManager.create(
    risky.address,
    stable.address,
    DEFAULT_CALIBRATION.strike.raw,
    DEFAULT_CALIBRATION.sigma.raw,
    DEFAULT_CALIBRATION.maturity.raw,
    DEFAULT_CALIBRATION.gamma.raw,
    parseWei(1).sub(parseWei(DEFAULT_CALIBRATION.delta)).raw,
    parseWei('1').raw,
  )

  return {
   primitiveFactory,
   primitiveEngine,
   primitiveManager,
   weth,
   risky,
   stable,
  };
}
