// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    using Counters for Counters.Counter;
    IERC721 public landContract;
    // State variables
    Counters.Counter public nftAuctionCount;       // Counter for NFTs listed for auction
    Counters.Counter public nextLandListId;       // Counter for LandNFTs listed in marketplace
    Counters.Counter public nextBundleListingId;
    constructor(address owner, IERC721 _landMinting) Ownable(msg.sender){
    landContract = _landMinting;

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

    struct auctionIndexing{
        uint tokenId;
        address contractAddress;
    }
    struct bidder{ 
        address user;
        string username;
        uint time;
        uint count;
        uint highestBid;
    }
    struct userBidCount{ 
        address userAdress;
        uint priceEntered;
    }



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

    mapping(address => mapping (uint => NFTItem)) public nftListing;
    mapping(uint =>Index) public nftIndex;

    mapping(address => mapping(uint =>Auction))public autionListing;
    mapping(uint => auctionIndexing) public auctionIndex;
    mapping(address => mapping (uint => mapping(uint=> bidder))) public auctionBidder;
    mapping(uint=>uint) public userBidCounter;

    mapping(address => uint256) public userCount;
    mapping(uint => uint) public userListCount; 
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

    event ItemCreated(uint256 indexed itemId, address indexed creator, string uri, uint256 price);
    event ItemSold(uint256 indexed itemId, address indexed buyer, uint256 price);

    // function listItem(address _mintContract, uint tokenId, string memory uri, uint256 price) public onlyOwner {
    //     _itemIds.increment();
    //     nftListing[_mintContract][tokenId]= NFTItem(tokenId, price, _itemIds.current(),msg.sender, uri, true);
    //     nftIndex[tokenId] = Index(_itemIds.current(), msg.sender);
    //     ERC721(_mintContract).transferFrom(msg.sender, address(this), tokenId); 
    //     emit ItemCreated(_itemIds.current(), msg.sender, uri, price);
    // }

    // function auctionNft(address _mintContract, uint tokenId, uint _minimumBid, uint _artistFee, address _artist) public{ 
    //     itemsAuction.increment();
    //     autionListing[_mintContract][tokenId] = Auction(tokenId, itemsAuction.current(), _minimumBid, _artistFee, block.timestamp + 100 seconds, 0,msg.sender, _artist, address(0), true);
    //     auctionIndex[tokenId] = auctionIndexing(itemsAuction.current(), _mintContract);
    //     ERC721(_mintContract).transferFrom(msg.sender, address(this), tokenId);
    // }
    // function biddingNft(uint _tokenId, string memory _username, uint _price) public { 
    //     address contractAddress = auctionIndex[_tokenId] .contractAddress;
    //     uint tokenId = auctionIndex[_tokenId] .tokenId;
    //     require(_price>=autionListing[contractAddress][tokenId].minBid,"Bid should be more that Minimum bid ");
    //     // require(autionListing[contractAddress][tokenId].isActive,"tokenId is not active yet");
    //     // require(autionListing[contractAddress][tokenId].artist != msg.sender,"artist canot bid");
    //     // require(autionListing[contractAddress][tokenId].owner != msg.sender,"owner cannot bid");
    //     autionListing[contractAddress][tokenId].highestBid = _price;
    //     autionListing[contractAddress][tokenId].highestBidder = msg.sender;
    //     userBidCounter[tokenId]++;
    //     auctionBidder[contractAddress][_tokenId][userBidCounter[tokenId]++] = bidder(msg.sender, _username, block.timestamp,userBidCounter[tokenId]++, _price);

    // }
    function OfferList(address _mintContract, uint _tokenId, uint amount, uint _maxPrice, address artist, uint artistFee) external {
        require(!userBundleListings[_mintContract][_tokenId].active, "Already Listed In Marketplace!");
        require(!NftAuction[_mintContract][_tokenId].isActive, "Already Listed In Auction!");
        nftAuctionCount.increment();
        NftAuction[_mintContract][_tokenId] = Auction(msg.sender, _tokenId, amount, _maxPrice, artist, artistFee, block.timestamp + 10 minutes, true, address(0), 0);
        auctionListCount[nftAuctionCount.current()] = AddressToken(_mintContract, _tokenId, amount);
        userCount[msg.sender] = 0;
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId);
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
    }
}