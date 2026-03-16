// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NftMarketplace
 * @dev A clean, professional marketplace for ERC721 tokens.
 */
contract NftMarketplace is ReentrancyGuard, Ownable {
    struct Listing {
        uint256 price;
        address seller;
    }

    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event ItemBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    // Platform fee in basis points (e.g., 250 = 2.5%)
    uint256 public platformFeeBps; 
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    constructor(uint256 _feeBps) Ownable(msg.sender) {
        platformFeeBps = _feeBps;
    }

    function listItem(address nftAddress, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be above zero");
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Not approved for marketplace");

        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory listing = s_listings[nftAddress][tokenId];
        require(listing.seller == msg.sender, "Not the seller");
        delete s_listings[nftAddress][tokenId];
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        require(listedItem.price > 0, "Item not listed");
        require(msg.value >= listedItem.price, "Insufficient funds");

        delete s_listings[nftAddress][tokenId];

        uint256 fee = (listedItem.price * platformFeeBps) / 10000;
        uint256 sellerProceeds = listedItem.price - fee;

        // Transfer funds
        (bool successFee, ) = payable(owner()).call{value: fee}("");
        require(successFee, "Fee transfer failed");
        
        (bool successSeller, ) = payable(listedItem.seller).call{value: sellerProceeds}("");
        require(successSeller, "Seller transfer failed");

        // Transfer NFT
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice) external {
        require(newPrice > 0, "Price must be above zero");
        require(s_listings[nftAddress][tokenId].seller == msg.sender, "Not the seller");
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenId];
    }
}
