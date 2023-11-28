// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../package/ERC/ERC5169.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ExampleERC5169 is Ownable, ERC5169 {
    constructor() Ownable(msg.sender){}
    
    function _authorizeSetScripts(string[] memory newScriptURI) internal override onlyOwner {}
}
