
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IConnected {
    // Struct to encapsulate detailed information about an NFT, used for easy data retrieval.
     struct NFT { 
        uint256 tokenId;    
        uint256 count;
        string uri;
        uint mintTime;        
        bool minted;
    }

    // Functions to be implemented by connected contracts for updating and retrieving NFT data
    function updateTokenId(address _to,uint _tokenId,address seller) external;
    function getTokenId(address _to) external view returns(NFT[] memory);
    function getTokenUri(uint _tokenId) external view returns(string memory);

}





contract NFTMarketplace is ReentrancyGuard, Ownable{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter public nextNftListId;       // Counter for NftNFTs listed in marketplace

    IERC721 public NftContract;

    address public immutable tokenAddress;


    struct ListNft{
        address owner;
        address seller;
        uint256 tokenId;
        uint256 count;
        uint256 price;
        bool listed;
    
    } 

    struct Address_Token {
        address contractAddress;
        uint tokenId;
    }

    struct ListedNftNftTokenId {
        ListNft listedData;          // The direct sale listing data for the NFT.
        uint listCount;          // A count or ID similar to `ListTokenId`.
        string uriData;          // URI for the NFT metadata.
    }


  
    mapping(uint256 => Address_Token) public listCount;
    mapping(address => uint256) public userCount;
    mapping(uint => uint) public userListCount;
    mapping(address => mapping(uint256 => ListNft)) public userNftListings;
     

    constructor(address initialOwner, IERC721 _NftMinting,address _USDCAddress) Ownable(initialOwner) {
        NftContract = _NftMinting;
        tokenAddress= _USDCAddress;
    }

    function listNft(address _mintContract, uint256 _price, uint256 _tokenId) public nonReentrant {
        require(!userNftListings[_mintContract][_tokenId].listed, "Already Listed In Marketplace!");
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        nextNftListId.increment();
        userNftListings[_mintContract][_tokenId] = ListNft(msg.sender, address(this), _tokenId, nextNftListId.current(), _price, true);
        listCount[nextNftListId.current()] = Address_Token(_mintContract, _tokenId);
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId); 
        userCount[msg.sender]++;
    }  

    function buyNft(uint256 listIndex, uint256 price) external nonReentrant {
        address Owner = userNftListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].owner;
        require(userNftListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].owner != msg.sender, "Owner Can't Buy Its Nfts");
        require(price >= userNftListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price, "Not enough ether to cover asking price");
        IERC20(tokenAddress).safeTransferFrom(msg.sender,Owner,price);
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        IConnected(listCount[listIndex].contractAddress).updateTokenId(msg.sender,listCount[listIndex].tokenId,userNftListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller);
        userNftListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed = false;
        delete listCount[nextNftListId.current()];
        nextNftListId.decrement();
    }

        function CancelListForSale(uint listIndex) public {
        address contractAddress = listCount[listIndex].contractAddress;
        uint id = listCount[listIndex].tokenId;
        require(userNftListings[contractAddress][id].listed,"Please List First !!!");
        userNftListings[contractAddress][listIndex].seller = userNftListings[contractAddress][id].seller;
        ERC721(contractAddress).transferFrom(address(this), msg.sender, listCount[nextNftListId.current()].tokenId);
        userNftListings[contractAddress][id].listed=false;
        userNftListings[contractAddress][id].count = listIndex;
        listCount[listIndex] = listCount[nextNftListId.current()];
        nextNftListId.decrement();

    }


    
    function getAllNftListedNfts() public view returns (ListedNftNftTokenId[] memory) {
        uint listNfts = nextNftListId.current();
        ListedNftNftTokenId[] memory listedNFT = new ListedNftNftTokenId[](listNfts);
        uint listedIndex = 0;
        for (uint i = 1; i <= nextNftListId.current() ; i++) {
            if (userNftListings[listCount[i].contractAddress][listCount[i].tokenId].listed) {
                listedNFT[listedIndex] = ListedNftNftTokenId(userNftListings[listCount[i].contractAddress][listCount[i].tokenId],i,IConnected(listCount[i].contractAddress).getTokenUri(listCount[i].tokenId));
                listedIndex++;
            }
        }
        return (listedNFT);
    }

}