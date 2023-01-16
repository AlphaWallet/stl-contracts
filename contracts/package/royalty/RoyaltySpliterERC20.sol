// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./RoyaltySpliterStatic.sol";

abstract contract RoyaltySpliterERC20 is RoyaltySpliterStatic {
    using SafeERC20 for IERC20;

    event RoyaltyPaidERC20(
        address indexed erc20,
        address receiver,
        uint256 sum
    );

    function withdrawERC20(address[] calldata contracts) external {
        Receiver[] memory receivers = _getReceivers();

        require(receivers.length > 0, "No receivers");
        for (uint i = 0; i < contracts.length; i++) {
            _payERC20(contracts[i], receivers);
        }
    }

    function _payERC20(address erc20, Receiver[] memory receivers) internal {
        IERC20 erc20c = IERC20(erc20);

        // get this contract balance to withdraw
        uint balance = erc20c.balanceOf(address(this));
        // throw error if it requests more that in the contract balance
        require(balance > 0, "Balance is Empty");

        unchecked {
            uint sum;
            uint len = receivers.length;
            for (uint i = 0; i < len; i++) {
                sum = (balance * receivers[i].revenue) / 10000;
                emit RoyaltyPaidERC20(erc20, receivers[i].wallet, sum);
                erc20c.safeTransfer(receivers[i].wallet, sum);
            }
        }
    }
}
