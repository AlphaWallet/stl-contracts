// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '../ERC/ERC5169.sol';
import '../royalty/DerivedERC2981Royalty.sol';
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import "hardhat/console.sol";

contract ERC721STD is
	ERC721Burnable,
	ERC5169,
	DerivedERC2981Royalty,
    AccessControlEnumerable,
    ERC721URIStorage,
    ERC721Enumerable
{
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public contractURI;
    string public baseURI;
    address public royaltyReceiver;
    uint public royaltyPercentage;
    uint public nextTokenId;

    event contractUriChanged(string newURI);
    event RoyaltyDataChanged(address addr, uint percentage);

    error TooHighRoyaltyPercentage();
    error OneAdminRequired();

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setRoyaltyData(msg.sender, 5 * 100);
    }

    function _authorizeSetScripts(string[] memory) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // function isMinter(address _account) public view returns (bool) {
    //     return hasRole(MINTER_ROLE, _account);
    // }

    function owner() public view returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721, ERC721URIStorage, ERC721Enumerable, ERC5169, AccessControlEnumerable, DerivedERC2981Royalty) returns (bool) {
        return ERC5169.supportsInterface(interfaceId)
        || DerivedERC2981Royalty.supportsInterface(interfaceId)
        || ERC721Enumerable.supportsInterface(interfaceId)
        || ERC721URIStorage.supportsInterface(interfaceId)
        || ERC721.supportsInterface(interfaceId)
        || AccessControlEnumerable.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return ERC721Enumerable._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._increaseBalance(account, value);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override returns (bool) {
        if (role == DEFAULT_ADMIN_ROLE && getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 1) {
            revert OneAdminRequired();
        }
        return AccessControlEnumerable._revokeRole(role, account);
    }

    function setContractURI(string calldata newURI) external onlyRole(DEFAULT_ADMIN_ROLE){
        contractURI = newURI;
        emit contractUriChanged(newURI);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override
		returns (address receiver, uint256 royaltyAmount)
	{
		_requireOwned(tokenId);
		receiver = royaltyReceiver;
		royaltyAmount = royaltyPercentage * salePrice / 10000;
	}

   
    function setRoyaltyData(address addr, uint percentage) external onlyRole(DEFAULT_ADMIN_ROLE){
        _setRoyaltyData(addr, percentage);
    }

    function _setRoyaltyData(address addr, uint percentage) internal {
        if (percentage >= 10_000){
            revert TooHighRoyaltyPercentage();
        }
        royaltyReceiver = addr;
        royaltyPercentage = percentage;
        emit RoyaltyDataChanged(addr, percentage);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE){
        baseURI = newBaseUri;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyRole(MINTER_ROLE){
        _setTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    /** 
    @param uri - can be empty string, minter can set the value later
    tokenId auto-increase
    */
    function mint(address to, string memory uri) external onlyRole(MINTER_ROLE){
        _mint(to, nextTokenId);
        if (bytes(uri).length > 0){
            _setTokenURI(nextTokenId, uri);
        }
        nextTokenId++;
    }

    // function contractURI() external pure returns (string memory){
    //     return "https://resources.smarttokenlabs.com/contract/SLN.json";
    // }
}