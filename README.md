# warp

ETHGlobal London Hackathon Project

## Screenshot

![screenshot](./images/screenshot.png)

## Deposit / Withdrawal Flow

![Sequence Diagram](./contracts/diagram/sequence_diagram/sequence_diagram.png)

## Caveat

1. If a user deposit a huge N amount and we haven’t bridge to destination chain, this user can initialSlowWithdraw to try to move N amount back to source chain. This might be an minor attack way if someone wants to waste the gas fee of our vaults. This can also make our destination chain’s contract withdraw more than we deposited.
2. There will be an accounting issue when `quit` and `execute` are sending at the same time. Because `cacheAssetFromDst` gets overridden, but that data is not up to date. This can be solved by introducing lock mechanism (lock the deposit / withdrawal while doing `quit` and `execute`).
3. There’s an potential arbitrage opportunity. It depends on the synchronous frequency of source and destination vault. Users can deposit and withdraw the fund before and after the quit. This can be solved by introducing lock mechanism (at least to deposit for several blocks).
