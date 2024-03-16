// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {SenderReceiver} from "../src/SenderReceiver.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract DeployContractsToArbSepolia is Script {
    ////////// CONTRACTS //////////
    SenderReceiver public senderReceiver;

    // CONSTANTS
    address ROUTER = 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8;
    address LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
    address USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    uint64 BASE_CHAIN_ID = 15971525489660198786;
    uint64 ARBITRUM_CHAIN_ID = 4949039107694359620;

    // Change this to the address of the SourceVault
    address SOURCE_VAULT = 0x00Dea5cd7D214ebf17197d38C1C986E441be0946; // WRONG ADDRESS!
    address DESTINATION_VAULT = 0x392B1E6905bb8449d26af701Cdea6Ff47bF6e5A8; // SOMMELIER

    function run() external {
        vm.startBroadcast();

        senderReceiver = new SenderReceiver(ROUTER, LINK);

        senderReceiver.allowlistSourceChain(BASE_CHAIN_ID, true);
        senderReceiver.allowlistSender(SOURCE_VAULT, true);
        senderReceiver.allowlistDestinationChain(ARBITRUM_CHAIN_ID, true);
        senderReceiver.addDestinationVault(address(DESTINATION_VAULT)); // SOMMELIER
        senderReceiver.addVaultToken(USDC);
        senderReceiver.updateVaultTokenDecimals(6);
        senderReceiver.addSourceChainId(BASE_CHAIN_ID);
        senderReceiver.addSourceVault(SOURCE_VAULT);

        vm.stopBroadcast();
    }
}
