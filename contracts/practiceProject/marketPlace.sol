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
        address creator;
        string uri;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => NFTItem) private _items;

    event ItemCreated(uint256 indexed itemId, address indexed creator, string uri, uint256 price);
    event ItemSold(uint256 indexed itemId, address indexed buyer, uint256 price);

    function createItem(string memory uri, uint256 price) public onlyOwner {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        _items[itemId] = NFTItem(itemId, msg.sender, uri, price, false);

        emit ItemCreated(itemId, msg.sender, uri, price);
    }

    function buyItem(uint256 itemId) public payable {
        NFTItem storage item = _items[itemId];
        require(item.sold == false, "Item already sold");
        require(msg.value >= item.price, "Insufficient funds");

        item.sold = true;
        _itemsSold.increment();

        emit ItemSold(itemId, msg.sender, item.price);

        payable(item.creator).transfer(item.price);
    }

    function getItem(uint256 itemId) public view returns (uint256 id, address creator, string memory uri, uint256 price, bool sold) {
        NFTItem storage item = _items[itemId];
        id = item.id;
        creator = item.creator;
        uri = item.uri;
        price = item.price;
        sold = item.sold;
    }

    function getItemsSold() public view returns (uint256) {
        return _itemsSold.current();
    }
}