// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketPlace is ReentrancyGuard {
    ////////////
    // Errors //
    ///////////
    error NFTMarketPlace__TokenNotApproved();
    error NFTMarketPlace__NotOwner();
    error NFTMarketPlace__TokenValueCantBeZero();
    error NFTMarketPlace__AlreadyListed();
    error NFTMarketPlace__IncorrectPrice();
    error NFTMarketPlace__AlreadyBought();
    error NFTMarketPlace__FeeTransferFailed();
    error NFTMarketPlace__SellerPaymentFailed();
    error NFTMarketPlace__NotListed();
    error NFTMarketPlace__NotZero();
    error NFTMarketPlace__NotFeeOwner();

    ///////////////////////
    // Type Declarations //
    //////////////////////
    struct Listing {
        uint256 price; // sale price in wei
        address seller; // current owner who listed the NFT
    }

    /////////////////////
    // State Variables //
    ////////////////////
    uint256 private fees = 25; // 2.5 percent
    address payable public immutable i_feesOwner;
    mapping(address => mapping(uint256 => Listing)) private listings;

    ////////////
    // Events //
    ///////////
    event TokenListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 indexed tokenPrice,
        address seller
    );

    event TokenBought(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address buyer
    );

    event TokenDelisted(uint256 indexed tokenId, address indexed nftAddress);

    ///////////////
    // Modifiers //
    //////////////
    modifier onlyOwner(uint256 tokenId, address nftAddress) {
        require(
            IERC721(nftAddress).ownerOf(tokenId) == msg.sender,
            NFTMarketPlace__NotOwner()
        );
        _;
    }
    /**
     * @dev Restricts function access to the current marketplace fee owner.
     * Reverts with NFTMarketPlace__NotFeeOwner if the caller is not feesOwner.
     */
    modifier onlyFeeOwner() {
        require(msg.sender == i_feesOwner, NFTMarketPlace__NotFeeOwner());
        _;
    }

    ///////////////
    // Functions //
    //////////////
    constructor(address payable _feesOwner) {
        i_feesOwner = _feesOwner;
    }

    /**
     * @notice Lists an NFT for sale on the marketplace.
     * @dev
     * - Caller must own the NFT (onlyOwner modifier).
     * - NFT must not already be listed (price == 0 check).
     * - NFT must have a non-zero price.
     * - NFT must be approved for this marketplace via getApproved or isApprovedForAll.
     * - Stores listing details in listings mapping and emits TokenListed event.
     * @param tokenId The unique identifier for the NFT within its contract.
     * @param tokenPrice The sale price for the NFT in wei.
     * @param nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__AlreadyListed Thrown if NFT is already listed.
     * @custom:error NFTMarketPlace__TokenValueCantBeZero Thrown if tokenPrice is zero.
     * @custom:error NFTMarketPlace__TokenNotApproved Thrown if NFT is not approved for the marketplace.
     */
    function list(
        uint256 tokenId,
        uint256 tokenPrice,
        address nftAddress
    ) public onlyOwner(tokenId, nftAddress) {
        // Ensure the NFT is not already listed (price == 0 means "not listed")
        require(
            listings[nftAddress][tokenId].price == 0,
            NFTMarketPlace__AlreadyListed()
        );

        // Ensure the listing price is greater than zero
        require(tokenPrice > 0, NFTMarketPlace__TokenValueCantBeZero());

        // Ensure marketplace is approved to transfer the NFT
        // Either token-specific approval (getApproved) or blanket approval (isApprovedForAll) must be set
        require(
            IERC721(nftAddress).getApproved(tokenId) == address(this) ||
                IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)),
            NFTMarketPlace__TokenNotApproved()
        );

        // Store listing details in the mapping
        // Outer key = NFT contract address, inner key = tokenId
        listings[nftAddress][tokenId] = Listing(tokenPrice, msg.sender);

        // Emit event for off-chain tracking and frontend updates
        emit TokenListed(nftAddress, tokenId, tokenPrice, msg.sender);
    }

    /**
     * @notice Purchases a listed NFT from the marketplace.
     * @dev
     * - Buyer must send exactly the listing price in msg.value.
     * - NFT must be currently listed (price > 0).
     * - Caller cannot be the seller of the NFT.
     * - Fees are calculated as a percentage of the sale price and sent to feesOwner.
     * - Remaining payment is sent to the seller.
     * - State (listings mapping) is updated before making external calls to prevent reentrancy risks.
     * - NFT is transferred to the buyer after payments are processed.
     * @param tokenId The unique identifier of the NFT within its contract.
     * @param nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__NotListed Thrown if the NFT is not listed for sale.
     * @custom:error NFTMarketPlace__IncorrectPrice Thrown if msg.value does not match listing price.
     * @custom:error NFTMarketPlace__AlreadyBought Thrown if the buyer is the seller of the NFT.
     * @custom:error NFTMarketPlace__FeeTransferFailed Thrown if sending marketplace fees fails.
     * @custom:error NFTMarketPlace__SellerPaymentFailed Thrown if sending payment to seller fails.
     */
    function buy(
        uint256 tokenId,
        address nftAddress
    ) public payable nonReentrant {
        Listing memory listing = listings[nftAddress][tokenId];

        // Check NFT is listed
        require(listing.price > 0, NFTMarketPlace__NotListed());

        // Check payment matches stored price
        require(msg.value == listing.price, NFTMarketPlace__IncorrectPrice());

        // Seller cannot buy their own NFT
        require(listing.seller != msg.sender, NFTMarketPlace__AlreadyBought());

        // Calculate fees
        uint256 feesAcquiredByContract = (listing.price * fees) / 1000; // which is equal to 2.5 percent
        uint256 sellerMoneyAfterFees = listing.price - feesAcquiredByContract;

        // Update state before external calls
        delete listings[nftAddress][tokenId];

        // Handle payments
        (bool feeSent, ) = i_feesOwner.call{value: feesAcquiredByContract}("");
        require(feeSent, NFTMarketPlace__FeeTransferFailed());

        (bool sellerPaid, ) = payable(listing.seller).call{
            value: sellerMoneyAfterFees
        }("");
        require(sellerPaid, NFTMarketPlace__SellerPaymentFailed());

        // Transfer NFT
        IERC721(nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        // Emit event
        emit TokenBought(nftAddress, tokenId, msg.sender);
    }

    /**
     * @notice Removes an NFT from the marketplace listings.
     * @dev
     * - Caller must own the NFT (onlyOwner modifier).
     * - NFT must currently be listed (price > 0).
     * - Deletes the listing from storage, resetting its data.
     * - Emits TokenDelisted event for off-chain tracking and UI updates.
     * @param tokenId The unique identifier of the NFT within its contract.
     * @param nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__NotListed Thrown if the NFT is not currently listed for sale.
     */
    function delist(
        uint256 tokenId,
        address nftAddress
    ) public onlyOwner(tokenId, nftAddress) {
        require(
            listings[nftAddress][tokenId].price > 0,
            NFTMarketPlace__NotListed()
        );

        delete listings[nftAddress][tokenId]; // removes listing entirely

        emit TokenDelisted(tokenId, nftAddress);
    }

    /**
     * @notice Updates the marketplace fee percentage.
     * @dev
     * - Only callable by the current feesOwner (see onlyFeeOwner modifier).
     * - newFees must be greater than zero.
     * - Fees are stored as a whole number representing a percentage (e.g., 5 = 5%).
     * @param newFees The new marketplace fee percentage to set.
     * @custom:error NFTMarketPlace__NotZero Thrown if newFees is zero.
     */
    function changeFees(uint256 newFees) external onlyFeeOwner {
        require(newFees > 0, NFTMarketPlace__NotZero());
        fees = newFees;
    }
    /////////////
    // Getters //
    ////////////
    /**
     * @notice Retrieves the details of a listed NFT.
     * @dev
     * - NFT must currently be listed (price > 0).
     * - Returns the Listing struct containing the sale price and seller address.
     * @param tokenId The unique identifier of the NFT within its contract.
     * @param nftAddress The contract address of the ERC721 NFT.
     * @return Listing struct containing:
     *         - price: The sale price in wei.
     *         - seller: The address of the current seller.
     * @custom:error NFTMarketPlace__NotListed Thrown if the NFT is not currently listed for sale.
     */
    function getListedItem(
        uint256 tokenId,
        address nftAddress
    ) public view returns (Listing memory) {
        require(
            listings[nftAddress][tokenId].price > 0,
            NFTMarketPlace__NotListed()
        );
        return listings[nftAddress][tokenId];
    }

    /**
     * @notice Retrieves the current marketplace fee percentage.
     * @dev Fee is stored as a whole number representing a percentage (e.g., 5 = 5%).
     * @return The current marketplace fee percentage.
     */
    function getFees() public view returns (uint256) {
        return fees;
    }
}