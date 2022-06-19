// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title  ERC-20 Fungible Token template
/// @author Miquel A. Cabot
/// @notice Used by CopyrightNFT to deploy a new ERC-20 token
/// @dev    This implementation follows the EIP-20 standard
///         (https://eips.ethereum.org/EIPS/eip-20)
contract ERC20Template is ERC20, Ownable {
    using SafeMath for uint256;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function mint(address to, uint256 value) external onlyOwner {
        _mint(to, value);
    }
}
