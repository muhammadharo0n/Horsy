// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract Marketplace is Ownable{
        uint256 public _nextTokenId;
        uint public _nftStakeId;
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
    struct NftStaking{ 
        uint tokenId;
        uint startTime;
        address stakedAddress;
    }
    struct stakingNftIndex{ 
        uint tokenId;
        address mintContract;
    }
    mapping(address mintContractAddress => mapping (uint tokenId => NftListing) ) public tokenListing;
    mapping(uint => TokenAddress) public Index;
    mapping(address  => NftStaking) public stakeListing;
    mapping(uint => stakingNftIndex) public stakingIndex;


    function listTokens (uint _tokenId, uint _price, address _mintContract) public{ 
        _nextTokenId++;
        tokenListing[_mintContract][_tokenId]= NftListing(_tokenId, _price, address(this), msg.sender,false, true);
        Index[_nextTokenId] = TokenAddress(_tokenId, _mintContract);
        ERC721(_mintContract).transferFrom(msg.sender,address(this), _tokenId);      
    }

    function buyTokens( uint _tokenId) public payable {

        address contractAddress = Index[_tokenId].mintContract;
        require(tokenListing[contractAddress][_tokenId].price <= msg.value,"you have entred wrong price ");
        require(tokenListing[contractAddress][_tokenId].listed = true , "NFT not minted");
        ERC721(contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        payable (owner()).transfer(msg.value);

        } 
    function stakeNft( uint _tokenId, address contractAddress) public { 
        
        _nftStakeId++;
        stakeListing[msg.sender] = NftStaking(_tokenId, block.timestamp, contractAddress);
        ERC721(contractAddress).transferFrom(msg.sender,address(this), _tokenId);
        stakingIndex[_nftStakeId] = stakingNftIndex(_tokenId, contractAddress);
   
    }
    function stakeReward(uint _tokenId, address _mintAddress) public { 
        reward = 
        IERC20(_mintAddress).transferFrom(msg.sender,reward)
    }
}