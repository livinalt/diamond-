// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibAppStorage {
    struct AppStorage {
        //erc721 token ==> NFTToken
        mapping(address owner => uint256) _balances;
        mapping(uint256 tokenId => address) _tokenApprovals;
        mapping(address owner => mapping(address operator => bool)) _operatorApprovals;
        mapping(uint256 tokenId => string) tokenURI;
        // for the marketplace Place
        address seller;
        uint256 price;
        bool isActive;
        mapping(uint256 => Listing) tokenIdToListing;
        uint256 _tokenIds;
        //NFTTokenFacet
        mapping(uint256 tokenId => address) _owners;
        

        // event Transfer(
        //     address indexed from,
        //     address indexed to,
        //     uint256 indexed tokenId);
        
    }

}
