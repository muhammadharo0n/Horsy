// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract Marketplace is Ownable{
    
    uint256 public _nextTokenId;
    uint tokenAddress;

    constructor (address initialOwner) Ownable(initialOwner) { 

        // mintContract= _tokenAddress;
        // dividnd = _dividnd;


    }
        
    struct NftListing{
        uint tokenId;
        uint price;
        address to;
        address artist;
        bool sold;
        bool listed;
    }
    struct TokenAddress{ 
        uint tokenId;
        address mintContract;
    }

    mapping(address mintContractAddress => mapping (uint tokenId => NftListing) ) public tokenListing;
    mapping(uint => TokenAddress) public Index;

    function listNft (uint _tokenId, uint _price, address _mintContract) public{ 
        _nextTokenId++;
        tokenListing[_mintContract][_tokenId]= NftListing(_tokenId, _price, address(this), msg.sender,false, true);
        Index[_nextTokenId] = TokenAddress(_tokenId, _mintContract);
        ERC721(_mintContract).transferFrom(msg.sender,address(this), _tokenId);    
    }

    function buyNft( uint _tokenId) public payable {

        address contractAddress = Index[_tokenId].mintContract;
        uint id = Index[_tokenId].tokenId;
        require(tokenListing[contractAddress][id].price <= msg.value,"you have entred wrong price ");
        require(tokenListing[contractAddress][id].listed = true , "NFT not minted");
        ERC721(contractAddress).safeTransferFrom(address(this), msg.sender, id);
        payable (owner()).transfer(msg.value);

        } 
    function getAllTokenIds(address userAddress) public view returns (NftListing [] memory){ 
        uint listed = _nextTokenId;
        uint index = 0;
        NftListing [] memory getMinting = new NftListing [] (listed);
        for(uint i=0 ; i<listed; i++){ 
            if (tokenListing[Index[i].mintContract][Index[i].tokenId].artist == userAddress){ 
                getMinting[listed] = tokenListing[Index[i].mintContract][Index[i].tokenId];
                index++;
               }
        }
        return getMinting;
    }
}