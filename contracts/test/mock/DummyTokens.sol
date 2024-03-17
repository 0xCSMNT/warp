// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockCCIPBnMToken is ERC20 {
    constructor() ERC20("Mock CCIP-BnM", "mCCIP-BnM") {
        _mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1000e18); // Anvil 0
    }

    function decimals() public view override returns (uint8) {
        return 6;
    }
}

contract MockTestToken is ERC20 {
    constructor() ERC20("TestToken", "TEST") {
        _mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1000e18); // Anvil 0
    }
}

contract MockLinkToken is ERC20 {
    constructor() ERC20("Mock Link", "mLINK") {
        _mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1000e18); // Anvil 0
    }
}

contract MockTokenDeployer {
    MockCCIPBnMToken public mockCCIPBnM;
    MockTestToken public mockTest;
    MockLinkToken public mockLink;

    constructor() {
        mockCCIPBnM = new MockCCIPBnMToken();
        mockTest = new MockTestToken();
        mockLink = new MockLinkToken();
    }
}
