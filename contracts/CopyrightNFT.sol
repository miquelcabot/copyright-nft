// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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

    // default values for ERC20 tokens
    string internal constant _ERC20_NAME = "Music ERC20 Token";
    string internal constant _ERC20_SYMBOL = "MSC";
    uint256 internal constant _ERC20_PRICE = 1 ether; // 1 ETH

    // metadata to store information about the song
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

    /// @dev Creates a new ERC-721 token
    /// @param name_ Name of the NFT
    /// @param symbol_ Symbol of the NFT
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        EIP712(name_, "1.0.0")
    {
        // we start with token id 1
        _tokenCounter = 1;
    }

    /// @dev Returns the address of the minter user
    /// @return address Address of the minter user
    function minter() external view returns (address) {
        return _minter;
    }

    /// @dev Returns information about the token
    /// @param tokenId Id of the token
    /// @return uint256 Metadata information about the token
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

    /// @dev Returns the address of the ERC20 token created for the NFT token
    /// @param tokenId Id of the token
    /// @return address Address of the ERC20 token
    function getErc20Token(uint256 tokenId) external view returns (address) {
        require(
            _exists(tokenId),
            "ERC721Metadata: you can't query the metadata for nonexistent token"
        );
        return _erc20token[tokenId];
    }

    /// @dev Returns the balance of gains for the copyright of the user
    /// @param owner Address of the user
    /// @return uint256 Balance of gains for the copyright of the user
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

    /// @dev Buy a song, create a new ERC-20 token and sending it to the user
    ///      who bought the song. It also stores the gain for the copyright of the
    ///      song in the owner's balance
    /// @param tokenId Id of the token
    function buySong(uint256 tokenId) external payable {
        require(_exists(tokenId), "ERC721: you can't buy nonexistent token");
        require(
            msg.value >= _ERC20_PRICE,
            "ERC721: you haven't sent the minimum price to buy the song"
        );
        // mint a new ERC20 to the buyer, to consume the song
        ERC20Template(_erc20token[tokenId]).mint(_msgSender(), 1);
        // store the gain for the copyright of the song in the owner's balance
        address owner = ownerOf(tokenId);
        _copyrightBalances[owner] = _copyrightBalances[owner].add(msg.value);
    }

    /// @dev Transfers the gains for the copyright of the song to the owner
    function collectCopyrightGains() external nonReentrant {
        address owner = _msgSender();
        uint256 balance = _copyrightBalances[owner];
        if (balance > 0) {
            _copyrightBalances[owner] = 0;
            // transfer the gains to the owner
            payable(owner).transfer(balance);
        }
    }

    /// @dev Mint a new NFT token to the receiver
    /// @param receiver Address of the user
    /// @param metadata_ Metadata of the song
    function mint(address receiver, Metadata memory metadata_)
        external
        onlyMinter
    {
      _mintAndSetMetadataAndDeployERC20(receiver, metadata_);
    }

    /// @dev Redeem a new NFT token to the receiver usign the ERC712 standard
    /// @param receiver Address of the user
    /// @param metadata_ Metadata of the song
    /// @param signature Signature of the message, signed by a minter user
    function redeem(
        address receiver,
        Metadata memory metadata_,
        bytes calldata signature
    ) external {
        // check that the signer has the minter role
        bytes32 dataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(string songName,string artist,string album,string songURL,address account)"
                    ),
                    keccak256(abi.encodePacked(metadata_.songName)),
                    keccak256(abi.encodePacked(metadata_.artist)),
                    keccak256(abi.encodePacked(metadata_.album)),
                    keccak256(abi.encodePacked(metadata_.songURL)),
                    receiver
                )
            )
        );
        address signer = ECDSA.recover(dataHash, signature);
        require(_isMinter(signer), "ERC721: invalid signature for redeem");

        _mintAndSetMetadataAndDeployERC20(receiver, metadata_);
    }

    /* === CONTROL FUNCTIONS === */

    /// @dev Change the minter user to a new account
    /// @param minter_ Address of the user who will have minter role
    function setMinter(address minter_) external onlyOwner {
        _setMinter(minter_);
    }

    /// @dev Sets a new base URI for the NFT tokens
    /// @param baseURI_ New base URI of the NFT tokens
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @dev Sets a new token URI for the NFT token
    /// @param tokenId Id of the token
    /// @param _tokenURI New token URI of the NFT token
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: you can't set token URI from a caller that is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    /// @dev Sets metadata for the NFT token
    /// @param tokenId Id of the token
    /// @param metadata_ New metadata information of the NFT token
    function setMetadata(uint256 tokenId, Metadata memory metadata_) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: you can't set metadata from a caller that is not owner nor approved"
        );
        _setMetadata(tokenId, metadata_);
    }

    /* === INTERNAL FUNCTIONS === */

    /// @dev Internal function to change the minter user to a new account
    /// @param minter_ Address of the user who will have minter role
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

    /// @dev Internal function to mint a new NFT token, set its metadata and deploy a new ERC20
    /// @param receiver Address of the user
    /// @param metadata_ Metadata of the song
    function _mintAndSetMetadataAndDeployERC20(address receiver, Metadata memory metadata_) internal {
        // no need to check receiver, will be taken care of by
        // underlying mint function
        _safeMint(receiver, _tokenCounter);
        // store the metadata
        _setMetadata(_tokenCounter, metadata_);
        // deploy a new ERC20 token for the NFT token
        _deployERC20Token(_tokenCounter);
        // increment token counter
        _tokenCounter = _tokenCounter.add(1);
    }

    /// @dev Internal function to set metadata for the NFT token
    /// @param tokenId Id of the token
    /// @param metadata_ New metadata information of the NFT token
    function _setMetadata(uint256 tokenId, Metadata memory metadata_) internal {
        require(
            _exists(tokenId),
            "ERC721Metadata: you can't set the metadata for nonexistent token"
        );
        _metadata[tokenId] = metadata_;
        emit MetadataChanged(tokenId, metadata_);
    }

    /// @dev Checks if the user has the minter role
    /// @param _minterAddress Address of the user to check
    /// @return bool True if the user has the minter role
    function _isMinter(address _minterAddress) internal view returns (bool) {
        return _minterAddress == _minter;
    }

    /// @dev Deploy a new ERC20 token for the NFT token
    /// @param tokenId Id of the token
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

    /// @dev Modifier to check if the user has the minter role
    modifier onlyMinter() {
        require(_msgSender() == _minter);
        _;
    }

    /* === EVENTS === */

    /// @dev Event emitted when the metadata of the NFT token is changed
    event MetadataChanged(uint256 indexed _tokenId, Metadata indexed _metadata);
}
