// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
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
    function getUserTokenUri(uint tokenId) external view returns(string memory);

}





contract NFTMarketplace is ERC1155Holder,ReentrancyGuard, Ownable{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    IERC1155 public buildingContract;
    IERC721 public landContract;
    // State variables
    Counters.Counter public nftAuctionCount;       // Counter for NFTs listed for auction
    Counters.Counter public nextLandListId;       // Counter for LandNFTs listed in marketplace
    Counters.Counter public nextBundleListingId; //  Counter for Buildings/Items NFTs listed in marketplace

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

    struct BundleListing {
        address seller;
        address owner;
        address artist;
        uint256[] tokenIds;
        uint256[] amounts;
        uint256 price;
        uint artistFee;
        bool active;
    }

    struct Auction {
        address owner;          // Owner of the NFT being auctioned.
        uint tokenId;           // Unique identifier for the NFT.
        uint amount;
        uint minimumBid;        // Minimum bid required to participate in the auction.
        address artist;         // The original creator/artist of the NFT.
        uint artistFeePerAge;   // Artist's fee per age, similar to the NFT struct.
        uint endTime;
        bool isActive;          // Indicates if the auction is currently active.
        address highestBidder;
        uint highestBid;
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
    struct addressToken {
        address contractAddress;
        uint[] tokenId;
        uint[] amount;
    }
    struct Address_Token {
        address contractAddress;
        uint tokenId;
    }

     // Stores details about a user's bid in an auction, including the bid amount and time.
    struct userDetail {
        address user;           // Address of the user making the bid.
        string userName;        // Optionally, a username or identifier for the bidder.
        uint price;             // The price of the bid.
        uint biddingTime;       // Timestamp when the bid was placed.
        uint bidCount;          // Number of bids placed by this user (for this auction?).
    }
     // Contains information about a Auction NFT in the auction, including its data and listing count.
    struct ListTokenId {
        Auction listedData;   // The auction data for the listed NFT.
        uint listCount;          // A count that could represent the number of times listed or an ID.
        string uriData;          // URI for the NFT metadata.
    }

    // Similar to `ListTokenId` but specifically for NFTs listed for direct sale.
    struct ListedNftTokenId {
        BundleListing listedData;          // The direct sale listing data for the NFT.
        uint listCount;          // A count or ID similar to `ListTokenId`.
        string uriData;          // URI for the NFT metadata.
    }
    struct ListedLandNftTokenId {
        ListLand listedData;          // The direct sale listing data for the NFT.
        uint listCount;          // A count or ID similar to `ListTokenId`.
        string uriData;          // URI for the NFT metadata.
    }


    mapping(uint256 => BundleListing) public bundleListings;
    mapping(uint256 => Address_Token) public listCount;
    mapping(address => uint256) public userCount;
    mapping(uint => uint) public userListCount; 
    mapping (uint => addressToken) public buildingListCount;
    mapping(uint => NftDetails) public lockedNFT;                                 //// Mapping to store details of all locked NFTs
    mapping(uint => AddressToken) public auctionListCount;                        // Maps auction indices to address and token ID pairs
    mapping(address => mapping(uint => mapping(uint => userDetail))) public Bidding; // Maps auction details to user bids
    mapping(uint => address) public SelectedUser;                                    // Maps selected user for auction
    mapping(address => mapping(uint => mapping(address => mapping(uint => uint)))) public BiddingCount; // Helper mapping for bidding counts
    mapping(address => mapping(uint => mapping(address => uint))) public userBiddingCount; // Helper mapping for user bidding counts
    mapping(address => mapping(uint => Auction)) public NftAuction; 
    mapping (address mintAddress => mapping (uint tokedId => NftDetails)) public NftSupply;
    mapping (address => mapping (uint =>uint)) public rewardAmount;
    mapping(address => mapping(uint256 => BundleListing)) public userBundleListings;
    mapping(address => mapping(uint256 => ListLand)) public userLandListings;

    event BundleListed(uint256 bundleListingId, address seller, uint256[] tokenIds, uint256[] amounts, uint256 price);
    event BundlePurchased(uint256 bundleListingId, address buyer, uint256[] tokenIds, uint256[] amounts, uint256 price);
    event BundleListingCancelled(uint256 bundleListingId);
    event HighestBidUpdated(uint auctionListCount, address bidder, uint amount);
    event AuctionWinnerSelected(uint auctionListCount, address winner);
    event NFTClaimed(uint auctionListCount, address claimant);
     
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
    constructor(address initialOwner, IERC1155 _buildingMinting, IERC721 _landMinting,address _USDCAddress) Ownable(initialOwner) {
        buildingContract = _buildingMinting;
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

    function listBuildings(address _artist, uint256[] calldata tokenIds, uint256[] calldata amounts, uint256 price, uint256 _artistFee) external nonReentrant {
        require(price > 0, "Price must be greater than zero");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(amounts[i] > 0, "Amount must be greater than zero");
            require(buildingContract.balanceOf(msg.sender, tokenIds[i]) <= amounts[i],"Insufficeint Amount!!!");
        }

        bundleListings[nextBundleListingId.current()] = BundleListing(msg.sender, address(this), _artist, tokenIds, amounts, price, _artistFee, true);
        IERC1155(buildingContract).safeBatchTransferFrom(msg.sender,address(this),tokenIds, amounts, "");
        userBundleListings[msg.sender][nextBundleListingId.current()] = bundleListings[nextBundleListingId.current()];
        emit BundleListed(nextBundleListingId.current(), msg.sender, tokenIds, amounts, price);
        nextBundleListingId.increment(); 
        }

    function buyBuildings(uint256 bundleListingId) external payable nonReentrant {
        BundleListing storage bundleListing = bundleListings[bundleListingId];
        require(bundleListing.active, "Bundle listing is not active");
        require(msg.value >= bundleListing.price, "Insufficient funds sent");
        uint Royality = bundleListings[bundleListingId].artistFee;
        uint artistFee = (bundleListings[bundleListingId].price * Royality) / 100;
        uint sellerAmount = bundleListings[bundleListingId].price - artistFee;
        payable(bundleListings[bundleListingId].seller).transfer(sellerAmount);
        payable(bundleListings[bundleListingId].artist).transfer(artistFee);
        buildingContract.safeBatchTransferFrom(bundleListing.owner, msg.sender, bundleListing.tokenIds, bundleListing.amounts, "");
        bundleListing.active = false;
        delete userBundleListings[bundleListing.owner][bundleListingId];
        nextBundleListingId.decrement();
        emit BundlePurchased(bundleListingId, msg.sender, bundleListing.tokenIds, bundleListing.amounts, bundleListing.price);
    }

    function cancelBundleListing(uint256 bundleListingId) external {
        BundleListing storage bundleListing = bundleListings[bundleListingId];
        require(bundleListing.seller == msg.sender, "Only the seller can cancel the bundle listing");
        require(bundleListing.active, "Bundle listing is not active");
        bundleListing.active = false;
        delete userBundleListings[bundleListing.seller][bundleListingId];
        nextBundleListingId.decrement();
        emit BundleListingCancelled(bundleListingId);
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
            uint reward = months;
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

     /**
    * @dev Lists an NFT for auction on the marketplace.
    *
    * This function allows a user to list an NFT for auction by specifying the NFT's contract address, token ID,
    * minimum starting price, and artist details. It ensures that the NFT is not already listed for sale or
    * auction elsewhere in the marketplace.
    * 
    * @param _mintContract The address of the ERC1155 contract where the NFT is minted. This contract address
    *                      is used to identify and interact with the NFT.
    * @param _tokenId The unique identifier of the NFT within its minting contract. This ID is used to specify
    *                 the exact NFT being listed for auction.
    * @param _maxPrice The starting or minimum price for the auction. Bids below this price will not be accepted.
    * @param artist The address of the artist or creator of the NFT. This is used to allocate any artist fees
    *               from the sale.
    * @param artistFee The percentage of the sale price that will be paid as a fee to the artist. This fee
    *                        is calculated based on the final sale price of the NFT.
    *
    * Requirements:
    * - The NFT identified by `_tokenId` from `_mintContract` must not already be listed in the marketplace or
    *   be active in another auction.
    * 
    * The function performs the following operations:
    * 1. Validates that the NFT is not currently listed for sale or active in another auction.
    * 2. Increments the counter tracking the total number of auctions.
    * 3. Creates a new `nftAuction` struct with the provided details and marks the auction as active.
    * 4. Updates the auction listing tracking with the new auction's details.
    * 5. Sets the initial bid count for the auction to 0.
    * 6. Transfers the NFT from the seller to the marketplace contract to hold in escrow during the auction.
    *
    * This setup ensures that the NFT is securely held while the auction takes place and facilitates a seamless
    * transfer to the winning bidder at the conclusion of the auction.
    */
    function OfferList(address _mintContract, uint _tokenId, uint amount, uint _maxPrice, address artist, uint artistFee) external {
        require(buildingContract.balanceOf(msg.sender, _tokenId) <= amount, "Insufficient Amount!!!");
        require(!userBundleListings[_mintContract][_tokenId].active, "Already Listed In Marketplace!");
        require(!NftAuction[_mintContract][_tokenId].isActive, "Already Listed In Auction!");
        nftAuctionCount.increment();
        NftAuction[_mintContract][_tokenId] = Auction(msg.sender, _tokenId, amount, _maxPrice, artist, artistFee, block.timestamp + 10 minutes, true, address(0), 0);
        auctionListCount[nftAuctionCount.current()] = AddressToken(_mintContract, _tokenId, amount);
        userCount[msg.sender] = 0;
        IERC1155(buildingContract).safeTransferFrom(msg.sender, address(this), _tokenId, amount, "");
    }

    /**
    * @dev Allows users to place bids on NFTs that are listed for auction.
    *
    * Participants can bid on NFTs by specifying the auction they wish to participate in, their name,
    * and the bid amount. This function updates the auction state with the new bid details.
    *
    * @param _auctionListCount The index of the auction in the `auctionListCount` mapping, indicating
    *                          which NFT the bid is for. This index helps identify the specific auction.
    * @param _name The name of the bidder. This parameter can be used for identification or display purposes
    *              in a UI.
    * @param _price The amount of the bid placed by the user. This value must be higher than the current
    *               highest bid for the auction to be considered valid.
    *
    * Requirements:
    * - The caller (bidder) must not be the owner of the NFT. Owners cannot bid on their own NFTs.
    * - The auction for the NFT must be active. Bids cannot be placed on NFTs not listed for auction or
    *   after the auction has ended.
    * 
    * The function performs the following operations:
    * 1. Retrieves the contract address and token ID of the NFT being bid on, based on `_auctionListCount`.
    * 2. Validates that the caller is not the owner of the NFT and that the auction is active.
    * 3. Increments the count of bids placed by the user for this specific NFT.
    * 4. Records the new bid in the `Bidding` mapping, which stores all bids for each auction.
    * 5. Updates the user's bidding count and the overall list of bids for this auction.
    *
    * This setup ensures that bids are accurately tracked and associated with the correct auction and bidder.
    * It allows for a transparent bidding process where all participants can place bids until the auction
    * concludes.
    */
    function NftOffers(uint _auctionListCount, string memory _name, uint _price) external {
        address contractAddress = auctionListCount[_auctionListCount].contractAddress;
        uint tokenId = auctionListCount[_auctionListCount].tokenId;
        require(NftAuction[contractAddress][tokenId].owner != msg.sender, "You are Not Eligible for Bidding");
        require(NftAuction[contractAddress][tokenId].isActive, "Not Listed In Offers!");
        require(_price > NftAuction[contractAddress][tokenId].highestBid, "Bid must be higher than current highest bid");
        NftAuction[contractAddress][tokenId].highestBid = _price;
        NftAuction[contractAddress][tokenId].highestBidder = msg.sender;
        NftAuction[contractAddress][tokenId].endTime = block.timestamp + 10 minutes;
        Bidding[contractAddress][tokenId][userListCount[_auctionListCount] + 1] = userDetail(msg.sender, _name, _price, block.timestamp, userListCount[_auctionListCount] + 1);
        userBiddingCount[contractAddress][tokenId][msg.sender]++;
        userListCount[_auctionListCount]++;
        emit HighestBidUpdated(_auctionListCount, msg.sender, _price);
    }
    /**
    * @dev Allows the owner of an NFT listed for auction to cancel the auction.
    * This function enables auction creators to retract their listings before a sale occurs.
    *
    * @param _auctionListCount The index of the auction in the `auctionListCount` mapping. It identifies
    *                          which auction (and therefore which NFT) is being cancelled.
    *
    * Requirements:
    * - The caller must be the owner of the NFT listed for auction. This ensures that only the rightful
    *   owner can cancel the auction.
    *
    * Operation:
    * 1. Validates that the caller is the owner of the NFT.
    * 2. Transfers the NFT from the smart contract back to the owner, effectively removing it from auction.
    * 3. Marks the auction as inactive by setting its `isActive` flag to false.
    * 4. Reassigns the last auction in the list to the position of the cancelled auction, and then
    *    deletes the last entry. This step maintains a compact list of auctions.
    * 5. Decrements the overall count of auctions.
    */
    function cancelOfferList(uint _auctionListCount) external {
        require(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner == msg.sender,"Only Owner Can Cancel!!");
        buildingContract.safeTransferFrom(address(this), msg.sender, auctionListCount[_auctionListCount].tokenId,auctionListCount[_auctionListCount].amount,"");
        NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].isActive = false;
        auctionListCount[_auctionListCount] = auctionListCount[nftAuctionCount.current()];
        userListCount[_auctionListCount] = userListCount[nftAuctionCount.current()];
        delete auctionListCount[nftAuctionCount.current()];
        delete userListCount[nftAuctionCount.current()];
        nftAuctionCount.decrement();
    }
    
    function ClaimNFT(uint _auctionListCount) external payable {
        
        address contractAddress = auctionListCount[_auctionListCount].contractAddress;
        uint tokenId = auctionListCount[_auctionListCount].tokenId;
        userDetail memory selectedUser = Bidding[contractAddress][tokenId][userListCount[_auctionListCount]];
        require(selectedUser.user == msg.sender, "You are not the selected bidder");
        require(msg.value >= selectedUser.price, "Incorrect Price");
        require(NftAuction[contractAddress][tokenId].highestBidder != address(0), "Please wait...");
        uint256 artistAmount = (selectedUser.price * NftAuction[contractAddress][tokenId].artistFeePerAge) / 100;
        uint256 sellerAmount = selectedUser.price - artistAmount;
        payable(NftAuction[contractAddress][tokenId].owner).transfer(sellerAmount);
        payable(NftAuction[contractAddress][tokenId].artist).transfer(artistAmount);
        buildingContract.safeTransferFrom(address(this), msg.sender, tokenId, NftAuction[contractAddress][tokenId].amount, "");
        delete SelectedUser[_auctionListCount];
        delete auctionListCount[_auctionListCount];
        delete userListCount[_auctionListCount];
        nftAuctionCount.decrement();
        emit NFTClaimed(_auctionListCount, msg.sender);
    }
  
   function finalizeAuction(uint _auctionListCount) external {
        address contractAddress = auctionListCount[_auctionListCount].contractAddress;
        uint tokenId = auctionListCount[_auctionListCount].tokenId;
        require(NftAuction[contractAddress][tokenId].isActive, "Auction is not active");
        require(block.timestamp >= NftAuction[contractAddress][tokenId].endTime, "Auction has not ended yet");
        SelectedUser[_auctionListCount] = NftAuction[contractAddress][tokenId].highestBidder;
        NftAuction[contractAddress][tokenId].isActive = false;
        emit AuctionWinnerSelected(_auctionListCount, NftAuction[contractAddress][tokenId].highestBidder);
    }
    /**
    * @dev Retrieves the bidding history for a specific NFT listed in the marketplace.
    *
    * @param _listCount The index of the NFT in the `auctionListCount` mapping, identifying which NFT's bidding history to return.
    * @return userDetail[] An array of `userDetail` structs, each containing details of a user's bid on the NFT.
    *
    * Operation:
    * 1. Initializes an array to hold the bidding history.
    * 2. Iterates over each bid made on the NFT and adds it to the `BiddingHistory` array.
    * 3. Returns the compiled list of bids as an array of `userDetail` structs.
    */
    function getBiddingHistory(uint _listCount) external view returns(userDetail[] memory){
        address contractAddress = auctionListCount[_listCount].contractAddress;
        uint tokenId = auctionListCount[_listCount].tokenId;
        uint indexCount = 0;
        userDetail[] memory BiddingHistory = new userDetail[](userListCount[_listCount]);
        for(uint i=1; i <= userListCount[_listCount];i++){
            BiddingHistory[indexCount] = Bidding[contractAddress][tokenId][i];
            indexCount++;
        }
        return BiddingHistory;
    }
    /**
    * @dev Retrieves all NFTs currently listed in the marketplace, both for direct sale and auction.
    * @return ListTokenId[] An array of `ListTokenId` structs containing details of NFTs listed for auction.
    * Operation:
    * 1. Initializes two arrays to hold details of NFTs listed for sale and auction, respectively.
    * 2. Iterates over each listing and auction, adding their details to the respective arrays.
    * 3. Returns the two arrays, one for direct sale listings and the other for auctions.
    */
    
    function getAllListedAuctionNfts() public view returns (ListTokenId[] memory) {
         uint listNft = (nftAuctionCount.current());
        ListTokenId[] memory auctionListNFT = new ListTokenId[](listNft);
        uint listedIndexCount = 0;
        for (uint i = 1; i <= nftAuctionCount.current() ; i++) {
            if (NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].isActive) {
                auctionListNFT[listedIndexCount] = ListTokenId(NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId],i,IConnected(auctionListCount[i].contractAddress).getUserTokenUri(auctionListCount[i].tokenId));
                listedIndexCount++;
            }
        }
        return (auctionListNFT);
    }
    function getAllListedBuildings() external view returns (BundleListing[] memory) {
        uint256 totalListings = nextBundleListingId.current();
        uint256 activeCount = 0;
        for (uint256 i = 0; i < totalListings; i++) {
            if (bundleListings[i].active) {
                activeCount++;
            }
        }

        // Create an array to hold active listings
        BundleListing[] memory activeListings = new BundleListing[](activeCount);
        uint256 index = 0;

        // Populate the array with active listings
        for (uint256 i = 0; i < totalListings; i++) {
            if (bundleListings[i].active) {
                activeListings[index] = bundleListings[i];
                index++;
            }
        }

        return activeListings;
    }

    function getAllLandListedNfts() public view returns (ListedLandNftTokenId[] memory) {
        uint listNft = nextLandListId.current();
        ListedLandNftTokenId[] memory listedNFT = new ListedLandNftTokenId[](listNft);
        uint listedIndex = 0;
        for (uint i = 1; i <= nextLandListId.current() ; i++) {
            if (userLandListings[listCount[i].contractAddress][listCount[i].tokenId].listed) {
                listedNFT[listedIndex] = ListedLandNftTokenId(
                userLandListings[listCount[i].contractAddress][listCount[i].tokenId],i,
                IConnected(listCount[i].contractAddress).getTokenUri(listCount[i].tokenId));
                listedIndex++;
            }
        }
        return (listedNFT);
    }

}