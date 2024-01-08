// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract ERC721OptimizedEnumerableUpgradeable is IERC721Enumerable, ERC721Upgradeable {

    error IndexOutOfBounds();
    error ZeroAddressCantBeOwner();

    struct ERC721EnumStorage {
        uint _tokenIdCounter;
        // count burnt token number to calc totalSupply()
        uint256 _burnt;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC721Enumerable).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    // keccak256(abi.encode(uint256(keccak256("stl.storage.ERC721OptimizedEnumerable")) - 1))
    bytes32 private constant ERC721OptimizedEnumerableLocation = 0x0c12c17af20e858ae142203eca79d9fe977cde9a6d2226d7db28f4c9277f8085;

    function _getERC721EnumStorage() private pure returns (ERC721EnumStorage storage $) {
        assembly {
            $.slot := ERC721OptimizedEnumerableLocation
        }
    }

    function _update(address to, uint256 tokenId, address from) internal virtual override returns (address) {
        if (to == address(0)) {
            ERC721EnumStorage storage $ = _getERC721EnumStorage();
            $._burnt++;
        }
        return ERC721Upgradeable._update(to, tokenId, from);
    }

    function getNextTokenId() internal view returns (uint){
        ERC721EnumStorage storage $ = _getERC721EnumStorage();
        return $._tokenIdCounter;
    }

    function _prepareTokenId() internal returns (uint) {
        ERC721EnumStorage storage $ = _getERC721EnumStorage();
        uint newTokenId = $._tokenIdCounter++;
        return newTokenId;
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
        ERC721EnumStorage storage $ = _getERC721EnumStorage();
        return $._tokenIdCounter - $._burnt;
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
        return 0;
    }

    function _mint(address to) internal {
        uint newTokenId = _prepareTokenId();
        ERC721Upgradeable._mint(to, newTokenId);
    }
}
