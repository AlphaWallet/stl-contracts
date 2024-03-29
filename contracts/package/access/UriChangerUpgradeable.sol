// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./UriChangerBase.sol";

abstract contract UriChangerUpgradeable is UriChangerBase {
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    //solhint-disable func-name-mixedcase */
    //slither-disable-next-line naming-convention
    function __UriChangerInit(address _newUriChanger) internal {
        _uriChangerOnlyInitializing();
        _updateUriChanger(_newUriChanger);
    }

    // override this function to limit to onlyInitializing
    function _uriChangerOnlyInitializing() internal virtual;
}
