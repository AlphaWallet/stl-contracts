// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract ParentContracts {
	using Address for address;

	// save as array to be able to foreach parents
	address[] private _allowedParentsArray;

	mapping(address => uint) private _allowedParents;

	event ParentAdded(address indexed newERC721);

	function _authorizeAddParent(address newContract) internal virtual;

	// array of ERC721 contracts to be parents to mint derived NFT
	function getParents() public view virtual returns (address[] memory) {
		return _allowedParentsArray;
	}

	function addParent(address newContract) public {
		_authorizeAddParent(newContract);

		require(newContract.isContract(), "Must be contract");

		IERC721 c = IERC721(newContract);

		try c.supportsInterface(type(IERC721).interfaceId) returns (bool result) {
			if (!result) {
				revert("Must be ERC721 contract");
			}
		} catch {
			// emit Log("external call failed");
			revert("Must be ERC721 contract");
		}

		// require(c.supportsInterface(type(IERC721).interfaceId), "Must be ERC721 contract");

		require(_allowedParents[newContract] == 0, "Already added");
		_allowedParentsArray.push(newContract);
		_allowedParents[newContract] = _allowedParentsArray.length;
		emit ParentAdded(newContract);
	}

	function _isAllowedParent(address _contract) internal view returns (bool) {
		return _allowedParents[_contract] > 0;
	}
}
