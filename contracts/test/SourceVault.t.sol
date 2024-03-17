// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {SourceVault} from "../src/SourceVault.sol";
import {UnitTests} from "./UnitTests.t.sol";
import "forge-std/console.sol";
contract SourceVaultTest is UnitTests {
    modifier asDevAccount0() {
        depositTokensToSourceVault();

        vm.startPrank(DEV_ACCOUNT_0);
        _;
        vm.stopPrank();
    }

    modifier asDevAccount1() {
        depositTokensToSourceVault();

        vm.prank(DEV_ACCOUNT_0);
        sourceVault.approve(DEV_ACCOUNT_1, TOKEN_TRANSFER_AMOUNT);

        vm.startPrank(DEV_ACCOUNT_1);
        _;
        vm.stopPrank();
    }

    // initSlowRedeem()

    function testInitSlowRedeem() public asDevAccount0 {
        _initSlowRedeem();
    }

    function testInitSlowRedeemTwice() public asDevAccount0 {
        _initSlowRedeemTwice();
    }

    function testInitSlowRedeemExceedMaxRedeem() public asDevAccount0 {
        _initSlowRedeemExceedMaxRedeem();
    }

    function testInitSlowRedeemFromDev1() public asDevAccount1 {
        _initSlowRedeem();
    }

    function testInitSlowRedeemTwiceFromDev1() public asDevAccount1 {
        _initSlowRedeemTwice();
    }

    function testInitSlowRedeemExceedMaxRedeemFromDev1() public asDevAccount1 {
        uint256 shares = sourceVault.balanceOf(DEV_ACCOUNT_0);
        assertTrue(shares > 0, "shares > 0");

        vm.expectRevert(SourceVault.InsufficientAllowance.selector);
        sourceVault.initSlowRedeem(shares + 1, DEV_ACCOUNT_0);

        sourceVault.initSlowRedeem(shares, DEV_ACCOUNT_0);
        vm.expectRevert(SourceVault.ExceedMaxRedeemableShares.selector);
        sourceVault.initSlowRedeem(shares, DEV_ACCOUNT_0);
    }

    function testInitSlowRedeemInsufficientAllowanceFromDev2() public {
        depositTokensToSourceVault();

        vm.startPrank(DEV_ACCOUNT_2);
        uint256 shares = sourceVault.balanceOf(DEV_ACCOUNT_0);
        assertTrue(shares > 0, "shares > 0");

        vm.expectRevert(SourceVault.InsufficientAllowance.selector);
        sourceVault.initSlowRedeem(shares, DEV_ACCOUNT_0);
        vm.stopPrank();
    }

    function testInitSlowRedeemRevertWithExistingPendingSharesToBeRedeemedFirst()
        public
        asDevAccount1
    {
        assertTrue(false, "TODO");
    }

    // redeem

    function testRedeemWithoutPendingToRedeem() public asDevAccount0 {
        uint256 shares = sourceVault.balanceOf(DEV_ACCOUNT_0);
        uint256 halfShares = shares / 2;
        assertTrue(halfShares > 0, "halfShares > 0");

        uint256 initBalance = ccipBnM.balanceOf(DEV_ACCOUNT_0);
        sourceVault.redeem(halfShares, DEV_ACCOUNT_0, DEV_ACCOUNT_0);

        assertEq(
            sourceVault.isPendingToRedeem(DEV_ACCOUNT_0),
            0,
            "isPendingToRedeem(DEV_ACCOUNT_0) != 0"
        );
        assertEq(
            sourceVault.totalPendingToRedeem(),
            0,
            "totalPendingToRedeem != 0"
        );
        assertEq(
            sourceVault.pendingToRedeemFromDst(),
            0,
            "pendingToRedeemFromDst != 0"
        );
        uint256 withdrawalAmount = ccipBnM.balanceOf(DEV_ACCOUNT_0) -
            initBalance;
        assertEq(withdrawalAmount, halfShares);
    }

    function testRedeemWithPendingToRedeem() public asDevAccount0 {
        uint256 shares = sourceVault.balanceOf(DEV_ACCOUNT_0);
        uint256 halfShares = shares / 2;
        assertTrue(halfShares > 0, "halfShares > 0");

        uint256 initBalance = ccipBnM.balanceOf(DEV_ACCOUNT_0);
        sourceVault.initSlowRedeem(shares, DEV_ACCOUNT_0);
        sourceVault.redeem(halfShares, DEV_ACCOUNT_0, DEV_ACCOUNT_0);

        assertEq(
            sourceVault.isPendingToRedeem(DEV_ACCOUNT_0),
            halfShares,
            "isPendingToRedeem(DEV_ACCOUNT_0) != halfShares"
        );
        assertEq(
            sourceVault.totalPendingToRedeem(),
            halfShares,
            "totalPendingToRedeem != halfShares"
        );
        assertEq(
            sourceVault.pendingToRedeemFromDst(),
            halfShares,
            "pendingToRedeemFromDst != halfShares"
        );
        uint256 withdrawalAmount = ccipBnM.balanceOf(DEV_ACCOUNT_0) -
            initBalance;
        assertEq(withdrawalAmount, halfShares);
    }

    function testRedeemWithPendingToRedeemAfterQuit() public asDevAccount0 {
        assertTrue(false, "TODO");
    }

    // execute

    function testExecute() public {
        depositTokensToSourceVault(); // 10e18
        uint256 userBalance = sourceVault.maxWithdraw(DEV_ACCOUNT_0);

        sourceVault.addDestinationChainId(16015286601757825753);
        sourceVault.addDestinationSenderReceiver(address(senderReceiver));
        senderReceiver.addSourceChainId(16015286601757825753);
        senderReceiver.addSourceVault(address(sourceVault));
        sourceVault.execute();

        uint256 senderReceiverBalance = destinationVault.balanceOf(
            address(senderReceiver)
        );
        assertEq(userBalance, senderReceiverBalance, "assets are not equal");
    }

    // quit

    function testQuit() public {
        depositTokensToSourceVault(); // 10e18
        uint256 userBalance = sourceVault.maxWithdraw(DEV_ACCOUNT_0);

        senderReceiver.addSourceChainId(16015286601757825753);
        senderReceiver.addSourceVault(address(sourceVault));
        sourceVault.addDestinationChainId(12532609583862916517);
        sourceVault.addDestinationSenderReceiver(address(senderReceiver));
        sourceVault.execute();

        vm.startPrank(DEV_ACCOUNT_0);
        uint256 maxRedeem = sourceVault.maxRedeem(DEV_ACCOUNT_0);

        sourceVault.initSlowRedeem(maxRedeem, DEV_ACCOUNT_0);
        vm.stopPrank();

        uint256 initialTimestamp = block.timestamp;
        skip(1);
        sourceVault.quit();

        uint256 senderReceiverBalance = destinationVault.balanceOf(
            address(senderReceiver)
        );

        uint256 assetsOfSourceVault = ccipBnM.balanceOf(address(sourceVault));

        assertEq(
            senderReceiverBalance,
            0,
            "assets on destination chain should be 0"
        );

        assertEq(
            assetsOfSourceVault,
            userBalance,
            "assets on source chain should be equal to user balance"
        );
        assertEq(
            sourceVault.isPendingToRedeem(DEV_ACCOUNT_0),
            userBalance,
            "isPendingToRedeem(DEV_ACCOUNT_0) != 0"
        );
        assertEq(
            block.timestamp - initialTimestamp,
            1,
            "lastRedeemFromDst is incorrect"
        );
        assertEq(
            sourceVault.totalAssets(),
            assetsOfSourceVault,
            "totalAssets is incorrect"
        );
    }

    // helper

    function _initSlowRedeem() internal {
        uint256 shares = sourceVault.balanceOf(DEV_ACCOUNT_0);
        uint256 halfShares = shares / 2;
        assertTrue(halfShares > 0, "halfShares > 0");
        skip(1);

        sourceVault.initSlowRedeem(halfShares, DEV_ACCOUNT_0);

        assertEq(
            sourceVault.lastRequestToRedeemFromDst(DEV_ACCOUNT_0),
            block.timestamp
        );

        assertEq(
            sourceVault.isPendingToRedeem(DEV_ACCOUNT_0),
            halfShares,
            "isPendingToRedeem(DEV_ACCOUNT_0) != halfShares"
        );
        assertEq(
            sourceVault.totalPendingToRedeem(),
            halfShares,
            "totalPendingToRedeem != halfShares"
        );
        assertEq(
            sourceVault.pendingToRedeemFromDst(),
            halfShares,
            "pendingToRedeemFromDst != halfShares"
        );
    }

    function _initSlowRedeemTwice() internal {
        uint256 shares = sourceVault.balanceOf(DEV_ACCOUNT_0);
        uint256 halfShares = shares / 2;
        assertTrue(halfShares > 0, "halfShares > 0");

        sourceVault.initSlowRedeem(halfShares, DEV_ACCOUNT_0);
        sourceVault.initSlowRedeem(halfShares, DEV_ACCOUNT_0);

        assertEq(
            sourceVault.isPendingToRedeem(DEV_ACCOUNT_0),
            shares,
            "isPendingToRedeem(DEV_ACCOUNT_0) != shares"
        );
        assertEq(
            sourceVault.totalPendingToRedeem(),
            shares,
            "totalPendingToRedeem != shares"
        );
        assertEq(
            sourceVault.pendingToRedeemFromDst(),
            shares,
            "pendingToRedeemFromDst != shares"
        );
    }

    function _initSlowRedeemExceedMaxRedeem() internal {
        uint256 shares = sourceVault.balanceOf(DEV_ACCOUNT_0);
        assertTrue(shares > 0, "shares > 0");

        vm.expectRevert(SourceVault.ExceedMaxRedeemableShares.selector);
        sourceVault.initSlowRedeem(shares + 1, DEV_ACCOUNT_0);

        sourceVault.initSlowRedeem(shares, DEV_ACCOUNT_0);
        vm.expectRevert(SourceVault.ExceedMaxRedeemableShares.selector);
        sourceVault.initSlowRedeem(shares, DEV_ACCOUNT_0);
    }

    
}
