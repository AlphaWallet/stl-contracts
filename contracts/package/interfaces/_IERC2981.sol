// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./_IERC165.sol";

//solhint-disable contract-name-camelcase */
//slither-disable-next-line naming-convention
interface _IERC2981 is _IERC165 {
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}
