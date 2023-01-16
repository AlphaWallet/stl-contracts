// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../package/access/UriChanger.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ExampleUriChanger is Ownable, UriChanger {
    uint public val = 1;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() UriChanger(msg.sender) {}

    function _authorizeUpdateUriChanger(
        address newAddress
    ) internal override onlyOwner {}

    function setValue(uint _val) public onlyUriChanger {
        val = _val;
    }

    function getValue() public view returns (uint) {
        return val;
    }
}
