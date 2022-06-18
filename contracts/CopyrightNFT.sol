// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721.sol";

/// @title  NFT that represents a copyright for a song
/// @author Miquel A. Cabot
/// @notice With this NFT you can demostrate the ownership of a song, and you will
///         be able to create new ERC20 tokens to consume this song and collect
///         profits for its use
/// @dev    This implementation follows the EIP-721 standard
///         (https://eips.ethereum.org/EIPS/eip-721)
contract CopyrightNFT is Ownable, ERC721 {
    using SafeMath for uint256;

    // address of minter user
    address internal _minter;
    // counter for token ids
    uint256 internal _tokenCounter;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        // we start with token id 1
        _tokenCounter = 1;
    }

    function minter() external view returns (address) {
        return _minter;
    }

    function mint(address receiver) external onlyMinter {
        // no need to check receiver, will be taken care of by
        // underlying mint function
        _safeMint(receiver, _tokenCounter);
        // increment token counter
        _tokenCounter = _tokenCounter.add(1);
    }

    /* === CONTROL FUNCTIONS === */

    function setMinter(address minter_) external onlyOwner {
        _setMinter(minter_);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: you can't set token URI from a caller that is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    /* === INTERNAL FUNCTIONS === */

    function _setMinter(address minter_) internal {
        require(
            minter_ != address(0),
            "ERC721: you can't set minter to the zero address"
        );
        require(minter_ != _minter, "ERC721: you can't set minter to the same address");
        _minter = minter_;
    }

    function _isMinter(address _minterAddress) internal view returns (bool) {
        return _minterAddress == _minter;
    }

    /* === MODIFIERS === */

    modifier onlyMinter() {
        require(_msgSender() == _minter);
        _;
    }
}
