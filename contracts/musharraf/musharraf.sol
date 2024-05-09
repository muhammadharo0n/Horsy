// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts@4.9.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.9.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.0/utils/Counters.sol";
/// @title Marketplace  for the NFTS
/// @author FatCat Team
/// @notice Contarct is based on minting the Nfts
contract Minting is ERC721URIStorage, Ownable {
   // Utility from OpenZeppelin for safely incrementing and decrementing numbers.
    using Counters for Counters.Counter;
    // A Counter to keep track of the last used token ID; ensures each token has a unique ID.
    Counters.Counter public _tokenIdCounter;
    // Struct to store an array of token IDs associated with a specific collection ID.
    struct TokenIdByCollection {
        uint256[] tokenIds;
    }
    // Struct to store metadata for each NFT minted.
    struct NFT {
        uint256 mintTime; // Timestamp of when the NFT was minted.
        address mintArtist; // Address of the artist who minted the NFT.
        uint artistFeePerAge; // A fee related to the artist, possibly a royalty or similar concept.
    }
    // Struct to encapsulate detailed information about an NFT, used for easy data retrieval.
    struct MyNft {
        uint256 tokenId; // Unique identifier for the NFT.
        uint256 mintTime; // Timestamp of the minting.
        address mintContract; // Address of the contract where the NFT was minted.
        address mintArtist; // Address of the artist who minted the NFT.
        uint artistFeePerAge; // Fee associated with the artist as per their age(?) or duration since minting.
        string uri; // URI for the NFT's metadata.
    }
    // Nested mapping to store which token IDs belong to which address, with a sequential index for enumeration.
    mapping(address => mapping(uint256 => uint256)) public TokenId;
    // Mapping to store the count of NFTs owned by each address.
    mapping(address => uint256) public count;
    // Mapping from collection IDs to their respective token IDs, facilitating collection-based operations.
    mapping(string => TokenIdByCollection) private tokenIdByCollection;
    // Mapping from token ID to its corresponding NFT metadata, for easy lookup.
    mapping (uint => NFT) public NFTMetadata;
    // Administrative address, likely used for contract management or privileged operations.
    address public adminAddress;
    // Event emitted when an NFT is successfully minted, including details like tokenId, minter, and mint time.
    event SafeMinting(uint256 tokenId, address Minter, uint MintingTime);
    // Constructor setting the initial admin address and initializing the ERC721 token with a name and symbol.
    constructor(address _adminAddress) ERC721("FATCAT", "CAT") {
        adminAddress = _adminAddress;
    }
    /**
    * @dev Allows a user to mint a new NFT.
    * @param uri The URI for the NFT metadata.
    * @param artist The address of the artist creating the NFT.
    * @param artistFeePerAge A specified fee related to the artist, potentially for royalties or similar.
    * @param collectionId The ID of the collection to which this NFT will be added.
    *
    * This function mints a new NFT to the caller's address, assigns it a unique token ID,
    * sets its metadata URI, records its minting time, artist, and artist fee, and associates it with a collection.
    * Emits a `SafeMinting` event upon successful minting.
    */
    function safeMint(string memory uri,address artist,uint artistFeePerAge,string memory collectionId) public {
        _tokenIdCounter.increment();
        TokenId[msg.sender][count[msg.sender] + 1] = _tokenIdCounter.current();
        _safeMint(msg.sender, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), uri);
        count[msg.sender]++;
        NFTMetadata[_tokenIdCounter.current()] = NFT(block.timestamp,artist,artistFeePerAge);
        tokenIdByCollection[collectionId].tokenIds.push(_tokenIdCounter.current());
        emit SafeMinting(_tokenIdCounter.current(),msg.sender,block.timestamp);
    }
    /**
    * @dev Retrieves a list of NFTs owned by a given address.
    * @param to The address to query for owned NFTs.
    * @return An array of `MyNft` structs, each representing an NFT owned by the queried address.
    *
    * This function constructs an array of `MyNft` structs containing detailed information
    * about each NFT owned by the specified address, including the token ID, mint time,
    * contract address, minting artist, artist fee, and metadata URI.
    */
    function getTokenId(address to) public view returns (MyNft[] memory) {
        MyNft[] memory myArray = new MyNft[](count[to]);
        for (uint256 i = 0; i < count[to]; i++) {
            myArray[i] = MyNft(TokenId[to][i + 1],NFTMetadata[TokenId[to][i + 1]].mintTime,address(this),NFTMetadata[TokenId[to][i + 1]].mintArtist,NFTMetadata[TokenId[to][i + 1]].artistFeePerAge,tokenURI(TokenId[to][i + 1]));
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
        TokenId[_to][count[_to] + 1] = _tokenId;
        MyNft[] memory myArray =  getTokenId(_seller);
        for(uint i=0 ; i < myArray.length ; i++){
            if(myArray[i].tokenId == _tokenId){
                TokenId[_seller][i+1] = TokenId[_seller][count[_seller]];
                count[_seller]--;
            }
        }
        count[_to]++;
    }
    /**
    * @dev Updates the mint time of a specific token ID to the current block timestamp.
    * @param _tokenId The token ID for which to update the mint time.
    *
    * This could be used to refresh or update the timestamp associated with an NFT,
    * potentially for mechanisms that depend on the age or recency of minting.
    */
    function update_TokenIdTime(uint _tokenId) external {
        NFTMetadata[_tokenId].mintTime = block.timestamp;
    }
    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override
    {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        updateTokenId(to,tokenId,from);
        super.safeTransferFrom(from, to, tokenId);
    }
    /**
    * @dev Retrieves all NFTs associated with a given collection ID.
    * @param collectionId The ID of the collection for which to retrieve NFTs.
    * @return An array of `MyNft` structs, each representing an NFT in the specified collection.
    *
    * This function iterates through all token IDs associated with the given collection ID,
    * constructing an array of `MyNft` structs that includes detailed information about each NFT,
    * such as token ID, mint time, the contract address, the minting artist, artist fee, and the token's metadata URI.
    */
    function getTokenIdsByCollection(string memory collectionId)
        public
        view
        returns (MyNft[] memory)
    {
        uint256[] memory tokenIds = tokenIdByCollection[collectionId].tokenIds;
        MyNft[] memory myArray = new MyNft[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 currentTokenId = tokenIds[i];
            myArray[i] = MyNft(currentTokenId,NFTMetadata[currentTokenId].mintTime,address(this),NFTMetadata[currentTokenId].mintArtist,NFTMetadata[currentTokenId].artistFeePerAge,tokenURI(currentTokenId));
        }
        return myArray;
    }
    /**
    * @dev Returns the contract's current balance.
    * @return The balance of the contract in wei.
    *
    * This function queries the contract's balance, allowing visibility into the amount of Ether held by the contract.
    */
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    /**
    * @dev Allows the current admin to transfer admin rights to a new address.
    * @param _adminAddress The address to be granted admin rights.
    *
    * This function updates the admin address of the contract. It includes a security check to ensure
    * that only the current admin can perform this operation, enhancing the contract's security by preventing
    * unauthorized changes to administrative privileges.
    */
    function setAdminAddress(address _adminAddress) external {
        require(adminAddress==msg.sender,"You are not Admin");
        adminAddress = _adminAddress;
    }
    /**
    * @dev Retrieves the metadata URI for a specific token ID.
    * @param tokenId The token ID for which to retrieve the metadata URI.
    * @return The URI string of the requested token's metadata.
    *
    * This function provides a way to access the metadata URI associated with a given token ID,
    * allowing external entities and interfaces to retrieve the metadata for display or processing purposes.
    */
    function getTokenUri(uint tokenId) external view returns(string memory){
        return tokenURI(tokenId);
    }
        // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}