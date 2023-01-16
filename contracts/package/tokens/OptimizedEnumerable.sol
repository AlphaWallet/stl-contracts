// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./OptimizedEnumerableBase.sol";

contract OptimizedEnumerable is OptimizedEnumerableBase, ERC721 {
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(OptimizedEnumerableBase, ERC721) {
        OptimizedEnumerableBase._beforeTokenTransfer(from, to, tokenId, batchSize);
        ERC721._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function balanceOf(
        address owner
    ) public view virtual override(OptimizedEnumerableBase, ERC721) returns (uint256 balance) {
        return ERC721.balanceOf(owner);
    }

    function ownerOf(
        uint256 tokenId
    ) public view virtual override(OptimizedEnumerableBase, ERC721) returns (address owner) {
        return ERC721.ownerOf(tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual override(OptimizedEnumerableBase, ERC721) returns (bool) {
        return ERC721._exists(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, OptimizedEnumerableBase) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || OptimizedEnumerableBase.supportsInterface(interfaceId);
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    //slither-disable-next-line dead-code
    function _mint(address to) internal {
        uint newTokenId = _prepareTokenId();
        ERC721._mint(to, newTokenId);
    }
}
