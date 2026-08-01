# Liquidity App — Uniswap V2 (Foundry)

A Solidity smart contract that lets a user swap USDT for DAI and add/remove liquidity to a Uniswap V2 pool in a single transaction, built and tested with Foundry against a live Arbitrum mainnet fork.

Part of my Solidity smart contract security portfolio, focused on writing production-style DeFi integrations while applying secure coding patterns.

## What it does

- **`addLiquidity`**: takes USDT from the user, swaps half of it for DAI through the Uniswap V2 Router, and deposits both tokens into the USDT/DAI pool — so the user only needs to hold one token to become a liquidity provider.
- **`removeLiquidity`**: burns the user's LP tokens through the Router and returns the underlying USDT and DAI.
- **`swapTokens`**: a standalone exact-input swap wrapper around `Router.swapExactTokensForTokens`.

## Security patterns applied

- **Checks-Effects-Interactions (CEI)**: state changes and token transfers are ordered to minimize reentrancy surface before external calls.
- **`SafeERC20`**: all transfers use `safeTransferFrom`/`safeTransfer` instead of raw ERC20 calls, so tokens that return `false` on failure (instead of reverting) can't silently pass.
- **Pull-then-approve pattern for LP tokens**: `removeLiquidity` explicitly pulls the caller's LP tokens into the contract before approving the Router — since `addLiquidity` mints LP tokens directly to the user (not to the contract), this step is required and is easy to miss.
- **Slippage protection**: every swap/liquidity call exposes `amountOutMin` / `amountAMin` / `amountBMin` parameters, respecting the "never accept less than you're willing to receive" invariant.
- **Deadline protection**: every external call takes a `deadline` to prevent stale transactions from being executed after being front-run or delayed.

## Architecture: Router vs Factory

- **Router (`V2Router02`)**: handles every operation that moves funds — swaps, adding liquidity, removing liquidity.
- **Factory**: read-only lookups. Used once, in `removeLiquidity`, to resolve the LP token's address via `getPair(tokenA, tokenB)` — since that address is never returned to the caller during `addLiquidity`.

## Tech stack

- Solidity 0.8.24
- Foundry (Forge + fork testing)
- OpenZeppelin Contracts v5.x (`IERC20`, `SafeERC20`)
- Uniswap V2 (Router02, Factory) on Arbitrum One

## Testing

Tests run against a live Arbitrum mainnet fork using Foundry's `--fork-url`, impersonating a real wallet with USDT balance via `vm.startPrank`.

```shell
forge test --fork-url https://arb1.arbitrum.io/rpc -vvv
```

Covers:
- Correct deployment and constructor wiring.
- Token swap execution with balance assertions.
- Adding liquidity and receiving LP tokens.
- Removing liquidity and recovering the underlying tokens.

## Project structure

```
src/
  SwapApp.sol              # main contract
  interfaces/
    IV2Router02.sol        # Uniswap V2 Router interface
    IFactory.sol           # Uniswap V2 Factory interface
test/
  SwapApp.t.sol             # Foundry fork tests
```

## Disclaimer

Built for educational and portfolio purposes as part of a blockchain security accelerator. Not audited — do not use in production without a professional security review.