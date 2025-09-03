// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @custom:security-contact yahayasalisu162@gmail.com

contract NairaNFT is
    ERC721,
    ERC721Pausable,
    ERC721Burnable,
    ERC2981,
    Ownable,
    ReentrancyGuard
{
    // ====== Supply / Minting state ======
    uint256 private _nextTokenId;          // current supply counter
    uint256 public immutable maxSupply;    // hard cap
    uint256 public mintPrice;              // price per NFT (in wei)
    uint256 public maxPerWallet;           // anti-whale per wallet cap
    mapping(address => uint256) public mintedBy; // mints per wallet

    // ====== Metadata ======
    string private _baseTokenURI;

    // ====== Constructor ======
    constructor(
        address initialOwner,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 maxSupply_,
        uint256 mintPriceWei_,
        uint256 maxPerWallet_,
        address royaltyReceiver,           // can be same as owner
        uint96 royaltyFeeBps               // e.g. 500 = 5%
    ) ERC721(name_, symbol_) Ownable(initialOwner) {
        require(maxSupply_ > 0, "maxSupply=0");
        _baseTokenURI = baseURI_;
        maxSupply = maxSupply_;
        mintPrice = mintPriceWei_;
        maxPerWallet = maxPerWallet_;
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeBps);
    }

    // ====== Admin controls ======
    function setBaseURI(string calldata newBase) external onlyOwner {
        _baseTokenURI = newBase;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxPerWallet(uint256 newMax) external onlyOwner {
        maxPerWallet = newMax;
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    /// Owner/airdrop mint
    function ownerMint(address to, uint256 quantity) external onlyOwner {
        _mintMany(to, quantity);
    }

    // ====== Public minting ======
    function publicMint(uint256 quantity)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(quantity > 0, "qty=0");
        require(msg.value == mintPrice * quantity, "wrong ETH sent");
        require(mintedBy[msg.sender] + quantity <= maxPerWallet, "wallet cap");
        mintedBy[msg.sender] += quantity;
        _mintMany(msg.sender, quantity);
    }

    // Internal batch minter
    function _mintMany(address to, uint256 quantity) internal {
        require(_nextTokenId + quantity <= maxSupply, "sold out");
        unchecked {
            for (uint256 i = 0; i < quantity; ++i) {
                _safeMint(to, _nextTokenId++);
            }
        }
    }

    // ====== Withdraw funds ======
    function withdraw(address payable to) external onlyOwner {
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "withdraw failed");
    }

    // ====== Metadata (baseURI pattern) ======
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // ====== Solidity-required overrides ======
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 iid)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(iid);
    }

    // Convenience views
    function totalMinted() external view returns (uint256) {
        return _nextTokenId;
    }
}