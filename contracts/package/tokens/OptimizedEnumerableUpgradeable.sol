// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./OptimizedEnumerableBase.sol";

contract OptimizedEnumerableUpgradeable is OptimizedEnumerableBase, ERC721Upgradeable {
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override(OptimizedEnumerableBase, ERC721Upgradeable) returns(address) {
        OptimizedEnumerableBase._update(to, tokenId, auth);
        return ERC721Upgradeable._update(to, tokenId, auth);
    }

    function balanceOf(
        address owner
    ) public view virtual override(OptimizedEnumerableBase, ERC721Upgradeable) returns (uint256 balance) {
        return ERC721Upgradeable.balanceOf(owner);
    }

    function ownerOf(
        uint256 tokenId
    ) public view virtual override(OptimizedEnumerableBase, ERC721Upgradeable) returns (address owner) {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Upgradeable, OptimizedEnumerableBase) returns (bool) {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) || OptimizedEnumerableBase.supportsInterface(interfaceId);
    }

    //slither-disable-next-line dead-code
    function _mint(address to) internal {
        uint newTokenId = _prepareTokenId();
        ERC721Upgradeable._mint(to, newTokenId);
    }
}
