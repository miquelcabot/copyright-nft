// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ERC20Template is ERC20 {
    using SafeMath for uint256;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}
}
