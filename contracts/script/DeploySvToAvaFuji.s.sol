// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {SourceVault} from "../src/SourceVault.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract DeploySvToBase is Script {
    // CONSTANTS
    address ROUTER = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address LINK = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address USDC = 0x5425890298aed601595a70AB815c96711a31Bc65;
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
        
    }
}