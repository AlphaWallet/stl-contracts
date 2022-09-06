// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";

contract RoyaltySpliterStatic is Ownable {

    using SafeERC20 for IERC20;
   
    struct receiver {
        address wallet;
        uint16 revenue;
    }

    receiver[] receivers;
    
    event RoyaltyPaid(address receiver, uint256 sum);
    event RoyaltyPaidERC20(address indexed erc20, address receiver, uint256 sum);

    constructor() {
        // validateAndSaveReceivers( initialReceivers );
    }

    function updateRecievers(receiver[] memory newReceivers) external onlyOwner {
        validateAndSaveReceivers( newReceivers );
    }

    function validateAndSaveReceivers(receiver[] memory newReceivers) internal {
        uint sum = 0;
        uint i;

        // clean current data
        uint curLen = receivers.length;
        if (curLen > 0) {
            for ( i = 0; i < curLen; i++){
                receivers.pop();
            }
        }

        uint len = newReceivers.length;
        for ( i = 0; i < len; i++){
            sum += newReceivers[i].revenue;
            receivers.push(newReceivers[i]);
        }
        require (sum == 10000, "Total revenue must be 10000");
    }

    function withdrawETH() external {
        uint balance = address(this).balance;
        require(balance > 0, "Empty balance");
        unchecked {
            uint sum;
            uint len = receivers.length;
            for (uint i = 0; i < len; i++){
                sum = balance * receivers[i].revenue / 10000;
                emit RoyaltyPaid(receivers[i].wallet, sum);
                _pay( receivers[i].wallet, sum);
            }

        }
    }

    function _pay(address ETHreceiver, uint256 amount) internal {
        (bool sent, ) = ETHreceiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdraw(address[] calldata contracts) external {
        for (uint i = 0; i < contracts.length; i++ ){
            payERC20(contracts[i]);
        }
    }

    function payERC20(address erc20) internal {
        
        IERC20 erc20c = IERC20(erc20);

        // get this contract balance to withdraw
        uint balance = erc20c.balanceOf(address(this));
        // throw error if it requests more that in the contract balance
        require(balance > 0, "Balance is Empty");

        unchecked {
            uint sum;
            uint len = receivers.length;
            for (uint i = 0; i < len; i++){
                sum = balance * receivers[i].revenue / 10000;
                emit RoyaltyPaidERC20( erc20, receivers[i].wallet, sum);
                erc20c.safeTransfer(receivers[i].wallet, sum);
            }
        }
    }

    receive() external payable {}
}