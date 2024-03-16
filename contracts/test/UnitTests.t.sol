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

    ////////// SETUP //////////
    function setUp() external {
        router = new MockCCIPRouter();
        linkToken = new MockLinkToken();
        ccipBnM = new MockCCIPBnMToken();

        receiver = new ProgrammableTokenTransfers(
            address(router),
            address(linkToken)
        );

        senderReceiver = new SenderReceiver(
            address(router),
            address(linkToken)
        );

        sourceVault = new SourceVault(
            ERC20(address(ccipBnM)),
            "SourceVault",
            "SV",
            address(router),
            address(linkToken)
        );

        destinationVault = new DestinationVault(
            ERC20(address(ccipBnM)),
            "DestinationVault",
            "DV"
        );

        sourceVault.allowlistDestinationChain(12532609583862916517, true);

        receiver.allowlistSourceChain(16015286601757825753, true);
        receiver.allowlistSender(address(sourceVault), true);

        senderReceiver.allowlistSourceChain(16015286601757825753, true);
        senderReceiver.allowlistSender(address(sourceVault), true);
        senderReceiver.addDestinationVault(address(destinationVault));
        senderReceiver.addVaultToken(address(ccipBnM));
    }

    ////////// HELPER FUNCTIONS //////////
    // transfer mocklink tokens to SourceVault from dev account 0

    function transferLinkTokensToSourceVault() public {
        vm.startPrank(DEV_ACCOUNT_0);

        linkToken.transfer(address(sourceVault), TOKEN_MINT_BALANCE);

        vm.stopPrank();
    }

    // function deposit tokens to SourceVault from dev account 0
    function depositTokensToSourceVault() public {
        vm.startPrank(DEV_ACCOUNT_0);

        ccipBnM.approve(address(sourceVault), TOKEN_TRANSFER_AMOUNT);
        sourceVault._deposit(TOKEN_TRANSFER_AMOUNT);

        vm.stopPrank();
    }

    function fundReceiver() public {
        address receiverAddress = address(receiver);
        vm.deal(receiverAddress, TOKEN_TRANSFER_AMOUNT);
    }

    ////////// SETUP TESTS //////////

    function testCorrectDestinationChainId() public view {
        //check that the destination chain id is correct on TokenTransferor
        assertTrue(
            sourceVault.allowlistedDestinationChains(12532609583862916517),
            "Destination chain id is not correctly allowlisted"
        );
    }

    function testCorrectAddressesForRouterAndLinkToken() public view {
        //check that the router and link token addresses are correct on TokenTransferor
        assertTrue(
            address(router) == sourceVault.getRouterAddress(),
            "Router address is not correct"
        );
        assertTrue(
            address(linkToken) == sourceVault.getLinkTokenAddress(),
            "Link token address is not correct"
        );
    }

    function testSenderHasTokens() public {
        transferLinkTokensToSourceVault();
        uint256 linkBalance = linkToken.balanceOf(address(sourceVault));
        // uint256 ccipBnMBalance = ccipBnM.balanceOf(address(sender));
        assertTrue(
            linkBalance == TOKEN_MINT_BALANCE,
            "SourceVault does not have the correct amount of link tokens"
        );
    }

    function testReceiverHasETH() public {
        fundReceiver();
        assertEq(address(receiver).balance, TOKEN_TRANSFER_AMOUNT);
        console2.log("Receiver Balance: ", address(receiver).balance / 1e18);
    }

    // Check that the asset address is correct
    function testCorrectSourceVaultAssetAddress() public view {
        assertEq(
            address(sourceVault.asset()),
            address(ccipBnM),
            "Asset address is incorrect"
        );
    }

    // Check that Dev account 0 has the correct amount of tokens
    function testDevAccountBalance() public view {
        assertEq(
            ccipBnM.balanceOf(DEV_ACCOUNT_0),
            TOKEN_MINT_BALANCE,
            "Dev account does not have the correct amount of tokens"
        );
    }

    ////////// CCIP TEST FUNCTIONS //////////

    // Test that the SourceVault can transfer tokens only to the receiver
    function testTransferTokensPayLINK() public {
        transferLinkTokensToSourceVault();
        depositTokensToSourceVault();
        sourceVault.transferTokensPayLINK(
            uint64(12532609583862916517),
            address(receiver),
            address(ccipBnM),
            uint256(TOKEN_TRANSFER_AMOUNT)
        );
        uint256 receiverBalance = ccipBnM.balanceOf(address(receiver));

        console2.log("Receiver Balance: ", receiverBalance / 1e18);
        assertEq(
            receiverBalance,
            TOKEN_TRANSFER_AMOUNT,
            "receiver did not receive the expected amount of tokens."
        );
    }

    ////////// ERC4626 TEST FUNCTIONS //////////

    // test that user can approve and deposit
    function testDeposit() public {
        vm.startPrank(DEV_ACCOUNT_0);
        // approve the transfer
        ccipBnM.approve(address(sourceVault), TOKEN_TRANSFER_AMOUNT);
        sourceVault._deposit(TOKEN_TRANSFER_AMOUNT);
        vm.stopPrank();
        console2.log("No of shares: ", sourceVault.totalSupply());
        //assert total assets are equal to the amount deposited
        assertEq(
            sourceVault.totalAssets(),
            TOKEN_TRANSFER_AMOUNT,
            "Total assets are not equal to the amount deposited"
        );
    }

    // test total assets are correct before and after deposit
    function testTotalAssets() public {
        vm.startPrank(DEV_ACCOUNT_0);
        assertEq(sourceVault.totalAssets(), 0);
        ccipBnM.approve(address(sourceVault), TOKEN_TRANSFER_AMOUNT);
        sourceVault._deposit(TOKEN_TRANSFER_AMOUNT);
        assertEq(sourceVault.totalAssets(), TOKEN_TRANSFER_AMOUNT);
        sourceVault.setCacheAssetFromDestinationVault(1e18);
        assertEq(sourceVault.totalAssets(), TOKEN_TRANSFER_AMOUNT + 1e18);
        vm.stopPrank();
    }

    // test that user can deposit from receiver into destination vault
    function testDepositToDestinationVault() public {
        vm.startPrank(DEV_ACCOUNT_0);
        ccipBnM.transfer(address(senderReceiver), TOKEN_TRANSFER_AMOUNT);
        console2.log(
            "SenderReceiver Balance: ",
            ccipBnM.balanceOf(address(senderReceiver))
        );
        senderReceiver.DepositToDestinationVault(TOKEN_TRANSFER_AMOUNT);
        console2.log(
            "DestinationVault Balance: ",
            ccipBnM.balanceOf(address(destinationVault))
        );
        console2.log(
            "SenderReceiver Closing Balance:",
            ccipBnM.balanceOf(address(senderReceiver))
        );

        assertEq(
            ccipBnM.balanceOf(address(destinationVault)),
            TOKEN_TRANSFER_AMOUNT,
            "DestinationVault did not receive the expected amount of tokens."
        );
    }

    // test that user can approve and withdraw when sufficient funds are available
    function testSimpleWithdraw() public {
        vm.startPrank(DEV_ACCOUNT_0);
        ccipBnM.approve(address(sourceVault), TOKEN_TRANSFER_AMOUNT);
        sourceVault._deposit(TOKEN_TRANSFER_AMOUNT);
        console2.log("No of shares after deposit: ", sourceVault.totalSupply());

        // Calculate the amount of shares based on the deposit
        uint256 sharesToWithdraw = sourceVault.balanceOf(DEV_ACCOUNT_0);
        sourceVault._withdraw(sharesToWithdraw, DEV_ACCOUNT_0);
        vm.stopPrank();

        // Assert that user has received full amount of fees in return
        assertEq(ccipBnM.balanceOf(DEV_ACCOUNT_0), TOKEN_MINT_BALANCE);
        console2.log(
            "No of shares after withdrawal: ",
            sourceVault.totalSupply()
        );
    }

    // test that vault can be locked and cause a revert when depositing
    function testOwnerLockVault() public {
        sourceVault.ownerLockVault();
        ccipBnM.approve(address(sourceVault), TOKEN_TRANSFER_AMOUNT);
        vm.expectRevert("Vault is locked");
        sourceVault._deposit(TOKEN_TRANSFER_AMOUNT);
    }

    // test that the vault can be unlocked
    function testOwnerUnlockVault() public {
        sourceVault.ownerLockVault();
        console2.log("Vault locked: ", sourceVault.vaultLocked());
        sourceVault.ownerUnlockVault();
        console2.log("Vault locked: ", sourceVault.vaultLocked());

        vm.startPrank(DEV_ACCOUNT_0);
        ccipBnM.approve(address(sourceVault), TOKEN_TRANSFER_AMOUNT);
        sourceVault._deposit(TOKEN_TRANSFER_AMOUNT);
        assertEq(sourceVault.totalAssets(), TOKEN_TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    ////////// CROSS CHAIN VAULT TEST FUNCTIONS //////////

    // test that source vault can send to receiver and user can deposit from receiver to destination vault
    function testCrossChainTransactionAndDeposit() public {
        transferLinkTokensToSourceVault();
        depositTokensToSourceVault();
        sourceVault.sendMessagePayLINK(
            uint64(12532609583862916517),
            address(senderReceiver),
            "Tokens Arrived",
            address(ccipBnM),
            uint256(TOKEN_TRANSFER_AMOUNT)
        );

        (
            ,
            string memory messageReceived,
            ,
            uint256 tokensReceived
        ) = senderReceiver.getLastReceivedMessageDetails();

        console2.log("Message Received: ", messageReceived);
        console2.log("Tokens Received: ", tokensReceived / 1e18);

        senderReceiver.DepositToDestinationVault(TOKEN_TRANSFER_AMOUNT);
        console2.log("msg.sender in test script:", msg.sender);

        assertEq(
            ccipBnM.balanceOf(address(destinationVault)),
            TOKEN_TRANSFER_AMOUNT,
            "DestinationVault did not receive the expected amount of tokens."
        );

        uint256 userShareBalance = sourceVault.balanceOf(DEV_ACCOUNT_0);
        uint256 senderReceiverShareBalance = destinationVault.balanceOf(
            address(senderReceiver)
        );

        assertEq(
            userShareBalance,
            senderReceiverShareBalance,
            "Shares are not equal"
        );

        console2.log("User Share Balance: ", userShareBalance);
        console2.log(
            "SenderReceiver Share Balance: ",
            senderReceiverShareBalance
        );
    }

    // test that can send a ccip message and call deposit function on receiver
    function testCrossChainFunctionCallDeposit() public {
        string memory messageSent = "DepositToDestinationVault(uint256)";
        transferLinkTokensToSourceVault();
        depositTokensToSourceVault();
        sourceVault.sendMessagePayLINK(
            uint64(12532609583862916517),
            address(senderReceiver),
            messageSent,
            address(ccipBnM),
            uint256(TOKEN_TRANSFER_AMOUNT)
        );
        console2.log(
            "SenderReceiver Balance: ",
            ccipBnM.balanceOf(address(senderReceiver))
        );
        console2.log(
            "DestinationVault Balance: ",
            ccipBnM.balanceOf(address(destinationVault))
        );
        assertEq(
            ccipBnM.balanceOf(address(destinationVault)),
            TOKEN_TRANSFER_AMOUNT,
            "DestinationVault did not receive the expected amount of tokens."
        );

        uint256 userShareBalance = sourceVault.balanceOf(DEV_ACCOUNT_0);
        uint256 senderReceiverShareBalance = destinationVault.balanceOf(
            address(senderReceiver)
        );

        assertEq(
            userShareBalance,
            senderReceiverShareBalance,
            "Shares are not equal"
        );

        console2.log("User Share Balance: ", userShareBalance / 1e18);
        console2.log(
            "SenderReceiver Share Balance: ",
            senderReceiverShareBalance / 1e18
        );
    }

    // test a that a dummy keeper can be set and call the bridge function
    function testDummyKeeperAndBridgeFunction() public {
        address dummyKeeper = DEV_ACCOUNT_1;
        sourceVault.addTimeBasedKeeper(dummyKeeper);
        string memory messageSent = "DepositToDestinationVault(uint256)";
        transferLinkTokensToSourceVault();
        depositTokensToSourceVault();

        sourceVault.addDestinationChainId(12532609583862916517);
        sourceVault.addDestinationSenderReceiver(address(senderReceiver));

        console2.log(
            "timeBasedKeeper on SourceVault",
            sourceVault.timeBasedKeeper()
        );
        console2.log("dummyKeeper", dummyKeeper);
        console2.log("sourceVault Owner", sourceVault.owner());

        assertEq(
            sourceVault.timeBasedKeeper(),
            dummyKeeper,
            "Dummy keeper was not set correctly"
        );

        vm.startPrank(dummyKeeper);
        sourceVault.batchSendToDestinationVault(messageSent);
        vm.stopPrank();

        assertEq(
            ccipBnM.balanceOf(address(destinationVault)),
            TOKEN_TRANSFER_AMOUNT,
            "DestinationVault did not receive the expected amount of tokens."
        );
    }

    function testThresholdBasedKeeperAndBridgeFunction() public {
        address thresholdBasedKeeper = DEV_ACCOUNT_2;
        sourceVault.addThresholdBasedKeeper(thresholdBasedKeeper);
        string memory messageSent = "DepositToDestinationVault(uint256)";
        transferLinkTokensToSourceVault();

        sourceVault.addDestinationChainId(12532609583862916517);
        sourceVault.addDestinationSenderReceiver(address(senderReceiver));
        sourceVault.setDepositThreshold(1e18);

        console2.log(
            "thresholdBasedKeeper on SourceVault",
            sourceVault.thresholdBasedKeeper()
        );
        console2.log("thresholdBasedKeeper", thresholdBasedKeeper);
        console2.log("sourceVault Owner", sourceVault.owner());
        console2.log(
            "sourceVault Deposit Threshold",
            sourceVault.depositThreshold()
        );

        depositTokensToSourceVault();

        assertEq(
            sourceVault.thresholdBasedKeeper(),
            thresholdBasedKeeper,
            "Threshold based keeper was not set correctly"
        );

        vm.startPrank(thresholdBasedKeeper);
        sourceVault.batchSendToDestinationVault(messageSent);
        vm.stopPrank();

        assertEq(
            ccipBnM.balanceOf(address(destinationVault)),
            TOKEN_TRANSFER_AMOUNT,
            "DestinationVault did not receive the expected amount of tokens."
        );
    }
}
