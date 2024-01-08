/* Attestation decode and validation */
/* AlphaWallet 2021 - 2022 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IERC5169 {
    /// @dev This event emits when the scriptURI is updated,
    /// so wallets implementing this interface can update a cached script
    event ScriptUpdate(string[]);

    /// @notice Get the scriptURI for the contract
    /// @return The scriptURI
    function scriptURI() external view returns (string[] memory);

    /// @notice Update the scriptURI
    /// emits event ScriptUpdate(string[])
    function setScriptURI(string[] memory) external;
}
