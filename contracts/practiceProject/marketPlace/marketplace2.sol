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
    Counters.Counter public nextLandListId;       // Counter for LandNFTs listed in marketplace

    IERC721 public landContract;

    uint public totalLockedNft;
    address public immutable tokenAddress;
    uint public startTime;
    uint public endTime;

    struct ListLand {
        address owner;
        address seller;
        uint256 tokenId;
        uint256 count;
        uint256 price;
        bool listed;
    
    } 

    struct NftDetails{ 
        uint TokenId;
        address stakerAddress; 
        address currentOwnerAddress; 
        uint userWithdrawToken;
        uint withdrawMonth;
        uint stakeTime;
        bool isActive;
    }


    struct AddressToken {
        address contractAddress;
        uint tokenId;
        uint amount;
    }

    struct Address_Token {
        address contractAddress;
        uint tokenId;
    }

    struct ListedLandNftTokenId {
        ListLand listedData;          // The direct sale listing data for the NFT.
        uint listCount;          // A count or ID similar to `ListTokenId`.
        string uriData;          // URI for the NFT metadata.
    }


  
    mapping(uint256 => Address_Token) public listCount;
    mapping(address => uint256) public userCount;
    mapping(uint => uint) public userListCount; 
    mapping(uint => NftDetails) public lockedNFT;                                 //// Mapping to store details of all locked NFTs
    mapping(uint => AddressToken) public auctionListCount;                        // Maps auction indices to address and token ID pairs
    mapping (address mintAddress => mapping (uint tokedId => NftDetails)) public NftSupply;
    mapping (address => mapping (uint =>uint)) public rewardAmount;
    mapping(address => mapping(uint256 => ListLand)) public userLandListings;
     
     /**
     * @dev Ensures conditions to lock an NFT are met:
     * - Vesting period must have started and not ended.
     * - The NFT must not be already staked.
     * @param tokenId The unique identifier of the NFT.
     */
    modifier lockConditions(uint tokenId) {
        require(startTime != endTime ,"Please wait...");
        require(startTime < block.timestamp, "Time Not Start..."); // Vesting must have started
        require(endTime > block.timestamp, "Time End."); // Vesting must not have ended
        require(!lockedNFT[tokenId].isActive, "Already Staked"); // Must not be staked
        _;
    }
    /**
     * @dev Ensures conditions to unlock an NFT are met:
     * - Vesting period must not have ended.
     * - Caller must be the staker of the NFT.
     * - The NFT must be currently staked.
     * @param tokenId The unique identifier of the NFT.
     */
    modifier unlockConditions(uint tokenId, address stakerAddress) {
        require(endTime < block.timestamp, "Please wait..."); // Vesting must not have ended
        require(lockedNFT[tokenId].stakerAddress == stakerAddress, "You are not owner of this NFT."); // Must be staker
        require(lockedNFT[tokenId].isActive, "NOT LOCKED."); // Must be staked
        _;
    }
    constructor(address initialOwner, IERC721 _landMinting,address _USDCAddress) Ownable(initialOwner) {
        landContract = _landMinting;
        tokenAddress= _USDCAddress;
    }

    function listLandNft(address _mintContract, uint256 _price, uint256 _tokenId) public nonReentrant {
        require(!userLandListings[_mintContract][_tokenId].listed, "Already Listed In Marketplace!");
        require(!NftSupply[_mintContract][_tokenId].isActive,"NFT already staked");
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        nextLandListId.increment();
        userLandListings[_mintContract][_tokenId] = ListLand(msg.sender, address(this), _tokenId, nextLandListId.current(), _price, true);
        listCount[nextLandListId.current()] = Address_Token(_mintContract, _tokenId);
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId); 
        userCount[msg.sender]++;
    }  

    function buyLandNft(uint256 listIndex, uint256 price) external payable nonReentrant {
        require(userLandListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].owner != msg.sender, "Owner Can't Buy Its Nfts");
        require(price >= userLandListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price, "Not enough ether to cover asking price");
        uint sellerAmount = userLandListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price;
        payable(userLandListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].owner).transfer(sellerAmount);
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        IConnected(listCount[listIndex].contractAddress).updateTokenId(msg.sender,listCount[listIndex].tokenId,userLandListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller);
        userLandListings[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed = false;
        delete listCount[nextLandListId.current()];
        nextLandListId.decrement();
    }


    /**
     * @dev Sets the vesting period.
     * Configures the start and end times for the vesting period.
     * @param start The start time of the vesting period.
     * @param end The end time of the vesting period.
     */
    function stakingPeriod(uint start, uint end) public onlyOwner {
        startTime = start;
        endTime = end;
    }

   /**
     * @dev Locks NFT.
     * @param stakerAddress The address of the staker.
     * @param tokenId The unique identifier of the NFT.
     */
    function stakeNFT(address mintContract, address stakerAddress, uint tokenId) public lockConditions(tokenId)
    {
        lockedNFT[tokenId] = NftDetails(tokenId, stakerAddress, address(this), 0, 0, block.timestamp, true);
        totalLockedNft++;
        ERC721(mintContract).transferFrom(stakerAddress, address(this), tokenId);
    }

    /**
     * @dev Unlocks NFT.
     * Unlocks the specified Starlight NFT by transferring it back to the staker.
     * @param stakerAddress The address of the staker.
     * @param tokenId The unique identifier of the NFT.
     */
    function unStakeNFT(address mintContract , address stakerAddress, uint tokenId) public unlockConditions(tokenId, stakerAddress) {
        lockedNFT[tokenId].isActive = false;
        totalLockedNft--;
        ERC721(mintContract).transferFrom(address(this), stakerAddress, tokenId);
    }

 /**
     * @dev Allows users to claim their earned tokens based on the locked NFT.
     * Users can claim their rewards based on the category of their locked NFT.
     * @param userAddress The address of the user.
     * @param tokenId The unique identifier of the NFT.
     */
    function userClaimFT(address userAddress, uint tokenId) public {
        (uint reward, uint month) = user_Staking_Rewards(tokenId);
        require(month != 0, "Please wait...");
        require(lockedNFT[tokenId].withdrawMonth != 12,"You have claimed your all rewards according to this NFT...");
        if (lockedNFT[tokenId].withdrawMonth + month < 12) {
            lockedNFT[tokenId].withdrawMonth += month;
            lockedNFT[tokenId].userWithdrawToken += (reward * month);
            IERC20(tokenAddress).safeTransfer(userAddress, (reward * month));
        } else {
            uint remainingMonth = (12 - lockedNFT[tokenId].withdrawMonth);
            lockedNFT[tokenId].withdrawMonth += remainingMonth;
            lockedNFT[tokenId].userWithdrawToken += (reward * remainingMonth);
            IERC20(tokenAddress).safeTransfer(userAddress, (reward * remainingMonth));
        }
    }
   
    /**
     * @dev Calculates user rewards based on the time and category of the NFT.
     * Calculates the rewards and the number of months the user can claim.
     * @param tokenId The unique identifier of the NFT.
     * @return rewards The calculated rewards.
     * @return month The number of months the user can claim rewards for.
     */
    function user_Staking_Rewards(uint tokenId) public view returns (uint rewards, uint month) {
        if (((block.timestamp - endTime) - (lockedNFT[tokenId].withdrawMonth * 60)) >= 60) {
            uint months = ((block.timestamp - endTime) - (lockedNFT[tokenId].withdrawMonth * 60)) / 60;
            uint reward = (1 * months);
            return (reward, months);
        } else {
            return (0,0);
        }
    }

    function adminDepositToken(address adminAddress, uint tokenDeposit) public onlyOwner{ 
        IERC20(tokenAddress).safeTransferFrom(adminAddress, address(this), tokenDeposit);
    }

    function adminWithdrawToken(address adminAddress, uint tokenDeposit) public onlyOwner{ 
        IERC20(tokenAddress).safeTransferFrom( address(this), adminAddress, tokenDeposit);
    }

    
    function getAllLandListedNfts() public view returns (ListedLandNftTokenId[] memory) {
        uint listNft = nextLandListId.current();
        ListedLandNftTokenId[] memory listedNFT = new ListedLandNftTokenId[](listNft);
        uint listedIndex = 0;
        for (uint i = 1; i <= nextLandListId.current() ; i++) {
            if (userLandListings[listCount[i].contractAddress][listCount[i].tokenId].listed) {
                listedNFT[listedIndex] = ListedLandNftTokenId(userLandListings[listCount[i].contractAddress][listCount[i].tokenId],i,IConnected(listCount[i].contractAddress).getTokenUri(listCount[i].tokenId));
                listedIndex++;
            }
        }
        return (listedNFT);
    }

}