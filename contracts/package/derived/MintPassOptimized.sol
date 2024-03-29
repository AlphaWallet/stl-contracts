// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@openzeppelin/contracts/utils/Address.sol";

import "../royalty/DerivedERC2981Royalty.sol";

contract MintPassOptimized is ERC721, Ownable, DerivedERC2981Royalty, IERC721Enumerable {
    using Math for uint256;
    using Address for address;

    /* solhint-disable var-name-mixedcase */
    // slither-disable-start naming-convention
    address immutable _BAYC;
    address immutable _MAYC;
    address immutable _DAPE;
    address _royaltyReceiver;
    // slither-disable-end naming-convention

    string constant _CONTRACT_URI = "https://niftytailor.com/contracts/mintpass.json";
    string constant _TOKEN_URI = "https://niftytailor.com/token/mintpass.json";

    uint256 constant _ALLOWED_NUMBER_OF_MINTPASSES = 10;
    uint256 constant _MINT_PRICE = (1 ether * 69) / 1000;
    uint256 constant _MAX_PER_ADDRESS = 50;
    uint256 constant _MAX_ALLOWED = 2500;

    uint private _tokenIdCounter;
    /* solhint-disable var-name-mixedcase */
    //slither-disable-next-line naming-convention
    uint256 immutable _MINT_START_TIME;

    // count burnt token number to calc totalSupply()
    uint256 private _burnt;

    event MintpassesMinted(address indexed requestor, uint indexed number);
    event RoyaltyContractUpdate(address indexed newAddress);

    //slither-disable-next-line naming-convention
    mapping(address => uint256) internal _mintedPerAddress;

    constructor(
        string memory name_,
        string memory symbol_,
        address bayc_,
        address mayc_,
        address dape_,
        address rr_,
        uint256 mintStartTime_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        require(bayc_ != address(0) && mayc_ != address(0) && dape_ != address(0), "Contract required");
        _BAYC = bayc_;
        _MAYC = mayc_;
        _DAPE = dape_;
        _setRoyaltyContract(rr_);

        _tokenIdCounter++;

        // TODO update royalty value
        _setRoyalty(200); // 100 = 1%

        _MINT_START_TIME = mintStartTime_;
    }

    function isContract(address _address) public view returns (bool) {
        // address(..).code.size
        // return account.code.length > 0;
        uint32 size;
        assembly { 
            size := extcodesize(_address) 
        }
        return size > 0;
    }

    function _exists(uint tokenId) internal view returns(bool){
        return ownerOf(tokenId) != address(0);
    }

    // required to solve inheritance
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721, DerivedERC2981Royalty) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || DerivedERC2981Royalty.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view virtual override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Token doesnt exist.");
        // receiver = _getTokenOwner(tokenId);
        receiver = _royaltyReceiver;
        royaltyAmount = (_getRoyalty() * salePrice) / 10000;
    }

    function setRoyaltyContract(address newAddress) external onlyOwner {
        _setRoyaltyContract(newAddress);
    }

    function _setRoyaltyContract(address newAddress) internal {
        require(isContract(newAddress), "Only Contract allowed");
        emit RoyaltyContractUpdate(newAddress);
        _royaltyReceiver = newAddress;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        //slither-disable-next-line low-level-calls
        (bool sent, ) = _msgSender().call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function _getBalance(address _contract) internal view returns (uint256) {
        ERC721 t = ERC721(_contract);
        return t.balanceOf(_msgSender());
    }

    function mintedTotal() public view returns (uint256) {
        return _tokenIdCounter - 1;
    }

    function mintedForAddress(address addr) public view returns (uint256) {
        return _mintedPerAddress[addr];
    }

    // we can use it in derived contract
    //slither-disable-next-line dead-code
    function _setMintedForAddress(address addr, uint value) internal {
        _mintedPerAddress[addr] = value;
    }

    function getMintStartTime() public view virtual returns (uint256) {
        return _MINT_START_TIME;
    }

    function mintMintPass(uint256 mintpassNumber) external payable {
        require(block.timestamp >= getMintStartTime(), "Minting not started");
        _mintFor(mintpassNumber);
    }

    function _mintFor(uint256 mintpassNumber) internal virtual {
        // uint256 currentBalance = ERC721Upgradeable.balanceOf(_msgSender());
        uint256 minted = _mintedPerAddress[_msgSender()];
        (bool ok, uint res) = _getMintPrice().tryMul(mintpassNumber);
        require(ok, "Operation result overflows UINT256");
        require(res == msg.value, "Ether value sent is not correct");

        require(_MAX_PER_ADDRESS >= (minted + mintpassNumber), "Too much MintPasses requested");
        require(_getMaxAllowed() >= (_tokenIdCounter - 1 + mintpassNumber), "Limit reached");
        // require( _isTokenOwner(erc721, tokenId), "Sender not an owner");

        uint256 originsNumber = _getBalance(_BAYC) + _getBalance(_MAYC);

        require(originsNumber * _ALLOWED_NUMBER_OF_MINTPASSES > minted, "Not enough origins.");
        require(originsNumber * _ALLOWED_NUMBER_OF_MINTPASSES - minted >= mintpassNumber, "Not enough origins");

        _mintedPerAddress[_msgSender()] = minted + mintpassNumber;

        for (uint i = 0; i < mintpassNumber; i++) {
            _mintWrap(_msgSender());
        }

        emit MintpassesMinted(_msgSender(), mintpassNumber);
    }

    function useToken(uint256 tokenId, address sender) external returns (bool) {
        require(_msgSender() == _DAPE, "Only Derived APE allowed");
        require(_exists(tokenId), "Non-existent token");
        require(ownerOf(tokenId) == sender, "Requested by Non-owner");
        _burnt++;
        _burn(tokenId);
        return true;
    }

    // function set_DAPE( address __dape) external onlyOwner {
    //     require (__dape != address(0), "Zero not allowed");
    //     _DAPE = __dape;
    // }

    function contractURI() public pure virtual returns (string memory) {
        return _CONTRACT_URI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _TOKEN_URI;
    }

    function _mintWrap(address to) internal returns (uint256 currentId) {
        currentId = _tokenIdCounter;
        _tokenIdCounter++;
        _mint(to, currentId);
    }

    /**
     * Foreach all minted tokens until reached appropriate index
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < balanceOf(owner), "MP: owner index out of bounds");

        uint256 numMintedSoFar = _tokenIdCounter;
        uint256 tokenIdsIdx = 0;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i = 1; i < numMintedSoFar; i++) {
                if (ownerOf(i) == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        assert(false);
        // added to stop compiler warnings
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIdCounter - _burnt - 1;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        uint256 numMintedSoFar = _tokenIdCounter;

        require(index < totalSupply(), "MP: index out of bounds");
        uint256 tokenIdsIdx = 0;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i = 1; i < numMintedSoFar; i++) {
                if (_exists(i)) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        assert(false);
        return 0;
    }

    function _getMintPrice() internal view virtual returns (uint) {
        return _MINT_PRICE;
    }

    function _getMaxAllowed() internal view virtual returns (uint) {
        return _MAX_ALLOWED;
    }
}
