// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
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


    mapping(uint=>mapping(address=>NFT)) public Tier1;
    mapping(uint=>mapping(address=>NFT)) public Tier2;
    mapping(uint=>mapping(address=>NFT)) public Tier3;
    mapping(uint=>mapping(address=>NFT)) public Tier4;
    mapping(uint=>mapping(address=>NFT)) public Tier5;


    function safeMint(uint price) public
    {
    string memory uri;
    string memory Neoo;
    string memory Quantumm;
    string memory name;
        tokenId++;
    if(tokenId <= 5){ 
        uri = Neoo;
        Tier1[tokenId][msg.sender] = NFT(tokenId, price, uri);
        
    } else if(tokenId <= 9){
        uri = Quantumm;
        Tier2[tokenId][msg.sender] = NFT(tokenId, price, uri);
        _burn(5);
    } else if(tokenId <= 12){
        uri = Neoo;
        Tier3[tokenId][msg.sender] = NFT(tokenId, price, uri);
    }
      else if(tokenId <= 14){
        uri = Quantumm;
        Tier4[tokenId][msg.sender] = NFT(tokenId, price, uri);
    }
      else if(tokenId <= 15){
        uri = Neoo;
        Tier5[tokenId][msg.sender] = NFT(tokenId, price, uri);
    }
    else { 
        require(tokenId<16,'No more NFT to mint');  
    }
    name = uri;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, name);
    }

    
    // Override the transfer functions to prevent transfers

    function transferFrom(address from, address to, uint256 tokenID) public virtual override(ERC721, IERC721) {
        revert("NFTs are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenID) public virtual override(ERC721, IERC721) {
        revert("NFTs are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) public virtual override(ERC721, IERC721) {
        revert("NFTs are non-transferable");
    }


    function _update(address to, uint256 tokenID, address auth)
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

    function tokenURI(uint256 tokenID)
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
