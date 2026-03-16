# Simple NFT Marketplace

A professional, root-only repository containing a robust NFT Marketplace implementation. This contract allows users to list their ERC721 tokens for sale in a trustless environment.

### Features
* **Fixed Price Listings**: Users can list NFTs for a specific price in Ether.
* **Platform Fees**: Integrated owner-controlled fee percentage for every successful sale.
* **Security**: Uses the Pull-Payment pattern for safety and ReentrancyGuard for execution security.
* **Management**: Functions to update listing prices or cancel active listings.

### How to Use
1. Deploy `NftMarketplace.sol` providing the desired platform fee percentage.
2. Users must `approve` the marketplace contract to handle their NFT.
3. Call `listItem` to put an NFT up for sale.
4. Buyers call `buyItem` and send the required ETH to complete the trade.
