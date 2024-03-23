// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/LibAppStorage.sol";



contract MarketPlaceFacet {
    LibAppStorage.AppStorage.Listing internal l;
    ERC721 public nftContract;

    constructor(address _nftContract) {
        nftContract = ERC721(_nftContract);
    }

    function listNFT(uint256 _tokenId, uint256 _price) external {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");
        require(_price > 0, "Price should be greater than zero");
        require(!l.tokenIdToListing[_tokenId].isActive, "NFT is already listed");

        tokenIdToListing[_tokenId] = l({
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        emit NFTListed(_tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _tokenId) external payable {
        LibAppStorage listing = l.tokenIdToListing[_tokenId];
        require(listing.isActive, "NFT is not listed");
        require(msg.value >= listing.price, "Insufficient funds");

        address seller = listing.seller;
        uint256 price = listing.price;

        delete l.tokenIdToListing[_tokenId];

        nftContract.safeTransferFrom(l.seller, msg.sender, _tokenId);
        payable(l.seller).transfer(l.price);

        emit NFTSold(_tokenId, l.seller, msg.sender, l.price);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
