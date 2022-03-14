import { ethers } from 'hardhat';

import PrimitiveFactoryArtifact from '@primitivefi/rmm-core/artifacts/contracts/PrimitiveFactory.sol/PrimitiveFactory.json';
import PrimitiveEngineArtifact from '@primitivefi/rmm-core/artifacts/contracts/PrimitiveEngine.sol/PrimitiveEngine.json';

import { computeEngineAddress } from './utils';

export async function fixture([deployer], provider) {
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

  return {
   primitiveFactory,
   primitiveEngine,
   risky,
   stable,
  };
}
