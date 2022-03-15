import hre, { ethers } from 'hardhat';
import { constants, Wallet, } from 'ethers';
import { parseWei } from 'web3-units';
import { createFixtureLoader, MockProvider } from 'ethereum-waffle';

import PrimitiveFactoryArtifact from '@primitivefi/rmm-core/artifacts/contracts/PrimitiveFactory.sol/PrimitiveFactory.json';
import PrimitiveEngineArtifact from '@primitivefi/rmm-core/artifacts/contracts/PrimitiveEngine.sol/PrimitiveEngine.json';
import PrimitiveManagerArtifact from '@primitivefi/rmm-manager/artifacts/contracts/PrimitiveManager.sol/PrimitiveManager.json';

import { computeEngineAddress } from './utils';
import { DEFAULT_CALIBRATION } from './config';

export function runTest(description: string, runTests: Function): void {
  const loadFixture = createFixtureLoader();

  describe(description, function () {
    beforeEach(async function () {
      const wallets = await hre.ethers.getSigners();

      const [deployer, alice, bob] = wallets;
      const loadedFixture = await loadFixture(fixture);

      this.contracts = {
        primitiveFactory: loadedFixture.primitiveFactory,
        primitiveEngine: loadedFixture.primitiveEngine,
        primitiveManager: loadedFixture.primitiveManager,
        weth: loadedFixture.weth,
        risky: loadedFixture.risky,
        stable: loadedFixture.stable,
      };

      this.wallets = {
        deployer,
        alice,
        bob,
      };
    });

    runTests();
  })
}

export async function fixture([deployer]: Wallet[], provider: MockProvider) {
  const PrimitiveFactory = await ethers.getContractFactory(
    PrimitiveFactoryArtifact.abi,
    PrimitiveFactoryArtifact.bytecode,
    deployer,
  );
  const primitiveFactory = await PrimitiveFactory.deploy();

  const TestERC20 = await ethers.getContractFactory('TestERC20', deployer);
  const risky = await TestERC20.deploy();
  const stable = await TestERC20.deploy();

  await primitiveFactory.deploy(risky.address, stable.address);

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
    weth.address,
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
    parseWei(1).raw,
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
