// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {SenderReceiver} from "../src/SenderReceiver.sol";
import {DestinationVault} from "../src/DestinationVault.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract DeployContractsToArbSepolia is Script {
    ////////// CONTRACTS //////////
    SenderReceiver public senderReceiver;
    DestinationVault public destinationVault;

    // CONSTANTS
    address ROUTER = 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93;
    address LINK = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    uint64 ARB_SEPOLIA_CHAIN_ID = 3478487238524512106;

    // Change this to the address of the SourceVault
    //address SOURCE_VAULT = 0x32482F92244Cc5Abac40313EA8D327Dd49B23C1a; // WRONG ADDRESS!

    function run() external {
        vm.startBroadcast();
        destinationVault = new DestinationVault(
            ERC20(USDC),
            "DestinationVault",
            "DV"
        );
        senderReceiver = new SenderReceiver(ROUTER, LINK);

        senderReceiver.allowlistSourceChain(ARB_SEPOLIA_CHAIN_ID, true);
        // senderReceiver.allowlistSender(SOURCE_VAULT, true);
        senderReceiver.allowlistDestinationChain(ARB_SEPOLIA_CHAIN_ID, true);
        senderReceiver.addDestinationVault(address(destinationVault)); // SOMMELIER
        senderReceiver.addVaultToken(USDC);
        senderReceiver.updateVaultTokenDecimals(6);
        senderReceiver.addSourceChainId(ARB_SEPOLIA_CHAIN_ID);
        // senderReceiver.addSourceVault(SOURCE_VAULT);

        vm.stopBroadcast();
    }
}
