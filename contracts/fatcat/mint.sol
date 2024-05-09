// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    uint256 private _nextTokenId;
    uint256 public startTime;
    uint256 public currentTime;
    uint public mintDuration = 10 seconds;
    uint public bronzefee = 3;
    uint public goldfee = 1;
    uint public silverfee = 2;
    uint public standardfee = 4;

    uint public goldMintDuration = 5 minutes;
    uint public silverMintDuration = 1 minutes;
    uint public bronzeMintDuration = 1 minutes;

    // uint256 private _goldStartTime;
    // uint256 private _silverStartTime;
    // uint256 private _bronzeStartTime;

    struct NFT{ 
        uint256 tokenId;    
        uint256 price;
        uint256 count;
        bool minted;
        address artist;
        string uri;
        uint mintTime;
    }

    mapping(uint=>NFT) public minting;
    mapping(address => mapping(uint256 => uint256)) public TokenId;
    mapping(address => uint256) public count;
    mapping(address=>bool) public whitelist;
    mapping(address=>bool) public bronze;
    mapping(address=>bool) public gold;
    mapping(address=>bool) public silver;
    mapping(address=>bool) public standard;

    
    event SafeMinting(uint256 tokenId, address Minter, uint MintingTime);


        constructor(address initialOwner)
            ERC721("MyToken", "MTK")
            Ownable(initialOwner)
    {}
        function bronzelisting(address[] calldata addrr) public { 
        for(uint i; i<addrr.length; i++){ 
           bronze[addrr[i]] = true; 
        }
    }
        function silverlisting(address[] calldata addrr) public { 
        for(uint i; i<addrr.length; i++){ 
           silver[addrr[i]] = true; 
        }
    }   function goldlisting(address[] calldata addrr) public { 
        for(uint i; i<addrr.length; i++){ 
           gold[addrr[i]] = true; 
        }
    }   function whitelisting(address[] calldata addrr) public { 
        for(uint i; i<addrr.length; i++){ 
           whitelist[addrr[i]] = true; 
        }
    }
        function standardlisting(address[] calldata addrr) public { 
        for(uint i; i<addrr.length; i++){ 
           standard[addrr[i]] = true; 
        }
    }
        function StartMinting(uint _startTime ) public {
            require(_startTime>block.timestamp,"Time should be now or Future");
            startTime  = _startTime ;
            currentTime = block.timestamp;

        }
    modifier canMintNFT(){ 
        require(whitelist[msg.sender],"This user is not approved");
        uint timeToMint;
        if(gold[msg.sender]){ 
            require(!silver[msg.sender] , "Goldmember ");
            require(!bronze[msg.sender], "Only for Gold members ");
            require(startTime > 0, "Start time not set");
            require(block.timestamp > startTime, "Cannot mint right now ");
        }
        if(silver[msg.sender]){ 
            require(startTime > 0, "Start time not set");
            require(block.timestamp > startTime + goldMintDuration, "Cannot mint silver right now ");
            require(!gold[msg.sender] , "Only for Gold members ");
            require(!bronze[msg.sender], "Only for Gold members ");
        }
        if(bronze[msg.sender]){ 
            require(block.timestamp > startTime + bronzeMintDuration, "Cannot mint bronze right now ");
            require(startTime > 0, "Start time not set");
            require(!gold[msg.sender] , "Only for Gold members ");
            require(!silver[msg.sender], "Only for Gold members ");
        
         }
    _;
    }

    function safeMint(string memory uri) public payable canMintNFT{
        require(whitelist[msg.sender], "This user is not approved");
        require(msg.value > 0, "Please provide a non-zero amount");
        uint taxfee;
        _itemIds.increment();
        _itemIds.current();
        _nextTokenId= _itemIds.current();
        TokenId[msg.sender][count[msg.sender]++] = _nextTokenId;
        count[msg.sender]++;

        if (bronze[msg.sender]){ 
            taxfee = bronzefee;
        } else if (gold[msg.sender]){ 
            taxfee = goldfee;
        }else if(silver[msg.sender]){ 
            taxfee = silverfee;
        }else{ 
            taxfee = standardfee;
        }
        uint taxAmount = (msg.value*taxfee)/100;
        
        // Transfer of Amount to Owner
        payable(owner()).transfer(taxAmount);

        // Mint Function 
        _safeMint(msg.sender, _nextTokenId);
        _setTokenURI(_nextTokenId, uri);
        minting[_nextTokenId] =NFT(_nextTokenId , taxAmount , _itemIds.current() , true , msg.sender, uri,block.timestamp);
        emit SafeMinting(_nextTokenId,msg.sender,block.timestamp);


    }

    function getTokenId(address to) public view returns (NFT[] memory) { 
    NFT[] memory myArray = new NFT[](count[to]);
    for (uint i = 0; i < count[to]; i++) { 
        // Initialize each NFT struct with the required arguments
        myArray[i] = NFT(
            TokenId[to][i + 1], // tokenId
            minting[TokenId[to][i + 1]].price, 
            minting[TokenId[to][i + 1]].count,
            minting[TokenId[to][i + 1]].minted, 
            minting[TokenId[to][i + 1]].artist, 
            minting[TokenId[to][i + 1]].uri,
            minting[TokenId[to][i + 1]].mintTime
        );
    }
    return myArray;
}
    function updateTokenId(address _to,uint _tokenId,address _seller) external {
        TokenId[_to][count[_to] + 1] = _tokenId;
        NFT[] memory myArray = getTokenId(_seller);
        for(uint i=0 ; i < myArray.length ; i++){
            if(myArray[i].tokenId == _tokenId){
                TokenId[_seller][i+1] = TokenId[_seller][count[_seller]];
                count[_seller]--;
            }
        }
        count[_to]++;
    }
    
    
    function getTokenUri(uint tokenId) external view returns(string memory){
        return tokenURI(tokenId);
    }

    // function update_TokenIdTime(uint _tokenId) external view {
    //     minting[_tokenId].mintTime = block.timestamp;
    // }


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
