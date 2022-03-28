![](https://pbs.twimg.com/profile_banners/1241234631707381760/1588727988/1500x500)

# Primitive Examples

[![License](https://img.shields.io/badge/License-GPLv3-green.svg)](https://www.gnu.org/licenses/gpl-3.0)

This repository contains examples showing how to interact with the Primitive Protocol's Automated Market Maker named "RMM-01".

These example contracts are written for educational purposes and were **NOT AUDITED**. Keep this in mind before using them in production.

Alternatively, you can use this repository as a base if you plan on building on top of the RMM protocol, as it contains all the necessary setup to run the whole protocol locally.

## Usage

Clone the repository on your computer:

```bash
git clone https://github.com/primitivefinance/rmm-examples.git
```

Then install the required dependencies:

```bash
# Using npm
npm install

# Using yarn
yarn
```

After that, you can try the other commands:

```bash
# Using npm and npx

# Compile the contracts
npm run compile

# Run a test
npx hardhat test ./path/to/the/test.ts

# Style the contracts using Prettier
npm run prettier


# Using yarn

# Compile the contracts
yarn compile

# Run a test
yarn hardhat test ./path/to/the/test.ts

# Style the contracts using Prettier
yarn prettier
```

## Example Contracts

### LiquidityManager

This simple example shows how a contract can manage liquidity pool tokens on the behalf of users, allowing them to allocate or remove into different pools.

The features of this example are quite basic:
- Users can allocate or remove liquidity into a pool of a predefined risky / stable pair
- Check the liquidity of each user currently managed by the contract

See the code [here](contracts/liquidityManager/liquidityManager.sol).

### LiquidityWrapper

The PrimitiveManager contract tokenizes liquidity pool tokens using the ERC1155 standard. This allows significant gas optimizations at a contract level, but adds a little bit of friction when it comes to integrating with other protocols, more used to deal with ERC20 tokens. Luckily, a straightforward solution to this problem is to use a "wrapper" contract.

The specifications of the `LiquidityWrapper` contract are extremely simple:
- A wrapper can only be associated with a unique PrimitiveManager token id
- Deposit (wrap) liquidity pool tokens (ERC1155) to receive wrapped tokens (ERC20)
- Withdraw (unwrap) wrapped liquidity pool tokens (ERC20) to get their unwrapped tokens back (ERC1155)

See the code [here](contracts/liquidityWrapper/LiquidityWrapper.sol).

### PrimitiveChef

Based on the [MasterChef](https://github.com/sushiswap/sushiswap/blob/canary/contracts/MasterChef.sol) created by SushiSwap, this contract is a reimplementation of the code with the support of ERC1155 tokens, the token standard used by the PrimitiveManager.

In a few words, the `PrimitiveChef` goals are to:
- Creation of staking pools dedicated to specific ERC1155 tokens
- Reward users depositing liquidity pool tokens in these staking pools

See the code [here](contracts/primitiveChef/PrimitiveChef.sol).

## Going Further

As mentioned above, if you plan on building on top of the Primitive RMM protocol, this repository can be used as a base for your work, as it already contains:
- A local context deploying a complete version of the protocol (PrimitiveFactory, PrimitiveEngine, PrimitiveManager and test ERC20 tokens)
- Custom Mocha hooks specific to the RMM protocol

Feel free to remove the examples or any files you don't want to keep to make yourself at home!
