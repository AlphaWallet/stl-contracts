// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../package/royalty/RoyaltySpliterERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RoyaltySpliterFull is Ownable, RoyaltySpliterERC20 {
    constructor() Ownable(msg.sender){}

    function _authorizeUpdateRecievers(Receiver[] memory newReceivers) internal override onlyOwner {}
}
