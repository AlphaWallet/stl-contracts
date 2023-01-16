// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../package/tokens/extensions/Minter.sol";
import "../package/tokens/extensions/ParentContracts.sol";
import "../package/tokens/extensions/SharedHolders.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../package/tokens/OptimizedEnumerable.sol";

contract ExampleERC721 is
	Ownable,
	Minter,
	SharedHolders,
	ParentContracts,
	OptimizedEnumerable
{
	constructor(
		string memory name,
		string memory symbol
	) OptimizedEnumerable(name, symbol) {}

	function _authorizeAddParent(
		address newContract
	) internal override onlyOwner {}

	function _authorizeSetSharedHolder(
		address[] calldata newAddresses
	) internal override onlyOwner {}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256
	) internal override(Minter, OptimizedEnumerable) {
		Minter._beforeTokenTransfer(from, to, tokenId, 1);
		OptimizedEnumerable._beforeTokenTransfer(from, to, tokenId, 1);
	}

	function mint(address to) public virtual {
		OptimizedEnumerable._mint(to);
	}

	function burn(uint256 tokenId) public virtual {
		//solhint-disable-next-line max-line-length
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			"ERC721: caller is not token owner or approved"
		);
		_burn(tokenId);
	}

	function isSharedHolderTokenOwner(
		address _contract,
		uint256 tokenId
	) public view returns (bool) {
		return _isSharedHolderTokenOwner(_contract, tokenId);
	}
}
