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
    uint256 public constant TOKEN_TRANSFER_AMOUNT = 10e6;
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
        sourceVault.allowlistDestinationChain(16015286601757825753, true);
        sourceVault.allowlistSourceChain(16015286601757825753, true);
        sourceVault.allowlistSourceChain(12532609583862916517, true);
        sourceVault.allowlistSender(address(senderReceiver), true);
        sourceVault.addDestinationSenderReceiver(address(senderReceiver));

        receiver.allowlistSourceChain(16015286601757825753, true);
        receiver.allowlistSender(address(sourceVault), true);

        senderReceiver.allowlistDestinationChain(16015286601757825753, true);
        senderReceiver.allowlistSourceChain(16015286601757825753, true);
        senderReceiver.allowlistSender(address(sourceVault), true);
        senderReceiver.addDestinationVault(address(destinationVault));
        senderReceiver.addSourceVault(address(sourceVault));
        senderReceiver.addVaultToken(address(ccipBnM));
        senderReceiver.updateVaultTokenDecimals(ccipBnM.decimals());
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
        sourceVault.deposit(TOKEN_TRANSFER_AMOUNT, DEV_ACCOUNT_0);

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

    ////////// ERC4626 TEST FUNCTIONS //////////

    // test that user can approve and deposit
    function testDeposit() public {
        vm.startPrank(DEV_ACCOUNT_0);
        // approve the transfer
        ccipBnM.approve(address(sourceVault), TOKEN_TRANSFER_AMOUNT);
        sourceVault.deposit(TOKEN_TRANSFER_AMOUNT, DEV_ACCOUNT_0);
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
        sourceVault.deposit(TOKEN_TRANSFER_AMOUNT, DEV_ACCOUNT_0);
        assertEq(sourceVault.totalAssets(), TOKEN_TRANSFER_AMOUNT);
        vm.stopPrank();
    }

    // test that vault can be locked and cause a revert when depositing
    function testLockVault() public {
        sourceVault.lockVault();
        ccipBnM.approve(address(sourceVault), TOKEN_TRANSFER_AMOUNT);
        vm.expectRevert(SourceVault.VaultLocked.selector);
        sourceVault.deposit(TOKEN_TRANSFER_AMOUNT, DEV_ACCOUNT_0);
    }

    // test that the vault can be unlocked
    function testUnlockVault() public {
        sourceVault.lockVault();
        console2.log("Vault locked: ", sourceVault.vaultLocked());
        sourceVault.unlockVault();
        console2.log("Vault locked: ", sourceVault.vaultLocked());

        vm.startPrank(DEV_ACCOUNT_0);
        ccipBnM.approve(address(sourceVault), TOKEN_TRANSFER_AMOUNT);
        sourceVault.deposit(TOKEN_TRANSFER_AMOUNT, DEV_ACCOUNT_0);
        assertEq(sourceVault.totalAssets(), TOKEN_TRANSFER_AMOUNT);
        vm.stopPrank();
    }
}
