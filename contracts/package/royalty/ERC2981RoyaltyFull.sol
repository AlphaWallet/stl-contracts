// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./DerivedERC2981Royalty.sol";

// Max royalty value is 10000 (100%)
abstract contract ERC2981RoyaltyFull is DerivedERC2981Royalty {
    event RoyaltyContractUpdated( address indexed newAddress );

    address payable private _royaltyReceiver;

    constructor (){
        _royaltyReceiver = payable(msg.sender);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external virtual override view
    returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Token doesnt exist.");
        require(_royaltyReceiver != address(0), "Receiver didnt set");
        receiver = _royaltyReceiver;
        royaltyAmount = (_getRoyalty() * salePrice) / 10000;
    }

    function setRoyaltyPercentage(uint value) external {
        _authorizeSetRoyalty();
        require(value < 100*100 , "Percentage more than 100%");
        _setRoyalty(value);
    }

    function setRoyaltyContract(address payable newAddress) external {
        require(newAddress != address(0), "Address required");
        _authorizeSetRoyalty();
        _setRoyaltyContract( newAddress );
    }

    function _setRoyaltyContract(address payable newAddress) internal {
        require(newAddress != address(0), "Address required");
        emit RoyaltyContractUpdated(newAddress);
        _royaltyReceiver = newAddress;
    }

    function _authorizeSetRoyalty() internal virtual;

    function _exists(uint256 tokenId) internal view virtual returns (bool);
}
