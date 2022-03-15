import {
  utils,
  BigNumberish,
} from 'ethers'

const { keccak256, solidityPack } = utils

/**
 * Computes deterministic poolIds from hashing engine address and calibration parameters.
 *
 * @param engine Address of Engine contract.
 * @param strike Strike price in wei, with decimal places equal to the Engine's `stable` token decimals.
 * @param sigma  Implied volatility in basis points.
 * @param maturity Timestamp of expiration in seconds, matching the format of `block.timestamp`.
 * @param gamma  Equal to 10_000 - fee, in basis points. Used to apply fee on swaps.
 *
 * @returns Keccak256 hash of a solidity packed array of engine address and calibration struct.
 *
 * @beta
 */
export function computePoolId(engine: string, strike: BigNumberish, sigma: BigNumberish, maturity: BigNumberish, gamma: BigNumberish): string {
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
