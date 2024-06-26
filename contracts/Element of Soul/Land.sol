// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

// Import OpenZeppelin's ERC721 standard implementation and its extensions.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// @title LandMinting
// @author LandMinting Team
// @notice This contract implements an ERC721 token with whitelisting and metadata storage functionalities.
contract LandMinting is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;  // Use Counters library from OpenZeppelin.
    Counters.Counter private _itemsId;  // Private counter to track token IDs.

    // Structure to store NFT information.
    struct NFT { 
        uint256 tokenId;    
        uint256 count;
        string uri;
        uint mintTime;        
        bool minted;
    }

    // Mappings to store various data related to NFTs and their owners.
    mapping(address => mapping(uint => uint)) public NftId;  // Maps address to a mapping of an index to a token ID.
    mapping(address => uint) public count;  // Maps address to the number of NFTs they own.
    mapping(uint => NFT) public NftMinting;  // Maps token ID to the NFT structure.
    mapping(address => bool) public whitelisted;  // Maps address to their whitelist status.

    // @dev Initializes the contract by setting a custom token name and symbol, and transferring ownership.
    // @param initialOwner The address to be set as the initial owner of the contract.
    constructor(address initialOwner) ERC721("Lands", "Land") Ownable(initialOwner) {
    }

    /*@notice Adds an address to the whitelist.
     @dev Can only be called by the contract owner.
     @param _authorized The address to be whitelisted.*/
    function whitelist(address _authorized) public onlyOwner {
        whitelisted[_authorized] = true;
    }

    /*@notice Removes an address from the whitelist.
    *@dev Can only be called by the contract owner.
    *@param _authorized The address to be removed from the whitelist.*/
    function unwhitelist(address _authorized) public onlyOwner {
        whitelisted[_authorized] = false;
    }

    /*@notice Mints a new token with a given URI.
    * @dev Can only be called by whitelisted addresses.
    * @param uri The metadata URI of the token to be minted.*/
    function safeMint(string memory uri) public {
        require(whitelisted[msg.sender], "You are not authorized for minting land!!");
        _itemsId.increment();  
        uint256 newItemId = _itemsId.current();  
        NftId[msg.sender][count[msg.sender] + 1] = newItemId;
        NftMinting[newItemId] = NFT(newItemId, count[msg.sender] + 1, uri, block.timestamp, true);
        _safeMint(msg.sender, newItemId);  
        _setTokenURI(newItemId, uri); 
        count[msg.sender]++; 
    }

    /* @notice Retrieves all tokens owned by the caller.
     @return An array of NFTs owned by the caller.*/
    function getTokenId(address _seller) public view returns(NFT[] memory) {
        NFT[] memory myArray = new NFT[](count[_seller]);  
        for (uint i = 0; i < count[_seller]; i++) { 
            uint tokenId = NftId[_seller][i + 1];
            myArray[i] = NftMinting[tokenId]; 
        }
        return myArray;
    }


    /**
    * @dev Transfers a token ID from one owner to another and updates internal tracking.
    * @param _to The address to receive the token ID.
    * @param _tokenId The token ID to be transferred.
    * @param _seller The current owner of the token ID.
    *
    * This function updates the internal mapping of token IDs to reflect a change in ownership.
    * It also adjusts the count of NFTs owned by both the seller and the buyer.
    * Note: This function does not perform the actual transfer of tokens but is intended to be called
    * in conjunction with a transfer function that handles ownership change.
    */
    function updateTokenId(address _to,uint _tokenId,address _seller) public {
        NftId[_to][count[_to] + 1] = _tokenId;
        NFT[] memory myArray =  getTokenId(_seller);
        for(uint i=0 ; i < myArray.length ; i++){
            if(myArray[i].tokenId == _tokenId){
                NftId[_seller][i+1] = NftId[_seller][count[_seller]];
                count[_seller]--;
            }
        }
        count[_to]++;
    }

    /*@notice Retrieves the URI of a specific token by its ID.
     @param tokenId The ID of the token whose URI is to be retrieved.
     @return The URI of the token.*/
    function getTokenUri(uint tokenId) external view returns(string memory) {
        return tokenURI(tokenId);
    }

    /*@dev Override the tokenURI function from ERC721 and ERC721URIStorage to provide token URI.
     @param tokenId The ID of the token whose URI is to be retrieved.
     @return The URI of the token.*/
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /* @dev Override the supportsInterface function from ERC721 and ERC721URIStorage to indicate support for interfaces.
     @param interfaceId The ID of the interface to be checked.
     @return A boolean indicating whether the interface is supported.*/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
