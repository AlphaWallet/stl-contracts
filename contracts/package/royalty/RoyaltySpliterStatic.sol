// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract RoyaltySpliterStatic {
    struct Receiver {
        address wallet;
        uint16 revenue;
    }

    Receiver[] private _receivers;

    event RoyaltyPaid(address receiver, uint256 sum);

    constructor() {
        // _validateAndSaveReceivers( initialReceivers );
    }

    function _getReceivers() internal view returns (Receiver[] memory) {
        return _receivers;
    }

    function updateRecievers(Receiver[] memory newReceivers) external {
        _authorizeUpdateRecievers(newReceivers);
        _validateAndSaveReceivers(newReceivers);
    }

    function _validateAndSaveReceivers(Receiver[] memory newReceivers) internal {
        uint sum = 0;
        uint i;

        // clean current data
        uint curLen = _receivers.length;
        if (curLen > 0) {
            for (i = 0; i < curLen; i++) {
                _receivers.pop();
            }
        }

        uint len = newReceivers.length;
        for (i = 0; i < len; i++) {
            sum += newReceivers[i].revenue;
            _receivers.push(newReceivers[i]);
        }
        require(sum == 10000, "Total revenue must be 10000");
    }

    function withdrawETH() external {
        uint balance = address(this).balance;
        require(balance > 0, "Empty balance");

        Receiver[] memory receivers_ = _getReceivers();

        require(receivers_.length > 0, "No receivers");
        unchecked {
            uint sum;
            uint len = receivers_.length;
            // slither-disable-start reentrancy-events
            for (uint i = 0; i < len; i++) {
                sum = (balance * receivers_[i].revenue) / 10000;
                emit RoyaltyPaid(receivers_[i].wallet, sum);
                _pay(receivers_[i].wallet, sum);
            }
            // slither-disable-end reentrancy-events
        }
    }

    /* solhint-disable func-param-name-mixedcase */
    /* solhint-disable var-name-mixedcase */
    function _pay(address ETHreceiver, uint256 amount) internal {
        // slither-disable-start low-level-calls
        // slither-disable-next-line calls-loop, unused-state
        (bool sent, ) = ETHreceiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
        // slither-disable-end low-level-calls
    }

    receive() external payable {}

    function _authorizeUpdateRecievers(Receiver[] memory newReceivers) internal virtual;
}
