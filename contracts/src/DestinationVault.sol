// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProgrammableTokenTransfers} from "./ProgrammableTokenTransfers.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@solmate/src/tokens/ERC4626.sol";

contract DestinationVault is ERC4626 {
    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset, _name, _symbol) {}

    // STATE VARIABLES
    address public sourceVault;

    function totalAssets() public view override returns (uint256) {
        uint256 _depositAssetBalance = asset.balanceOf(address(this));
        // TODO: ADD LOGIC FOR BALANCE OF PRODUCTIVE ASSET

        uint256 _totalAssets = _depositAssetBalance; // + _productiveAssetBalance;
        return _totalAssets;
    }

    function getExchangeRate() internal pure returns (uint256) {
        return 950000000000000000; // This represents 0.95 in fixed-point arithmetic with 18 decimal places

        // TODO: FINISH THIS LATER TO ACCESS AN ORACLE
    }
}
