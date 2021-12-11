![](https://pbs.twimg.com/profile_banners/1241234631707381760/1588727988/1500x500)

# Primitive Examples

This repository contains examples showing how to interact with the Primitive Protocol's Automated Market Maker named "RMM-01".

These example contracts are written for educational purposes and were **NOT AUDITED**. Keep this in mind before using them in production.

## Contracts

### LiquidityWrapper

The PrimitiveManager tokenized liquidity pool tokens using the ERC1155 standard. This allows significant gas optimizations at a contract level, but adds a little bit of friction when it comes to integrating with other protocols. Luckily a straightforward solution to this problem is to use a "wrapper" contract.

The `LiquidityWrapper` contract wraps ERC1155 tokens from a specific PrimitiveManager pool and issues ERC20 tokens to the users.

See the [code here](contracts/liquidityWrapper/LiquidityWrapper.sol).
