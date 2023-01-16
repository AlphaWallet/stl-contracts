/* Attestation decode and validation */
/* AlphaWallet 2021 - 2022 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC5169.sol";

abstract contract ERC5169Upgradable is ERC5169 {
    // reserve 50 slots for ERC5169.
    //slither-disable-next-line naming-convention
    uint256[49] private __gap;
}
