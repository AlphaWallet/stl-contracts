// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UriChangerBase.sol";

abstract contract UriChangerUpgradeable is UriChangerBase {
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _uriChangerInit(address _newUriChanger) internal {
        _uriChangerOnlyInitializing();
        _updateUriChanger(_newUriChanger);
    }

    // override this function to limit to onlyInitializing
    function _uriChangerOnlyInitializing() internal virtual;
}
