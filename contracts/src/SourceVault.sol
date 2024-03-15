// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProgrammableTokenTransfers} from "./ProgrammableTokenTransfers.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@solmate/src/tokens/ERC4626.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {LibFormatter} from "./utils/LibFormatter.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SourceVault is ERC4626, ProgrammableTokenTransfers {
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

    


    
}