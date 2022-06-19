// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/AddressUtils.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721TokenReceiver.sol";

/// @title  ERC-721 Non-Fungible Token, with optional metadata extension
/// @author Miquel A. Cabot
/// @dev    This implementation follows the EIP-721 standard
///         (https://eips.ethereum.org/EIPS/eip-721)
contract ERC721 is Context, IERC721Metadata {
    using SafeMath for uint256;
    using AddressUtils for address;

    // name of the NFT token
    string private _name;
    // symbol of the NFT token
    string private _symbol;
    // token URIs for every NFT token (tokenId -> token URI)
    mapping(uint256 => string) private _tokenURIs;
    // base URI for the NFT tokens
    string private _baseURI;
    // owner for every NFT token (tokenId -> token owner)
    mapping(uint256 => address) private _owners;
    // balance for every user (user -> balance)
    mapping(address => uint256) private _balances;
    // approval for every token (tokenId -> address aproved)
    mapping(uint256 => address) private _tokenApprovals;
    // operator approvals for every user (user -> operator address -> true/false)
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

    /// @dev Creates a new ERC-721 token
    /// @param name_ Name of the NFT
    /// @param symbol_ Symbol of the NFT
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /// @dev Returns the name of the NFT token
    /// @return string Name of the NFT token
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @dev Returns the symbol of the NFT token
    /// @return string Symbol of the NFT token
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @dev Returns the base URI of the NFT tokens
    /// @return string Base URI of the NFT tokens
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /// @dev Returns the token URI of the NFT token
    /// @param tokenId Id of the token
    /// @return string Token URI of the NFT token
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: you can't query the URI for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    /// @dev Returns the balance of a user
    /// @param owner Address of the user
    /// @return uint256 Balance of the user
    function balanceOf(address owner) external view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: you can't query the balance of the zero address"
        );
        return _balances[owner];
    }

    /// @dev Returns the owner of an NFT token
    /// @param tokenId Id of the token
    /// @return address Owner of the NFT token
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: you can't query the ownership for nonexistent token"
        );
        return owner;
    }

    /// @dev Approves an operator to manage all tokens of a user
    /// @param operator Addresss of the operator
    /// @param approved True = approved, False = not approved
    function setApprovalForAll(address operator, bool approved)
        external
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @dev Indicates if an operator is approved to manage all tokens of a owner
    /// @param owner Addresss of the owner
    /// @param operator Addresss of the operator
    /// @return bool True = approved, False = not approved
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /// @dev Approves an user to manage an specific NFT token
    /// @param to Addresss of the user to approve
    /// @param tokenId Id of the token
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: you can't approve the owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: you can't approve if you aren't owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /// @dev Returns the approved address of an NFT token
    /// @param tokenId Id of the token
    /// @return address Address of the approved user
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: you can't check approved for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /// @dev Transfers an NFT token to a new owner
    /// @param from User address of the token owner
    /// @param to User address of the new owner
    /// @param tokenId Id of the token
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: you can't transfer if you aren't the owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /// @dev Transfers safely an NFT token to a new owner
    /// @param from User address of the token owner
    /// @param to User address of the new owner
    /// @param tokenId Id of the token
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @dev Transfers safely an NFT token to a new owner
    /// @param from User address of the token owner
    /// @param to User address of the new owner
    /// @param tokenId Id of the token
    /// @param _data Additional data to pass along
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: you can't transfer if you aren't the owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /* === INTERNAL FUNCTIONS === */

    /// @dev Checks if an NFT token exists
    /// @param tokenId Id of the token
    /// @return bool True = exists, False = doesn't exist
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /// @dev Internal function to set a new base URI for the NFT tokens
    /// @param baseURI_ New base URI of the NFT tokens
    function _setBaseURI(string memory baseURI_) internal {
        _baseURI = baseURI_;
    }

    /// @dev Internal function to set a new token URI for the NFT token
    /// @param tokenId Id of the token
    /// @param _tokenURI New token URI of the NFT token
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(
            _exists(tokenId),
            "ERC721Metadata: you can't set the URI for nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /// @dev Internal function to approve an operator to manage all tokens of a user
    /// @param owner Addresss of the owner
    /// @param operator Addresss of the operator
    /// @param approved True = approved, False = not approved
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: you can't approve the owner");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /// @dev Internal function to approve an user to manage an specific NFT token
    /// @param to Addresss of the user to approve
    /// @param tokenId Id of the token
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /// @dev Checks if an user is the owner of an NFT token or if he is approved to manage all tokens of a user
    /// @param user Addresss of the user to check
    /// @param tokenId Id of the token
    /// @return bool True = is owner or is approved, False = isn't owner and isn't approved
    function _isApprovedOrOwner(address user, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: you can't query a nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (user == owner ||
            isApprovedForAll(owner, user) ||
            getApproved(tokenId) == user);
    }

    /// @dev Internal function to transfer an NFT token to a new owner
    /// @param from User address of the token owner
    /// @param to User address of the new owner
    /// @param tokenId Id of the token
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: you can't transfer from incorrect owner"
        );
        require(
            to != address(0),
            "ERC721: you can't transfer to the zero address"
        );

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /// @dev Internal function to transfer safely an NFT token to a new owner
    /// @param from User address of the token owner
    /// @param to User address of the new owner
    /// @param tokenId Id of the token
    /// @param _data Additional data to pass along
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: you can't transfer to non ERC721Receiver implementer"
        );
    }

    /// @dev Internal function to mint a new NFT token to the receiver
    /// @param receiver Address of the user
    /// @param tokenId Id of the token
    function _mint(address receiver, uint256 tokenId) internal {
        require(
            receiver != address(0),
            "ERC721: you can't mint to the zero address"
        );
        require(!_exists(tokenId), "ERC721: token already minted");

        _owners[tokenId] = receiver;
        _balances[receiver] = _balances[receiver].add(1);

        emit Transfer(address(0), receiver, tokenId);
    }

    /// @dev Internal function to mint safely a new NFT token to the receiver
    /// @param receiver Address of the user
    /// @param tokenId Id of the token
    function _safeMint(address receiver, uint256 tokenId) internal {
        _safeMint(receiver, tokenId, "");
    }

    /// @dev Internal function to mint safely a new NFT token to the receiver
    /// @param receiver Address of the user
    /// @param tokenId Id of the token
    /// @param _data Additional data to pass along
    function _safeMint(
        address receiver,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(receiver, tokenId);
        require(
            _checkOnERC721Received(address(0), receiver, tokenId, _data),
            "ERC721: you can't transfer to non ERC721Receiver implementer"
        );
    }

    /// @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
    /// @param _from Address representing the previous owner of the given token ID
    /// @param _receiver Target address that will receive the tokens
    /// @param _tokenId Id of the token
    /// @param _data Additional data to pass along
    /// @return bool Whether the call correctly returned the expected magic value
    function _checkOnERC721Received(
        address _from,
        address _receiver,
        uint256 _tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_receiver.isContract()) {
            bytes4 retval = IERC721TokenReceiver(_receiver).onERC721Received(
                _msgSender(),
                _from,
                _tokenId,
                _data
            );
            return retval == _ERC721_RECEIVED;
        } else {
            return true;
        }
    }
}
