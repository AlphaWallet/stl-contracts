// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

abstract contract Minter {
    mapping(uint => address) private _minter;

    function _update(address to, uint256 tokenId, address) internal virtual returns (address) {
        if (to == address(0)) {
            delete _minter[tokenId];
        }

        address from = _ownerOf(tokenId);
        if (from == address(0)) {
            _minter[tokenId] = to;
        }
        return address(0);
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {}

    function getMinter(uint tokenId) public view returns (address) {
        address minter_ = _minter[tokenId];
        require(minter_ != address(0), "Not minted");
        return minter_;
    }
}
