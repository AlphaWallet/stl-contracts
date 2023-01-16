// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract UriChangerBase {
    address private _uriChanger;

    event UriChangerUpdated(address indexed previousAddress, address indexed newAddress);

    /**
     * @dev Returns the address of the current owner.
     */
    function _getUriChanger() internal view returns (address) {
        return _uriChanger;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyUriChanger() {
        require(_getUriChanger() == msg.sender, "UriChanger: caller is not allowed");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function updateUriChanger(address newAddress) public virtual {
        _authorizeUpdateUriChanger(newAddress);
        require(newAddress != address(0), "UriChanger: Address required");
        _updateUriChanger(newAddress);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _updateUriChanger(address newAddress) internal virtual {
        address oldAddress = _uriChanger;
        _uriChanger = newAddress;
        emit UriChangerUpdated(oldAddress, newAddress);
    }

    function _authorizeUpdateUriChanger(address newAddress) internal virtual;
}
