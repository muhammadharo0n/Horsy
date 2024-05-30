// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface GetBalance { 
    function balanceOf(address _addrr) external view returns (uint tokenId);
}

interface IConnected {
    // Struct to encapsulate detailed information about an NFT, used for easy data retrieval.
    struct NFT{ 
        uint256 tokenId;    
        uint256 price;
        uint256 count;
        bool minted;
        address artist;
        string uri;
        uint mintTime;
    }


    // Functions to be implemented by connected contracts for updating and retrieving NFT data
    function updateTokenId(address _to,uint _tokenId,address seller) external;
    // function update_TokenIdTime(uint _tokenId) external;
    function getTokenId(address _address) external view returns(NFT [] memory);
    function getTokenUri(uint _tokenId) external view returns(string memory);

}
contract NFTMarketplace is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    uint totalVolume;
    uint artistFeePerAge;
    uint sellerFeePerAge;
    uint buyerFeePerAge;
    uint256 soldCount;
    address FatCats= 0x5F31f088c0d692FF133bd3b11b923F4E1bE99E9B;
    address FatLeopards= 0xE2CBAdc3250Dc901596E1cDFFA778fc313162247;
    address FatTigers= 0x572dD734F1068C1EDa13E0b655BC227b31AD8f72;
    address FatKittens= 0xE533f399513F8Ed44D7E12E458d532Fe7005CF4e;

        constructor(address owner) Ownable(msg.sender){
    memberShipPer[memberShip.Gold] = 0;
    memberShipPer[memberShip.Silver] = 3;
    memberShipPer[memberShip.Bronze] = 4;
    memberShipPer[memberShip.Standard] = 5;
    owner = msg.sender;


    }


    enum memberShip{Gold, Silver, Bronze, Standard}


    struct NFTlist {
        uint256 tokenId;    
        address seller;
        address owner;
        uint256 price;
        uint256 count;
        bool listed;
        address artist;
        uint artistFeePerAge;
        uint sellerFeePerAge;
        uint buyerFeePerAge;

    }
    struct tokenAddress{ 
        address contractAddress;
        uint TokenId;
    }
    struct VolumeData{
        uint _price;
        uint _time;
    }
    struct commissionData{
       uint totalCommission;
       uint timestamp; 
    }

    mapping (memberShip => uint) public memberShipPer;
    
    // Similar to `ListTokenId` but specifically for NFTs listed for direct sale.
    struct ListedNftTokenId {
        NFTlist listedData;          // The direct sale listing data for the NFT.
        uint Index;          // A count or ID similar to `ListTokenId`.
        string uriData;          // URI for the NFT metadata.
    }
    mapping(address mintContractAddress=> mapping (uint256 => NFTlist)) public _items;
    mapping(uint => tokenAddress) public Index;
    mapping(uint => VolumeData) public Volume; 
    mapping(uint => commissionData) public commission;
    mapping(uint => uint) public Sales;


    event ItemCreated(uint256 indexed itemId, address indexed creator, string uri, uint256 price);
    event ItemSold(uint256 indexed itemId, address indexed buyer, uint256 price);
        // Emitted when an NFT is listed for sale.
    event NFTListed(uint256 tokenId, address seller, address owner, uint256 price);

    // Emitted when an NFT is sold.
    event NFTSold(uint256 tokenId, address seller, address owner, uint256 price, uint SoldTime);
        // Emitted when fees are paid to an artist.
    event Fee(address ArtistAddress, uint ArtistFee);
        // Emitted when NFT list get Cancle
    event NFTCancel(uint256 tokenId, address seller, address owner, uint256 price);


    function listItem( address mintContract , uint _tokenId, string memory uri, uint256 price, address artist) public {
        _itemIds.increment();
        _itemIds.current();
        _items[mintContract][_tokenId]= NFTlist( _tokenId,msg.sender,address(this), price,_items[mintContract][_tokenId].count ,true , artist ,artistFeePerAge,sellerFeePerAge,buyerFeePerAge);
        Index[_itemIds.current()] = tokenAddress(mintContract,_tokenId );
        ERC721(mintContract).transferFrom(msg.sender,address(this),_tokenId);
        Volume[totalVolume] = VolumeData(price , block.timestamp);
        totalVolume++;
        emit ItemCreated(_itemIds.current(), msg.sender, uri, price);
    }


    function Buy(uint listIndex, memberShip choice) public payable { 
        address contractAddress = Index[listIndex].contractAddress;
        uint tokenId = Index[listIndex].TokenId;
        uint memberPerAgeCal= (_items[contractAddress][tokenId].price * memberShipPer[choice]) / 100 ;
        require(_items[contractAddress][tokenId].seller != msg.sender, "Not the Seller");
        require(msg.value >=  (_items[contractAddress][tokenId].price + memberPerAgeCal), "Not enough price");
        ERC721(contractAddress).transferFrom(address(this),msg.sender,tokenId);
        // IConnected(Index[listIndex].contractAddress).updateTokenId(msg.sender,_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].tokenId,_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].seller);
            if(_items[contractAddress][tokenId].count == 0){
                _items[contractAddress][tokenId].artist =_items[contractAddress][tokenId].seller;
                _items[contractAddress][tokenId].artistFeePerAge = 85;
                _items[contractAddress][tokenId].buyerFeePerAge= 15;


            }
            if(_items[contractAddress][tokenId].count > 0){ 
                _items[contractAddress][tokenId].artistFeePerAge = 5;
                _items[contractAddress][tokenId].sellerFeePerAge=95;
                _items[contractAddress][tokenId].buyerFeePerAge= 5;
            }
        
        uint buyerFeeCul =  (_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].price * buyerFeePerAge) / 1000;
        uint sellerFeeCul = (_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].price * sellerFeePerAge) / 1000;
        uint artistFeePer = _items[Index[listIndex].contractAddress][Index[listIndex].TokenId].artistFeePerAge;
        uint artistFee = (_items[contractAddress][tokenId].price * artistFeePer) / 100;
        uint sellerAmount = _items[contractAddress][tokenId].price - (artistFee + buyerFeeCul + sellerFeeCul);

        payable(_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].seller).transfer(sellerAmount);
        payable (_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].artist).transfer(artistFee);
        payable(owner()).transfer(buyerFeeCul);
        payable(owner()).transfer(memberPerAgeCal);

       _items[contractAddress][tokenId].listed = false;
        // IConnected(Index[listIndex].contractAddress);
        _items[contractAddress][tokenId].count++;

        Index[listIndex]= Index[_itemIds.current()];
        _itemIds.decrement();
        emit Fee(_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].artist,_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].artistFeePerAge);
        emit NFTSold(_items[contractAddress][tokenId].tokenId ,
        _items[contractAddress][tokenId].seller,
        msg.sender, sellerAmount, block.timestamp);
    }

    function checkBalanceOf (address userAddrr) public view returns ( 
    bool isGoldMember, bool isSilverMember, bool isBronzeMember, bool isStandardMember){ 
        
        uint tokenIdOne = GetBalance(FatCats).balanceOf(userAddrr);
        uint tokenIdTwo = GetBalance(FatLeopards).balanceOf(userAddrr);
        uint tokenIdThree = GetBalance(FatTigers).balanceOf(userAddrr);
        uint tokenIdFour = GetBalance(FatKittens).balanceOf(userAddrr);
        
        if (tokenIdOne > 0 && tokenIdTwo > 0 && tokenIdThree > 0 && tokenIdFour > 0) {
            return ( true, true, true, true);
        } else if (tokenIdTwo > 0 && tokenIdThree > 0 && tokenIdFour > 0) {
            return ( false, true, true, true);
        } else if (tokenIdThree > 0 && tokenIdFour > 0) {
            return ( false, false, true, true);
        } else if (tokenIdFour > 0) {
            return ( false, false, false, true);
        }
    }


    function editList(uint listIndex, uint price) public { 
        require(_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].listed,"This Item not listed ");
        require(_items[Index[listIndex].contractAddress][Index[listIndex].TokenId ].seller == msg.sender,"You are not Owner");
        _items[Index[listIndex].contractAddress][Index[listIndex].TokenId].price = price;
    }

    function CancleListForSale(uint listIndex) public { 
        require(_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].listed,"This Item not listed ");
        _items[Index[listIndex].contractAddress][Index[listIndex].TokenId].owner =_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].seller;
        ERC721(Index[listIndex].contractAddress).transferFrom(address(this),_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].seller,Index[listIndex].TokenId);
        _items[Index[listIndex].contractAddress][Index[listIndex].TokenId].listed = false;
        _items[Index[listIndex].contractAddress][Index[listIndex].TokenId].count = listIndex;
        Index[listIndex] = Index[_itemIds.current()];
        _itemIds.decrement();
        emit NFTCancel(_items[Index[listIndex].contractAddress][Index[listIndex].TokenId].tokenId,
        _items[Index[listIndex].contractAddress][Index[listIndex].TokenId].seller,
        msg.sender,
        _items[Index[listIndex].contractAddress][Index[listIndex].TokenId].price);
    }

    function getAllListedNfts() public view returns (ListedNftTokenId[] memory) { 
    uint listNftCount = 0;
    ListedNftTokenId[] memory getNFTtokenid = new ListedNftTokenId[](_itemIds.current());
    
    for (uint i = 1; i <= _itemIds.current(); i++) { 
        if (_items[Index[i].contractAddress][Index[i].TokenId].listed) {
            getNFTtokenid[listNftCount] = ListedNftTokenId(_items[Index[i].contractAddress][Index[i].TokenId],i,IConnected(Index[i].contractAddress).getTokenUri(Index[i].TokenId));
            listNftCount++;
        }
    }
    return getNFTtokenid;
    }

}