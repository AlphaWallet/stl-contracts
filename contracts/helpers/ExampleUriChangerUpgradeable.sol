// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../package/access/UriChangerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ExampleUriChangerUpgradeable is OwnableUpgradeable, UriChangerUpgradeable, UUPSUpgradeable {
    uint public val;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __UriChangerInit(msg.sender);
        val = 1;
    }

    function _uriChangerOnlyInitializing() internal override onlyInitializing {}

    function _authorizeUpdateUriChanger(address newAddress) internal override onlyOwner {}

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setValue(uint _val) public onlyUriChanger {
        val = _val;
    }

    function getValue() public view returns (uint) {
        return val;
    }
}
