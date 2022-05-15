import {
  utils,
  BigNumber,
} from 'ethers'

const { keccak256, solidityPack } = utils

export function computePoolId(
  engine: string,
  maturity: string | number,
  sigma: string | BigNumber,
  strike: string | BigNumber,
  gamma: string | BigNumber
): string {
  return keccak256(
    solidityPack(['address', 'uint128', 'uint32', 'uint32', 'uint32'], [engine, strike, sigma, maturity, gamma])
  )
}

/**
 * Statically computes an Engine address.
 *
 * @remarks
 * Verify `bytecode` is up-to-date.
 *
 * @param factory Deployer of the Engine contract.
 * @param risky Risky token address.
 * @param stable Stable token address.
 * @param bytecode Bytecode of the PrimitiveEngine.sol smart contract.
 *
 * @returns engine address.
 *
 * @beta
 */
export function computeEngineAddress(factory: string, risky: string, stable: string, bytecode: string): string {
  const salt = utils.solidityKeccak256(
    ['bytes'],
    [utils.defaultAbiCoder.encode(['address', 'address'], [risky, stable])]
  )
  return utils.getCreate2Address(factory, salt, utils.keccak256(bytecode))
}
