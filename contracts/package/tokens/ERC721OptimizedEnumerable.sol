// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
// import "./OptimizedEnumerableBase.sol";

contract ERC721OptimizedEnumerable is ERC721 {

    uint private _tokenIdCounter;
    // count burnt token number to calc totalSupply()
    uint256 private _burnt;

    error IndexOutOfBounds();
    error ZeroAddressCantBeOwner();

    function _update(address to, uint256 tokenId, address from) internal virtual override returns (address) {
        if (to == address(0)) {
            _burnt++;
        }
        return ERC721._update(to, tokenId, from);
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return 
            interfaceId == type(IERC721Enumerable).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    function _mint(address to) internal {
        uint newTokenId = _prepareTokenId();
        ERC721._mint(to, newTokenId);
    }

    function getNextTokenId() internal view returns (uint){
        return _tokenIdCounter;
    }

    function _prepareTokenId() internal returns (uint) {
        return _tokenIdCounter++;
    }

    /**
     * Foreach all minted tokens until reached appropriate index
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {

        if (index >= balanceOf(owner)){
            revert IndexOutOfBounds();
        }

        if (owner == address(0)){
            revert ZeroAddressCantBeOwner();
        }

        uint256 numMinted = getNextTokenId();
        uint256 tokenIdsIdx = 0;

        unchecked {
            for (uint256 i = 0; i < numMinted; i++) {
                if (_ownerOf(i) == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        assert(false);
        // added to stop compiler warnings
        return 0;
    }

    function totalSupply() public view virtual returns (uint256) {
        return getNextTokenId() - _burnt;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        uint256 numMintedSoFar = getNextTokenId();

        if (index >= totalSupply()){
            revert IndexOutOfBounds();
        }

        uint256 tokenIdsIdx = 0;

        unchecked {
            for (uint256 i = 0; i < numMintedSoFar; i++) {
                if (_ownerOf(i) != address(0)) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        assert(false);
        // added to stop compiler warnings
        return 0;
    }
}


