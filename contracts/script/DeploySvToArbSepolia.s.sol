// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {SourceVault} from "../src/SourceVault.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract DeploySvToArb is Script {
    // CONSTANTS
    address ROUTER = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;
    address LINK = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
    address USDC = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
    uint64 ETH_SEPOLIA_CHAIN_ID = 16015286601757825753;

    // CONTRACTS
    SourceVault public sourceVault;

    function run() external {
        vm.startBroadcast();
        sourceVault = new SourceVault(
            ERC20(USDC),
            "SourceVault Base",
            "SVB",
            ROUTER,
            LINK
        );

        sourceVault.allowlistDestinationChain(ETH_SEPOLIA_CHAIN_ID, true);
        sourceVault.addDestinationChainId(ETH_SEPOLIA_CHAIN_ID);
        sourceVault.allowlistSourceChain(ETH_SEPOLIA_CHAIN_ID, true);
        sourceVault.allowlistSender(
            0x5Ea34d2aE385b25F18AC1401c10aFd20Ba32C0F7,
            true
        );
        sourceVault.addDestinationSenderReceiver(
            0x5Ea34d2aE385b25F18AC1401c10aFd20Ba32C0F7
        );
    }
}
