// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract ParentContracts {

    // save as array to be able to foreach parents
    address[] private _allowedParentsArray;

    mapping(address => uint) private _allowedParents;
    mapping(address => address) private _parentContractBeneficiaries;

    event ParentAdded(address indexed newERC721);

    //slither-disable-next-line unimplemented-functions
    function _authorizeAddParent(address newContract) internal virtual;

    // array of ERC721 contracts to be parents to mint derived NFT
    function getParents() public view virtual returns (address[] memory) {
        return _allowedParentsArray;
    }

    function addParentAndBeneficiary(
        address newContract,
        address royaltyBeneficiary
    ) public {
        addParent(newContract);
        _parentContractBeneficiaries[newContract] = royaltyBeneficiary;
    }

    // slither-disable-next-line dead-code
    function _getRoyaltyBeneficiary(
        address _parentContract
    ) internal view returns (address beneficiary) {
        beneficiary = _parentContractBeneficiaries[_parentContract];

        require(beneficiary != address(0), "Beneficiary undefined");
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function addParent(address newContract) public {
        _authorizeAddParent(newContract);

        require(_isContract(newContract), "Must be contract");

        IERC721 c = IERC721(newContract);

        // slither-disable-start uninitialized-local
        // slither-disable-next-line unused-return
        try c.supportsInterface(type(IERC721).interfaceId) returns (
            bool result
        ) {
            
            // slither-disable-next-line variable-scope
            if (!result) {
                revert("Must be ERC721 contract");
            }
            
        } catch {
            // emit Log("external call failed");
            revert("Must be ERC721 contract");
        }
        // slither-disable-end uninitialized-local

        require(_allowedParents[newContract] == 0, "Already added");
        _allowedParentsArray.push(newContract);
        _allowedParents[newContract] = _allowedParentsArray.length;
        emit ParentAdded(newContract);
    }

    // slither-disable-next-line dead-code
    function _isAllowedParent(address _contract) internal view returns (bool) {
        return _allowedParents[_contract] > 0;
    }
}
