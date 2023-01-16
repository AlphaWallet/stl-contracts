// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../package/royalty/RoyaltySpliterERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RoyaltySpliterFull is Ownable, RoyaltySpliterERC20 {
    function _authorizeUpdateRecievers(
        Receiver[] memory newReceivers
    ) internal override onlyOwner {}
}
