// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ProgrammableTokenTransfers} from "./ProgrammableTokenTransfers.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {LibFormatter} from "./utils/LibFormatter.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import "forge-std/console.sol";
contract SenderReceiver is ProgrammableTokenTransfers {
    using FixedPointMathLib for uint256;
    using LibFormatter for uint256;

    constructor(
        address _router,
        address _link
    ) ProgrammableTokenTransfers(_router, _link) {}

    // STATE VARIABLES
    uint64 public sourceChainId;
    address public sourceVault;
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

    function updateVaultTokenDecimals(uint8 _decimals) public onlyOwner {
        vaultTokenDecimals = _decimals;
    }

    function addSourceChainId(uint64 _id) public onlyOwner {
        sourceChainId = _id;
    }

    function addSourceVault(address _sourceVault) public onlyOwner {
        sourceVault = _sourceVault;
    }

    function deposit(
        uint256 _amount
    ) public onlyAllowlisted(sourceChainId, sourceVault) {
        ERC20(vaultToken).approve(destinationVault, _amount);
        IERC4626(destinationVault).deposit(_amount, address(this));
    }

    function redeem(
        uint256 shareRatio,
        uint256 assetsFromSrc
    ) public onlyAllowlisted(sourceChainId, sourceVault) {
        uint256 totalAssets = assetsFromSrc +
            IERC4626(destinationVault).balanceOf(address(this));
        uint256 assets = _convertToAssets(shareRatio, totalAssets)
            .formatDecimals(18, vaultTokenDecimals);

        IERC4626(destinationVault).withdraw(
            assets,
            address(this),
            address(this)
        );
        // call router
        _sendDataAndToken(
            sourceChainId,
            sourceVault,
            abi.encodeWithSignature(
                "receiveQuitSignal(uint256)",
                IERC4626(destinationVault).balanceOf(address(this))
            ),
            vaultToken,
            assets
        );
    }

    function _convertToAssets(
        uint256 shareRatio,
        uint256 totalAssets
    ) internal pure returns (uint256) {
        return shareRatio.mulWadDown(totalAssets);
    }
}
