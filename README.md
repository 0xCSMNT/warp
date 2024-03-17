# warp

ETHGlobal London Hackathon Project

## Screenshot

<img width="1512" alt="02" src="https://github.com/0xCSMNT/warp/assets/2104965/8d7cfbc7-2191-4477-9852-ec7c772a0652">
<img width="1512" alt="03" src="https://github.com/0xCSMNT/warp/assets/2104965/24e51878-36f4-4b53-921b-544f7a88ac0e">

## Deployed Contracts

### Source Vault
Deployed to [Base Sepolia](https://sepolia.basescan.org/address/0x6fd4f4e2bd64168254f3c719b28b88d5d0246d40#code). This is the user facing ERC4626 contract that handles deposits and initiates cross chain transactions to deposit and withdraw from the destination vault.

### SenderReceiver
Deployed to [Arbitrum Sepolia](https://sepolia.arbiscan.io/address/0x59d4f2d53612e944c583c838358f4310c5136799#code). This is contract on the destination chain that receives CCIP messages, interacts with the destination ERC4626, and handles all of the accounting for user deposits.

### Example Transactions
[execute()](https://ccip.chain.link/msg/0x78f0808e4260a101b4443e9944f30747b0e53e3ef06e90f459edfebe0e791946) - sends the token and data from the SourceVault to the SenderReceiver on destination chain via CCIP.

[quit() requested](https://ccip.chain.link/msg/0x7470ca05a7e34ff1c66ad7033673f1a97fbbeb73802e0898e9e747489959f4c8) - sends a request from SourceVault to SenderReceiver to request withdrawal from the destination vault.

[quit() executed](https://ccip.chain.link/msg/0x6b432a15e447ea6a44dbff014c72bc6b6b78d0283c09054f241bf62caad9df9f) - Sender Receiver withdraws from the destination vault and send the tokens back to SourceVault for customer withdrawal.

### Terms and Contract Names:
**Source Chain:** This is the chain where the user facing contracts are deployed. 

**Destination Chain:** This is the chain where funds will be bridged

**SourceVault:** This is the main user facing smart contract. Exposes an ERC4626 interface. Stores the accounting for the vault users. 
Lives on Source Chain

**DestinationVault:** This is the actual live vault we are connecting too. It can be any ERC4626-compliant smart contract. In the project, a mock contract with the same name is used for testing purposes.
Lives on Destination Chain

**SenderReceiver:** This “middle-man” contract that receives CCIP messages and transfers on the Destination Chain. It deposits to the DestinationVault and receives shares to represent the aggregate position of all SourceVault shareholders.


## Deposit / Withdrawal Flow

![Sequence Diagram](./contracts/diagram/sequence_diagram/sequence_diagram.png)

## Caveat

1. If a user deposit a huge N amount and we haven’t bridge to destination chain, this user can initialSlowWithdraw to try to move N amount back to source chain. This might be an minor attack way if someone wants to waste the gas fee of our vaults. This can also make our destination chain’s contract withdraw more than we deposited.
2. There will be an accounting issue when `quit` and `execute` are sending at the same time. Because `cacheAssetFromDst` gets overridden, but that data is not up to date. This can be solved by introducing lock mechanism (lock the deposit / withdrawal while doing `quit` and `execute`).
3. There’s an potential arbitrage opportunity. It depends on the synchronous frequency of source and destination vault. Users can deposit and withdraw the fund before and after the quit. This can be solved by introducing lock mechanism (at least to deposit for several blocks).
