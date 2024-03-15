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

    function testCorrectDestinationChainId() public {
        //check that the destination chain id is correct on TokenTransferor
        assertTrue(
            sourceVault.allowlistedDestinationChains(12532609583862916517),
            "Destination chain id is not correctly allowlisted"
        );
    }
}
