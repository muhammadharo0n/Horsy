// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    constructor(address initialOwner)
        ERC721("MyToken", "MTK")
        Ownable(initialOwner)
    {}
    struct NFT{ 
        uint256 tokenId;    
        uint256 price;
        string  uri;
    }
    uint public tokenId;


    mapping(uint=>NFT) public Neo;
    mapping(uint=>NFT) public Quantum;
    mapping(uint=>NFT) public Sentement;

    function safeMint(uint price, string memory uri) public
    {
     
        tokenId++;
    if(tokenId <= 5){ 
        Neo[tokenId] = NFT(tokenId, price, uri);
    } else if(tokenId <= 10){
        Quantum[tokenId] = NFT(tokenId, price, uri);
    } else if(tokenId <= 15){
        Sentement[tokenId] = NFT(tokenId, price, uri);
    }else { 
        require(tokenId<16,'No more NFT to mint');  
    }

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

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
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
