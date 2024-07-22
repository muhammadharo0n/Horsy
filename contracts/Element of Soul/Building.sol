// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @title Building
/// @author Buildings Team
/// @notice This contract implements an ERC1155 token with whitelisting, minting, and batch minting functionalities.
//hkj,

contract Building is ERC1155, Ownable {
    uint public nextTokenId;  // Variable to keep track of the next token ID.
    mapping(address => mapping(uint => bool)) public isActive;  // Maps address and token ID to activation status.
    // mapping(address => uint) public count;  // Maps address to the count of individual NFTs owned.
    mapping(address => uint) public batchCount;  // Maps address to the count of batches owned.
    mapping(address => bool) public whitelisted;  // Maps address to their whitelist status.
    
    // mapping(address => mapping(uint => id_To_nft)) public tokenDetail;  // Maps address and counter to individual NFT details.
    mapping(address => mapping(uint => BundleOfNfts)) public BundleOfNftDetail;  // Maps address and index to batch NFT details.
    mapping(address => mapping(uint => uint)) public nftId;

    /// @dev Structure to store details of a batch of NFTs.
    struct BundleOfNfts {
        address Artist;
        uint[] id;
        uint[] amount;
        string uri;
    }

    BundleOfNfts bundle;

    /**  
     * @dev Initializes the contract by setting a custom URI for all token types and transferring ownership.
     * @param initialOwner The address to be set as the initial owner of the contract.
     */
    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {
    }

    /**
     * @notice Mints a batch of new tokens with given URIs.
     * @dev Can only be called by whitelisted addresses.
     * @param to The address of the account to which the tokens will be minted.
     * @param tokenIds_Quantity The number of different token IDs to be minted.
     * @param amounts The amounts of each token to be minted.
     * @param uri The metadata URI for the batch of tokens.
     */
    function Buildings(address to, uint tokenIds_Quantity, uint256[] memory amounts, string memory uri) public {
        require(whitelisted[to], "You are not authorized!");
        require(to != address(0), "Please provide a valid address to mint Buildings!");
        uint256[] memory ids = new uint256[](tokenIds_Quantity);
        for (uint16 i = 0; i < tokenIds_Quantity; i++) {
            ids[i] = nextTokenId + i;
            nftId[msg.sender][batchCount[msg.sender] + 1] = nextTokenId;
        }
        _mintBatch(to, ids, amounts, "");
        _setURI(uri);
        BundleOfNftDetail[to][batchCount[to] + 1] = BundleOfNfts(msg.sender, ids, amounts, uri);
        nextTokenId += tokenIds_Quantity;
        batchCount[to]++;
    }

    /**
     * @notice Adds an address to the whitelist.
     * @dev Can only be called by the contract owner.
     * @param _authorized The address to be whitelisted.
     */
    function whitelist(address _authorized) public onlyOwner {
        whitelisted[_authorized] = true;
    }

    /**
     * @notice Removes an address from the whitelist.
     * @dev Can only be called by the contract owner.
     * @param _authorized The address to be removed from the whitelist.
     */
    function unwhitelist(address _authorized) public onlyOwner {
        whitelisted[_authorized] = false;
    }

    /**
     * @notice Retrieves all batch NFT details owned by a given address.
     * @param owner The address of the owner.
     * @return An array of `BundleOfNfts` structures representing the batches owned by the given address.
     */
    function getBatchNFTsDetail(address owner) public view returns (BundleOfNfts[] memory) {
        BundleOfNfts[] memory batchNFTs = new BundleOfNfts[](batchCount[owner]);
        for (uint256 i = 1; i <= batchCount[owner]; i++) {
            batchNFTs[i - 1] = BundleOfNftDetail[owner][i];
        }
        return batchNFTs;
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
    function updateTokenId(address _to, uint _tokenId, address _seller) public {
        BundleOfNfts[] memory myArray = getBatchNFTsDetail(_seller);

        for (uint i = 0; i < myArray.length; i++) {
            nftId[_to][batchCount[_to] + 1] = _tokenId;
            if (contains(myArray[i].id, _tokenId)) {
                BundleOfNftDetail[_seller][i + 1] = BundleOfNftDetail[_seller][batchCount[_seller]];
                batchCount[_seller]--;
                break;
            }
        }
        batchCount[_to]++;
    }

    /**
     * @dev Checks if an array contains a specific value.
     * @param array The array to search.
     * @param value The value to find.
     * @return A boolean indicating whether the value is found.
     */
    function contains(uint[] memory array, uint value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /*@notice Retrieves the URI of a specific token by its ID.
     @param tokenId The ID of the token whose URI is to be retrieved.
     @return The URI of the token.*/
    function getTokenUri(uint tokenId) external view returns (string memory) {
        return uri(tokenId);
    }
}
