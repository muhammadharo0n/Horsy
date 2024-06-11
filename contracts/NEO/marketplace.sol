// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IConnected {
    // Struct to encapsulate detailed information about an NFT, used for easy data retrieval.
    struct NFT{ 
        uint256 tokenId;    
        uint256 price;
        uint256 count;
        bool minted;
        address artist;
        string uri;
        uint mintTime;
    }


    // Functions to be implemented by connected contracts for updating and retrieving NFT data
    function updateTokenId(address _to,uint _tokenId,address seller) external;
    // function update_TokenIdTime(uint _tokenId) external;
    function getTokenId(address _address) external view returns(NFT [] memory);
    function getTokenUri(uint _tokenId) external view returns(string memory);

}
contract NFTMarketplace is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;

        struct NFT{ 
        uint256 tokenId;    
        uint256 price;
        bool minted;
        address owner;
        string uri;
    }

    struct Index{ 
        address mintContract;
        uint tokenId;
    }

    mapping(address mintContract=>mapping(uint tokenId => NFT)) public NftListing;
    mapping(uint=>Index) public IndexListing; 

    event Listing (uint tokenId, address owner, uint price, string uri, bool minted);
    event NftSold (uint tokenId, address owner, uint price, string uri, bool minted);


        constructor(address owner) Ownable(msg.sender){
    owner = msg.sender;

    }

    function listItem(address _mintContract,uint _tokenId, uint _price, string memory _uri) public  { 
        _itemIds.increment();
        _itemIds.current();
        NftListing[_mintContract][_tokenId] = NFT(_tokenId, _price, true, msg.sender, _uri);
        IndexListing[_itemIds.current()] = Index(_mintContract, _tokenId);
        emit Listing (_tokenId , msg.sender , _price, _uri, true);
    }

    function buy (uint _tokenId) public payable { 
        
        address contractAddress = IndexListing[_tokenId].mintContract;
        require(NftListing[contractAddress][_tokenId].owner!= msg.sender, "Owner cannot buy this NFT");
        require(NftListing[contractAddress][_tokenId].minted= true, "NFT not Listed");
        ERC721(contractAddress).transferFrom(address(this), msg.sender, _tokenId);

        payable(owner()).transfer(msg.value);
        emit NftSold(_tokenId, msg.sender, NftListing[contractAddress][_tokenId].price, NftListing[contractAddress][_tokenId].uri, NftListing[contractAddress][_tokenId].minted);
    }



}