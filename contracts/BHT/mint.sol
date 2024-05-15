// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemsId;

        struct NFT{ 
        uint256 tokenId;    
        uint256 price;
        uint256 count;
        address artist;
        string uri;
        uint mintTime;        
        bool minted;

    }

    mapping(address =>mapping (uint =>uint)) public NftId ;
    mapping(address => uint) public count ; 
    mapping(uint => NFT) public NftMinting;
    mapping(address=>bool) public whitelist;

    constructor() ERC721("BHANBANAS", "BHT") Ownable(msg.sender) {
    }

    function whitelisting(address[] calldata addrr) public { 
        for(uint i; i<addrr.length; i++){ 
           whitelist[addrr[i]] = true; 
        }
    }

    function safeMint(string memory uri) public payable{
        require(whitelist[msg.sender] = true,"User not approved");
        // require(NftMinting[NftId[msg.sender][_itemsId.current()]].price >= msg.value,"Enter correct price");
        require(msg.value > 0 , " Enter any number");
        _itemsId.increment();
        _itemsId.current();
        // Mint Function
        NftId[msg.sender][count[msg.sender]+1] = _itemsId.current();


        NftMinting[_itemsId.current()] = NFT(_itemsId.current(), msg.value,  count[msg.sender]+1, msg.sender, uri, block.timestamp, true);
        _safeMint(msg.sender,_itemsId.current());
        _setTokenURI(_itemsId.current(), uri);

        count[msg.sender]++;

        // Transfer Token to address

        payable(owner()).transfer(msg.value);

    }
    function getTokenId( ) public view returns(NFT[] memory) { 
        NFT[]memory myArray = new NFT[](count[msg.sender]);
        for (uint i; i<count[msg.sender]; i++){ 
            myArray[i] = NFT(
            NftId[msg.sender][i + 1],
            NftMinting[NftId[msg.sender][i + 1]].price,
            NftMinting[NftId[msg.sender][i + 1]].count,
            NftMinting[NftId[msg.sender][i + 1]].artist,
            NftMinting[NftId[msg.sender][i + 1]].uri,
            NftMinting[NftId[msg.sender][i + 1]].mintTime,
            NftMinting[NftId[msg.sender][i + 1]].minted
            );
        }
        return myArray;
    }

    function getTokenUri(uint tokenId) external view returns(string memory){
        return tokenURI(tokenId);
    }

        // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}


