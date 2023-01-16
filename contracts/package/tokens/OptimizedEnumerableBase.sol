// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// disable "is IERC721Enumerable" to avoid multiple methods override for OptimizedEnumerableUpgradeable
abstract contract OptimizedEnumerableBase  {
	using Counters for Counters.Counter;

	Counters.Counter private _tokenIdCounter;

	// count burnt token number to calc totalSupply()
	uint256 private _burnt;

	//slither-disable-next-line dead-code
	function _beforeTokenTransfer(
		address,
		address to,
		uint256,
		uint256
	) internal virtual {
		if (to == address(0)) {
			_burnt++;
		}
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view virtual returns (bool) {
		return
			interfaceId == type(IERC721Enumerable).interfaceId ||
			interfaceId == type(IERC165).interfaceId;
	}

	function balanceOf(
		address owner
	) public view virtual returns (uint256 balance);

	function ownerOf(uint256 tokenId) public view virtual returns (address owner);

	function _exists(uint256 tokenId) internal view virtual returns (bool);

	/**
	 * Foreach all minted tokens until reached appropriate index
	 */
	function tokenOfOwnerByIndex(
		address owner,
		uint256 index
	) public view virtual returns (uint256) {
		require(index < balanceOf(owner), "Owner index out of bounds");

		uint256 numMinted = _tokenIdCounter.current();
		uint256 tokenIdsIdx = 0;

		// Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
		unchecked {
			for (uint256 i = 0; i < numMinted; i++) {
				if (_exists(i) && (ownerOf(i) == owner)) {
					if (tokenIdsIdx == index) {
						return i;
					}
					tokenIdsIdx = tokenIdsIdx + 1;
				}
			}
		}

		// Execution should never reach this point.
		assert(false);
		// added to stop compiler warnings
		return 0;
	}

	function totalSupply() public view virtual returns (uint256) {
		return _tokenIdCounter.current() - _burnt;
	}

	/**
	 * @dev See {IERC721Enumerable-tokenByIndex}.
	 */
	function tokenByIndex(
		uint256 index
	) public view virtual returns (uint256) {
		uint256 numMintedSoFar = _tokenIdCounter.current();

		require(index < totalSupply(), "Index out of bounds");

		uint256 tokenIdsIdx = 0;

		// Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
		unchecked {
			for (uint256 i = 0; i < numMintedSoFar; i++) {
				if (_exists(i)) {
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

	function _prepareTokenId() internal returns (uint) {
		uint newTokenId = _tokenIdCounter.current();
		_tokenIdCounter.increment();
		return newTokenId;
	}
}
