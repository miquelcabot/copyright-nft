// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721.sol";

contract CopyrightNFT is Ownable, ERC721 {
    using SafeMath for uint256;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
    }
}
