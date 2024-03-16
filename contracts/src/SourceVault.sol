// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProgrammableTokenTransfers} from "./ProgrammableTokenTransfers.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@solmate/src/tokens/ERC4626.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {LibFormatter} from "./utils/LibFormatter.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

struct Log {
    uint256 index; // Index of the log in the block
    uint256 timestamp; // Timestamp of the block containing the log
    bytes32 txHash; // Hash of the transaction containing the log
    uint256 blockNumber; // Number of the block containing the log
    bytes32 blockHash; // Hash of the block containing the log
    address source; // Address of the contract that emitted the log
    bytes32[] topics; // Indexed topics of the log
    bytes data; // Data of the log
}

interface ILogAutomation {
    function checkLog(
        Log calldata log,
        bytes memory checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

contract SourceVault is
    ProgrammableTokenTransfers,
    ERC4626 // Make this "is ILogAutomation"
{
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

    // STATE VARIABLES FOR CCIP MESSAGES
    uint64 public DestinationChainId;
    address public DestinationSenderReceiver;

    address public destinationVault;
    bool public vaultLocked;
    uint256 public cacheAssetFromDst;
    uint256 public depositThreshold = 1e18; // keeper bot only gets triggered when depositableAsset >= depositThreshold
    uint256 public redeemThreshold = 1e18; // keeper bot only gets triggered when penddingWithdrawal >= withdrawThreshold
    uint256 public totalPendingToRedeem; // total pending withdrawal from isPendingToWithdraw
    uint256 public pendingToRedeemFromDst; // pedning to request withdrawal from destination vault in the next batch
    uint256 public lastRedeemFromDst; // last time the source vault requested withdrawal from destination vault
    mapping(address => uint256) public lastRequestToRedeemFromDst;
    mapping(address => uint256) public isPendingToRedeem;
    uint256 public redeemExtraRatio; // 5% = 5e6

    //
    // ERROR
    //
    error VaultLocked();
    error SufficientAssets();
    error InsufficientAllowance();
    error ExceedMaxRedeemableShares();
    error ExistingPendingSharesToBeRedeemedFirst();
    error InsufficientQuitingAmount();
    error InsufficientAssetsToBeDeposited();

    // EVENTS
    event TimeToExecute(uint256 pendingToDeposit, uint256 depositThreshold);
    event TimeToQuit(uint256 pendingToRedeem, uint256 redeemThreshold);

    //
    // MODIFIER
    //

    modifier whenNotLock() {
        if (vaultLocked) {
            revert VaultLocked();
        }
        _;
    }

    //
    // DEPOSIT/WITHDRAWAL LOGIC
    // ERC4626 OVERRIDES
    //
    function deposit(
        uint256 assets,
        address receiver
    ) public override whenNotLock returns (uint256 shares) {
        shares = super.deposit(assets, receiver);
        _checkDepositThreshold();
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override whenNotLock returns (uint256 assets) {
        assets = super.mint(shares, receiver);
        _checkDepositThreshold();
    }

    function _withdraw(uint _shares, address _receiver) public {
        // TODO: two scenarios
        // 1. directly withdraw if the asset is enough
        // 2. add address to the withdrawQueue if not enough
        require(!vaultLocked, "Vault is locked");
        require(_shares > 0, "No funds to withdraw");

        // Convert shares to the equivalent amount of assets
        uint256 assets = previewRedeem(_shares);

        // Withdraw the assets to the receiver's address
        withdraw(assets, _receiver, msg.sender);
    }

    function execute() public {
        // TODO: Add logic to proceed the vault's strategy (cross chain yield farming)
        // this function will call transferTokenWithData to interact with the ccip router
    }

    function quit() public {
        // TODO: Add logic to quit the vault's strategy (cross chain yield farming)
        // withdraw amount = penddingWithdrawal * (1 + withdrawalExtraRatio)
    }

    function depositableAssetToDestination() public view returns (uint256) {
        uint256 _depositAssetBalance = asset
            .balanceOf(address(this))
            .formatDecimals(asset.decimals(), 18);

        uint256 totalPendingWithdrawal = previewRedeem(totalPendingToRedeem);

        if (totalPendingWithdrawal >= _depositAssetBalance) {
            return 0;
        }

        return _depositAssetBalance - totalPendingWithdrawal;
    }

    function totalAssets() public view override returns (uint256) {
        uint256 _depositAssetBalance = _currentAsset();
        uint256 _totalAssets = _depositAssetBalance + cacheAssetFromDst;
        return _totalAssets.formatDecimals(18, asset.decimals());
    }

    function addDestinationVault(address _destinationVault) public onlyOwner {
        destinationVault = _destinationVault;
    }

    function addDestinationChainId(
        uint64 _destinationChainId
    ) public onlyOwner {
        DestinationChainId = _destinationChainId;
    }

    function addDestinationSenderReceiver(
        address _destinationSenderReceiver
    ) public onlyOwner {
        DestinationSenderReceiver = _destinationSenderReceiver;
    }

    function setDepositThreshold(uint256 _threshold) public onlyOwner {
        depositThreshold = _threshold;
    }

    // Owner can pause the vault for safety
    function lockVault() external onlyOwner {
        vaultLocked = true;
    }

    function unlockVault() external onlyOwner {
        vaultLocked = false;
    }

    function _checkRedeemThreshold() internal {
        if (pendingToRedeemFromDst >= redeemThreshold) {
            emit TimeToQuit(pendingToRedeemFromDst, redeemThreshold);
        }
    }

    function _checkDepositThreshold() internal {
        uint256 _depositableAssetToDestination = depositableAssetToDestination();
        if (_depositableAssetToDestination >= depositThreshold) {
            emit TimeToExecute(
                _depositableAssetToDestination,
                depositThreshold
            );
        }
    }

    function _currentAsset() internal view returns (uint256) {
        return
            asset.balanceOf(address(this)).formatDecimals(asset.decimals(), 18);
    }

    // AUTOMATION FUNCTIONS
}
