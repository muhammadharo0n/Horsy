// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private itemsAuction;

    constructor(address owner) Ownable(msg.sender){

    owner = msg.sender;


    }

    struct NFTItem {
        uint256 id;
        uint price;
        uint256 count;
        address creator;
        string uri;
        bool sold;
    }
    struct Index{ 
        uint tokenId;
        address owner;
    }
    struct Auction{ 
        uint tokenId;
        uint amount;
        uint minBid;
        uint artistFeePerAge;
        uint endTime;
        uint highestBid;
        address owner;
        address artist;
        address highestBidder;
        bool isActive;

    }
    struct auctionIndexing{
        uint tokenId;
        address contractAddress;
    }
    struct bidder{ 
        address user;
        string username;
        uint time;
        uint count;
        uint highestBid;
    }
    struct userBidCount{ 
        address userAdress;
        uint priceEntered;
    }

    mapping(address => mapping (uint => NFTItem)) public nftListing;
    mapping(uint =>Index) public nftIndex;

    mapping(address => mapping(uint =>Auction))public autionListing;
    mapping(uint => auctionIndexing) public auctionIndex;
    mapping(address => mapping (uint => bidder)) public auctionBidder;
    mapping(address=>uint) public userBidCounter;

    event ItemCreated(uint256 indexed itemId, address indexed creator, string uri, uint256 price);
    event ItemSold(uint256 indexed itemId, address indexed buyer, uint256 price);

    function listItem(address _mintContract, uint tokenId, string memory uri, uint256 price) public onlyOwner {
        _itemIds.increment();
        nftListing[_mintContract][tokenId]= NFTItem(tokenId, price, _itemIds.current(),msg.sender, uri, true);
        nftIndex[tokenId] = Index(_itemIds.current(), msg.sender);
        ERC721(_mintContract).transferFrom(msg.sender, address(this), tokenId); 
        emit ItemCreated(_itemIds.current(), msg.sender, uri, price);
    }

    function auctionNft(address _mintContract, uint tokenId, uint _minimumBid, uint _artistFee, address _artist) public{ 
        itemsAuction.increment();
        autionListing[_mintContract][tokenId] = Auction(tokenId, itemsAuction.current(), _minimumBid, _artistFee, block.timestamp + 100 seconds, 0,msg.sender, _artist, address(0), true);
        auctionIndex[tokenId] = auctionIndexing(itemsAuction.current(), _mintContract);
        ERC721(_mintContract).transferFrom(msg.sender, address(this), tokenId);
    }
    function biddingNft(uint _tokenId, string memory _username) public { 
        address contractAddress = auctionIndex[_tokenId] .contractAddress;
        uint tokenId = auctionIndex[_tokenId] .tokenId;
        require(autionListing[contractAddress][tokenId].minBid<=autionListing[contractAddress][tokenId].amount,"Bid should be more that Minimum bid ");
        // require(autionListing[contractAddress][tokenId].isActive,"tokenId is not active yet");
        require(autionListing[contractAddress][tokenId].artist != msg.sender,"artist canot bid");
        require(autionListing[contractAddress][tokenId].owner != msg.sender,"owner cannot bid");
        autionListing[contractAddress][tokenId].highestBid >= autionListing[contractAddress][tokenId].amount;
        autionListing[contractAddress][tokenId].highestBidder == msg.sender;
        
        auctionBidder[contractAddress][_tokenId] = bidder(msg.sender, _username, block.timestamp,userBidCounter[msg.sender]++, autionListing[contractAddress][tokenId].highestBid);

    }
    // function buyItem(uint256 itemId) public payable {
    //     NFTItem storage item = _items[itemId];
    //     require(item.sold == false, "Item already sold");
    //     require(msg.value >= item.price, "Insufficient funds");

    //     item.sold = true;
    //     _itemsSold.increment();

    //     emit ItemSold(itemId, msg.sender, item.price);

    //     payable(item.creator).transfer(item.price);
    // }
}