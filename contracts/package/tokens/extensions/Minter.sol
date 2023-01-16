// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

contract Minter {
	mapping(uint => address) private _minter;

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256
	) internal virtual {
		if (to == address(0) && from != address(0)) {
			delete _minter[tokenId];
		}

		if (from == address(0)) {
			_minter[tokenId] = to;
		}
	}

	function getMinter(uint tokenId) public view returns (address) {
		address minter_ = _minter[tokenId];
		require(minter_ != address(0), "Not minted");
		return minter_;
	}
}
