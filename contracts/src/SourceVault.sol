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

contract SourceVault is ProgrammableTokenTransfers, ERC4626, ILogAutomation {
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

    // STATE VARIABLES FOR DEPOSIT LIMIT
    uint256 public depositThreshold;
    uint256 public currentDeposits;

    uint256 public tempDepositCounter = 0;

    // OTHER STATE VARIABLES
    address public destinationVault;
    bool public vaultLocked;
    uint256 public cacheAssetFromDestinationVault; // what is this
    uint256 public withdrawThreshold; // what is this
    uint256 public penddingWithdrawal; // what is this
    mapping(address => bool) public isPendingToWithdraw;
    uint256 public withdrawalExtraRatio; // 5% = 5e6

    // EVENTS
    event DepositLimitExceeded(uint256 currentDeposits);
    event CurrentDepositsReset(uint256 currentDeposits);

    // ERC4626 OVERRIDES
    function _deposit(uint _assets) public {
        require(!vaultLocked, "Vault is locked");
        require(_assets > 0, "Deposit must be greater than 0");
        deposit(_assets, msg.sender);
        currentDeposits += _assets;

        if (currentDeposits > depositThreshold) {
            emit DepositLimitExceeded(currentDeposits);
        }
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

    function totalAssets() public view override returns (uint256) {
        uint256 _depositAssetBalance = asset
            .balanceOf(address(this))
            .formatDecimals(asset.decimals(), 18);
        uint256 _totalAssets = _depositAssetBalance +
            cacheAssetFromDestinationVault;
        return _totalAssets;
    }

    // TODO: only allow this function to specific addresses
    function setCacheAssetFromDestinationVault(uint256 _amount) public {
        cacheAssetFromDestinationVault = _amount;
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

    // VAULT LOCKING FUNCTIONS
    function lockVault() internal {
        // Vault locking logic
        vaultLocked = true;
    }

    function unlockVault() internal {
        vaultLocked = false;
    }

    // Owner can pause the vault for safety
    function ownerLockVault() external onlyOwner {
        lockVault();
    }

    function ownerUnlockVault() external onlyOwner {
        unlockVault();
    }

    function batchSendToDestinationVault(string calldata messageSent) public {
        require(asset.balanceOf(address(this)) > 0, "No assets to send");
        sendMessagePayLINK(
            DestinationChainId,
            DestinationSenderReceiver,
            messageSent,
            address(asset),
            asset.balanceOf(address(this))
        );
        currentDeposits = 0;
    }

    function increaseTempDepositCounter() public {
        tempDepositCounter++;
    }

    // AUTOMATION FUNCTIONS

    // function checkLog(
    //     Log calldata log,
    //     bytes memory
    // ) external pure returns (bool upkeepNeeded, bytes memory performData) {
    //     upkeepNeeded = true;
    //     address logSender = bytes32ToAddress(log.topics[1]);
    //     performData = abi.encode(logSender);
    // }

    function checkLog(
        Log calldata log,
        bytes memory
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
    }

    function performUpkeep(bytes calldata performData) external {
        increaseTempDepositCounter();
    }
}
