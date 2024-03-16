// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ProgrammableTokenTransfers} from "./ProgrammableTokenTransfers.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {console2} from "forge-std/Test.sol";

contract SenderReceiver is ProgrammableTokenTransfers {
    constructor(
        address _router,
        address _link
    ) ProgrammableTokenTransfers(_router, _link) {}

    // STATE VARIABLES
    address public destinationVault;
    address public vaultToken;
    uint8 public vaultTokenDecimals;

    // FUNCTIONS

    // Add destination Vault
    function addDestinationVault(address _destinationVault) public onlyOwner {
        destinationVault = _destinationVault;
    }

    function addVaultToken(address _token) public onlyOwner {
        vaultToken = _token;
    }

    function updateVaultTokenDeciamls(uint8 _decimals) public onlyOwner {
        vaultTokenDecimals = _decimals;
    }

    function DepositToDestinationVault(uint256 _amount) public {
        ERC20(vaultToken).approve(destinationVault, _amount);
        IERC4626(destinationVault).deposit(_amount, address(this));
        console2.log("msg.sender in deposit function:", msg.sender);
    }

    function withdraw(uint256 amount) public {
        // TODO:
        // withdraw assets from the the destination vault
        // this needs to be called by ccip router
        // this function will also call transferTokenWithData to interact with the ccip router
    }
}
