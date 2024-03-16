// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {SourceVault} from "../src/SourceVault.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract DeploySvToBase is Script {
    // CONSTANTS
    address ROUTER = 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD;
    address LINK = 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196;
    address USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    uint64 ARBITRUM_CHAIN_ID = 4949039107694359620;

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

        sourceVault.allowlistDestinationChain(ARBITRUM_CHAIN_ID, true);
        sourceVault.addDestinationChainId(ARBITRUM_CHAIN_ID);
        sourceVault.allowlistSourceChain(ARBITRUM_CHAIN_ID, true);
        
    }
}