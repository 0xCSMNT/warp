// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProgrammableTokenTransfers} from "./ProgrammableTokenTransfers.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@solmate/src/tokens/ERC4626.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {LibFormatter} from "./utils/LibFormatter.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SourceVault is ERC4626, ProgrammableTokenTransfers {
    using FixedPointMathLib for uint256;
    using LibFormatter for uint256;
    using Math for uint256;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _router,
        address _link
    )
        ProgrammableTokenTransfers(_router, _link)
        ERC4626(_asset, _name, _symbol)
    {}

    // STATE VARIABLES
    address public destinationVault;
    bool public vaultLocked;
    uint256 public DestinationVaultBalance;

    // ERC4626 OVERRIDES
    function _deposit(uint _assets) public {
        require(!vaultLocked, "Vault is locked");
        require(_assets > 0, "Deposit must be greater than 0");
        deposit(_assets, msg.sender);
    }

    function _withdraw(uint _shares, address _receiver) public {
        require(!vaultLocked, "Vault is locked");
        require(_shares > 0, "No funds to withdraw");

        // Convert shares to the equivalent amount of assets
        uint256 assets = previewRedeem(_shares);

        // Withdraw the assets to the receiver's address
        withdraw(assets, _receiver, msg.sender);
    }




    
}