// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../package/tokens/extensions/Minter.sol";
import "../package/tokens/extensions/ParentContracts.sol";
import "../package/tokens/extensions/SharedHolders.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../package/tokens/OptimizedEnumerable.sol";
import "../package/royalty/ERC2981RoyaltyFull.sol";

contract ExampleERC721 is Ownable, ERC2981RoyaltyFull, Minter, SharedHolders, ParentContracts, OptimizedEnumerable {
    constructor(string memory name, string memory symbol) OptimizedEnumerable(name, symbol) {}

    function _authorizeAddParent(address newContract) internal override onlyOwner {}

    function _authorizeSetRoyalty() internal override onlyOwner {}

    function _authorizeSetSharedHolder(address[] calldata newAddresses) internal override onlyOwner {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) internal override(Minter, OptimizedEnumerable) {
        Minter._beforeTokenTransfer(from, to, tokenId, 1);
        OptimizedEnumerable._beforeTokenTransfer(from, to, tokenId, 1);
    }

    function _exists(
        uint256 tokenId
    ) internal view override(ERC2981RoyaltyFull, OptimizedEnumerable) returns (bool) {
        return OptimizedEnumerable._exists(tokenId);
    }

    function mint(address to) public virtual {
        OptimizedEnumerable._mint(to);
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function isSharedHolderTokenOwner(address _contract, uint256 tokenId) public view returns (bool) {
        return _isSharedHolderTokenOwner(_contract, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(OptimizedEnumerable, DerivedERC2981Royalty) returns (bool) {
        return
            OptimizedEnumerable.supportsInterface(interfaceId) || DerivedERC2981Royalty.supportsInterface(interfaceId);
    }
}
