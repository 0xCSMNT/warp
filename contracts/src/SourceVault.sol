// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProgrammableTokenTransfers} from "./ProgrammableTokenTransfers.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@solmate/src/tokens/ERC4626.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {LibFormatter} from "./utils/LibFormatter.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/console.sol";

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
    uint64 public destinationChainId;
    address public destinationSenderReceiver;

    bool public vaultLocked;
    uint256 public cacheAssetFromDst;
    uint256 public depositThreshold = 0.1e6; // keeper bot only gets triggered when depositableAsset >= depositThreshold
    uint256 public redeemThreshold = 0.1e6; // keeper bot only gets triggered when penddingWithdrawal >= withdrawThreshold
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

    function initSlowWithdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public whenNotLock returns (uint256 shares) {
        // TODO: implement slow withdraw logic
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotLock returns (uint256 shares) {
        shares = super.withdraw(assets, receiver, owner);
    }

    function initSlowRedeem(uint256 shares, address owner) public whenNotLock {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];

            if (allowed < shares) revert InsufficientAllowance();
        }

        uint256 maxShares = maxRedeem(owner);
        uint256 pendingToRedeem = isPendingToRedeem[owner];
        uint256 maxRedeemableShares = maxShares - pendingToRedeem;

        // prevent inaccurate withdrawal from destination vault
        if (
            pendingToRedeem > 0 &&
            lastRequestToRedeemFromDst[owner] <= lastRedeemFromDst
        ) {
            revert ExistingPendingSharesToBeRedeemedFirst();
        }

        if (shares > maxRedeemableShares) revert ExceedMaxRedeemableShares();

        totalPendingToRedeem += shares;
        pendingToRedeemFromDst += shares;
        isPendingToRedeem[owner] += shares;
        lastRequestToRedeemFromDst[owner] = block.timestamp;

        _checkRedeemThreshold();
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override whenNotLock returns (uint256 assets) {
        uint256 pendingToRedeem = isPendingToRedeem[owner];
        if (pendingToRedeem > 0) {
            uint256 diff = (shares >= pendingToRedeem)
                ? pendingToRedeem
                : shares;

            isPendingToRedeem[owner] -= diff;
            totalPendingToRedeem -= diff;

            // prevent unwanted withdrawal from destination vault
            if (lastRequestToRedeemFromDst[owner] > lastRedeemFromDst) {
                pendingToRedeemFromDst -= diff;
            }
        }
        assets = super.redeem(shares, receiver, owner);
    }

    function execute() public {
        uint256 _depositableAssetToDestination = depositableAssetToDestination();
        if (_depositableAssetToDestination < depositThreshold) {
            revert InsufficientAssetsToBeDeposited();
        }

        // need to pre cache the asset, otherwise,
        // `convertToAssets` will divide to 0 in the very beginning
        cacheAssetFromDst += _depositableAssetToDestination;

        _sendDataAndToken(
            destinationChainId,
            destinationSenderReceiver,
            abi.encodeWithSignature(
                "deposit(uint256)",
                _depositableAssetToDestination
            ),
            address(asset),
            _depositableAssetToDestination
        );
    }

    function quit() public {
        if (pendingToRedeemFromDst < redeemThreshold) {
            revert InsufficientQuitingAmount();
        }

        // TODO: return extra amount (pendingToRedeemFromDst * (1 + withdrawalExtraRatio))

        // redeemableAssets = supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply)
        // shareRatio = shares / supply
        uint256 shareRatio = pendingToRedeemFromDst.mulDivDown(
            10 ** asset.decimals(),
            totalSupply
        );

        _sendData(
            destinationChainId,
            destinationSenderReceiver,
            abi.encodeWithSignature(
                "redeem(uint256,uint256)",
                shareRatio,
                _currentAsset()
            )
        );
    }

    function receiveQuitSignal(uint256 _assetFromDestinationVault) public {
        _onlySelf();
        cacheAssetFromDst = _assetFromDestinationVault;
        lastRedeemFromDst = block.timestamp;
        pendingToRedeemFromDst = 0;
    }

    function depositableAssetToDestination() public view returns (uint256) {
        uint256 _depositAssetBalance = asset.balanceOf(address(this));

        uint256 totalPendingWithdrawal = previewRedeem(totalPendingToRedeem);

        if (totalPendingWithdrawal >= _depositAssetBalance) {
            return 0;
        }

        return _depositAssetBalance - totalPendingWithdrawal;
    }

    function totalAssets() public view override returns (uint256) {
        uint256 _depositAssetBalance = _currentAsset();
        uint256 _totalAssets = _depositAssetBalance + cacheAssetFromDst;
        return _totalAssets;
    }

    function addDestinationChainId(
        uint64 _destinationChainId
    ) public onlyOwner {
        destinationChainId = _destinationChainId;
    }

    function addDestinationSenderReceiver(
        address _destinationSenderReceiver
    ) public onlyOwner {
        destinationSenderReceiver = _destinationSenderReceiver;
    }

    function setDepositThreshold(uint256 _threshold) public onlyOwner {
        depositThreshold = _threshold;
    }

    function setRedeemThreshold(uint256 _threshold) public onlyOwner {
        redeemThreshold = _threshold;
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
        return asset.balanceOf(address(this));
    }

    // AUTOMATION FUNCTIONS
    function checkLog(
        Log calldata log,
        bytes memory
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        performData = abi.encode(log.topics[0]);
    }

    function performUpkeep(bytes calldata performData) external {
        if (
            keccak256("TimeToExecute(uint256,uint256)") ==
            abi.decode(performData, (bytes32))
        ) {
            execute();
        } else if (
            keccak256("TimeToQuit(uint256,uint256)") ==
            abi.decode(performData, (bytes32))
        ) {
            quit();
        }
    }
}
