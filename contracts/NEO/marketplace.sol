// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// interface IConnected {
//     // Struct to encapsulate detailed information about an NFT, used for easy data retrieval.
//     struct NFT{ 
//         uint256 tokenId;    
//         uint256 price;
//         uint256 count;
//         bool minted;
//         address artist;
//         string uri;
//         uint mintTime;
//     }


//     // Functions to be implemented by connected contracts for updating and retrieving NFT data
//     function updateTokenId(address _to,uint _tokenId,address seller) external;
//     // function update_TokenIdTime(uint _tokenId) external;
//     function getTokenId(address _address) external view returns(NFT [] memory);
//     function getTokenUri(uint _tokenId) external view returns(string memory);

// }
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
    
    mapping(uint=>mapping(address=>NFT)) public Tier1;
    mapping(uint=>mapping(address=>NFT)) public Tier2;
    mapping(uint=>mapping(address=>NFT)) public Tier3;
    mapping(uint=>mapping(address=>NFT)) public Tier4;
    mapping(uint=>mapping(address=>NFT)) public Tier5;
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
        require(_tokenId <= 15, 'No more NFT to mint');

    if(_tokenId <= 5){ 
        Tier1[_tokenId][msg.sender] = NFT(_tokenId, _price, true, msg.sender, _uri);
        
    } else if(_tokenId <= 9){

        Tier2[_tokenId][msg.sender] = NFT(_tokenId, _price, true, msg.sender, _uri);  
         
    } else if(_tokenId <= 12){
        Tier3[_tokenId][msg.sender] = NFT(_tokenId, _price, true, msg.sender, _uri);
    }
      else if(_tokenId <= 14){
        Tier4[_tokenId][msg.sender] = NFT(_tokenId, _price, true, msg.sender, _uri);
    }
      else if(_tokenId <= 15){
        Tier5[_tokenId][msg.sender] = NFT(_tokenId, _price, true, msg.sender, _uri);
    }
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId);
    }

    function buy (uint tokenId) public payable { 
        
        address contractAddress = IndexListing[tokenId].mintContract;
        require(NftListing[contractAddress][tokenId].owner!= msg.sender, "Owner cannot buy this NFT");
        require(NftListing[contractAddress][tokenId].minted= true, "NFT not Listed");
        require(msg.value >= NftListing[contractAddress][tokenId].price, "Insufficient funds");
        ERC721(contractAddress).transferFrom(address(this), msg.sender, IndexListing[tokenId].tokenId);

        payable(owner()).transfer(NftListing[contractAddress][tokenId].price);
        emit NftSold(tokenId, msg.sender, NftListing[contractAddress][tokenId].price, NftListing[contractAddress][tokenId].uri, NftListing[contractAddress][tokenId].minted);
    }

}