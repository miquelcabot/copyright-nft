// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./ERC20Template.sol";
import "./ERC721.sol";

/// @title  NFT that represents a copyright for a song
/// @author Miquel A. Cabot
/// @notice With this NFT you can demostrate the ownership of a song, and you will
///         be able to create new ERC20 tokens to consume this song and collect
///         profits for its use
/// @dev    This implementation follows the EIP-721 standard
///         (https://eips.ethereum.org/EIPS/eip-721)
contract CopyrightNFT is Ownable, ReentrancyGuard, ERC721, EIP712 {
    using SafeMath for uint256;

    string internal constant _ERC20_NAME = "Music ERC20 Token";
    string internal constant _ERC20_SYMBOL = "MSC";
    uint256 internal constant _ERC20_PRICE = 1 ether; // 1 ETH

    struct Metadata {
        string songName;
        string artist;
        string album;
        string songURL;
    }

    // address of minter user
    address internal _minter;
    // counter for token ids
    uint256 internal _tokenCounter;
    // stored metadata for each token
    mapping(uint256 => Metadata) private _metadata;
    // store ERC20 token address created for each NFT token
    mapping(uint256 => address) private _erc20token;
    // store balance of copyright NFT token for each user (bought songs)
    mapping(address => uint256) private _copyrightBalances;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        EIP712(name_, "1.0.0")
    {
        // we start with token id 1
        _tokenCounter = 1;
    }

    function minter() external view returns (address) {
        return _minter;
    }

    function getMetadata(uint256 tokenId)
        external
        view
        returns (Metadata memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: you can't query the metadata for nonexistent token"
        );
        return _metadata[tokenId];
    }

    function getErc20Token(uint256 tokenId) external view returns (address) {
        require(
            _exists(tokenId),
            "ERC721Metadata: you can't query the metadata for nonexistent token"
        );
        return _erc20token[tokenId];
    }

    function getCopyrightBalance(address owner)
        external
        view
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: you can't query the copyright balance of the zero address"
        );
        return _copyrightBalances[owner];
    }

    function buySong(uint256 tokenId) external payable {
        require(_exists(tokenId), "ERC721: you can't buy nonexistent token");
        require(
            msg.value >= _ERC20_PRICE,
            "ERC721: you haven't sent the minimum price to buy the song"
        );
        ERC20Template(_erc20token[tokenId]).mint(_msgSender(), 1);
        address owner = ownerOf(tokenId);
        _copyrightBalances[owner] = _copyrightBalances[owner].add(msg.value);
    }

    function collectCopyrightGains() external nonReentrant {
        address owner = _msgSender();
        uint256 balance = _copyrightBalances[owner];
        if (balance > 0) {
            _copyrightBalances[owner] = 0;
            payable(owner).transfer(balance);
        }
    }

    function mint(address receiver, Metadata memory metadata_)
        external
        onlyMinter
    {
        // no need to check receiver, will be taken care of by
        // underlying mint function
        _safeMint(receiver, _tokenCounter);
        _setMetadata(_tokenCounter, metadata_);
        _deployERC20Token(_tokenCounter);
        // increment token counter
        _tokenCounter = _tokenCounter.add(1);
    }

    function redeem(
        address receiver,
        Metadata memory metadata_,
        address signer,
        bytes calldata signature
    ) external {
        bytes32 dataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(string songName,string artist,string album,string songURL,address account)"
                    ),
                    metadata_.songName,
                    metadata_.artist,
                    metadata_.album,
                    metadata_.songURL,
                    receiver
                )
            )
        );
        require(
            SignatureChecker.isValidSignatureNow(signer, dataHash, signature),
            "ERC721: invalid signature for redeem"
        );
        require(_isMinter(signer), "ERC721: signer is not a minter");

        _safeMint(receiver, _tokenCounter);
        _setMetadata(_tokenCounter, metadata_);
        _deployERC20Token(_tokenCounter);
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

    function setMetadata(uint256 tokenId, Metadata memory metadata_) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: you can't set metadata from a caller that is not owner nor approved"
        );
        _setMetadata(tokenId, metadata_);
    }

    /* === INTERNAL FUNCTIONS === */

    function _setMinter(address minter_) internal {
        require(
            minter_ != address(0),
            "ERC721: you can't set minter to the zero address"
        );
        require(
            minter_ != _minter,
            "ERC721: you can't set minter to the same address"
        );
        _minter = minter_;
    }

    function _setMetadata(uint256 tokenId, Metadata memory metadata_) internal {
        require(
            _exists(tokenId),
            "ERC721Metadata: you can't set the metadata for nonexistent token"
        );
        _metadata[tokenId] = metadata_;
        emit MetadataChanged(tokenId, metadata_);
    }

    function _isMinter(address _minterAddress) internal view returns (bool) {
        return _minterAddress == _minter;
    }

    function _deployERC20Token(uint256 tokenId) internal {
        // create ERC20 token
        ERC20Template erc20token = new ERC20Template(
            string(
                abi.encodePacked(_ERC20_NAME, " ", Strings.toString(tokenId))
            ),
            string(abi.encodePacked(_ERC20_SYMBOL, Strings.toString(tokenId)))
        );
        _erc20token[tokenId] = address(erc20token);
    }

    /* === MODIFIERS === */

    modifier onlyMinter() {
        require(_msgSender() == _minter);
        _;
    }

    /* === EVENTS === */

    event MetadataChanged(uint256 indexed _tokenId, Metadata indexed _metadata);
}
