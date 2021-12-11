![](https://pbs.twimg.com/profile_banners/1241234631707381760/1588727988/1500x500)

# Primitive Examples

This repository contains examples showing how to interact with the Primitive Protocol's Automated Market Maker named "RMM-01".

These example contracts are written for educational purposes and were **NOT AUDITED**. Keep this in mind before using them in production.

## Contracts

### LiquidityWrapper

The PrimitiveManager tokenized liquidity pool tokens using the ERC1155 standard. This allows significant gas optimizations at a contract level, but adds a little bit of friction when it comes to integrating with other protocols, more used to deal with ERC20 tokens. Luckily a straightforward solution to this problem is to use a "wrapper" contract.

The specifications of the `LiquidityWrapper` contract are extremely simple:
- A wrapper can only be associated with a unique PrimitiveManager pool
- It allows users to deposit (wrap) liquidity pool tokens (ERC1155) to receive wrapped tokens (ERC20)
- It allows users to withdraw (unwrap) wrapped liquidity pool tokens (ERC20) to get their unwrapped tokens back (ERC1155)

See the [code here](contracts/liquidityWrapper/LiquidityWrapper.sol).
