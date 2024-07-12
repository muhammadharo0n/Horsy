// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

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

    mapping(address => mapping (uint => NFTItem)) public nftListing;
    mapping(uint =>Index) public nftIndex;

    event ItemCreated(uint256 indexed itemId, address indexed creator, string uri, uint256 price);
    event ItemSold(uint256 indexed itemId, address indexed buyer, uint256 price);

    function createItem(uint tokenId, string memory uri, uint256 price, address _mintContract) public onlyOwner {
        _itemIds.increment();
        nftListing[_mintContract][tokenId]= NFTItem(_itemIds.current(), price, _itemIds.current(),msg.sender, uri, true);
        nftIndex[_itemIds.current()] = Index(_itemIds.current(), msg.sender);
        // ERC721(_mintContract).safeTransferFrom(msg.sender, address(this), itemId); 

        emit ItemCreated(_itemIds.current(), msg.sender, uri, price);
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