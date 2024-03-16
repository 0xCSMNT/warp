// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {SourceVault} from "../src/SourceVault.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract DeploySVToBaseSepolia is Script {
    // CONTRACTS
    SourceVault public sourceVault;

    // CONSTANTS
    address ROUTER = 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93;
    address LINK = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    uint64 ETH_SEPOLIA_CHAIN_ID = 16015286601757825753;
    uint64 ARB_SEPOLIA_CHAIN_ID = 3478487238524512106;

    function run() external {
        vm.startBroadcast();
        sourceVault = new SourceVault(
            ERC20(USDC),
            "SourceVault Base",
            "SVB",
            ROUTER,
            LINK
        );

        sourceVault.allowlistDestinationChain(ARB_SEPOLIA_CHAIN_ID, true);
        sourceVault.addDestinationChainId(ARB_SEPOLIA_CHAIN_ID);

        vm.stopBroadcast();
    }
}