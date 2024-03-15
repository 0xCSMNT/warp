// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {ProgrammableTokenTransfers} from "../src/ProgrammableTokenTransfers.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {MockCCIPRouter} from "test/mock/MockRouter.sol";
import {MockLinkToken, MockCCIPBnMToken} from "test/mock/DummyTokens.sol";
import {SourceVault} from "../src/SourceVault.sol";
import {DestinationVault} from "../src/DestinationVault.sol";
import {SenderReceiver} from "../src/SenderReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract UnitTests is StdCheats, Test {
    
    ////////// CONTRACTS //////////
    ProgrammableTokenTransfers public receiver; // replace later
    SenderReceiver public senderReceiver;

    SourceVault public sourceVault;
    DestinationVault public destinationVault;

    MockCCIPRouter public router;
    MockLinkToken public linkToken;
    MockCCIPBnMToken public ccipBnM;

    ////////// CONSTANTS //////////
    uint256 public constant TOKEN_MINT_BALANCE = 1000e18;
    uint256 public constant TOKEN_TRANSFER_AMOUNT = 10e18;
    address public constant DEV_ACCOUNT_0 =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public constant DEV_ACCOUNT_1 =
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public constant DEV_ACCOUNT_2 =
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

}