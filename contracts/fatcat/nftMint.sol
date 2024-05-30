// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FatKittens is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    constructor() ERC721("MyToken", "MTK") Ownable(msg.sender)
    {

    }

    uint TokenId ;
    string uri = "FatKittens";

    function safeMint() public
    {   TokenId++;
        _safeMint(msg.sender, TokenId);
        _setTokenURI(TokenId, uri);
    }
    // address FatCats= 0xf995801Ce5A91C9f06A57FA53F3BDdc3f740adc4;
    // address FatLeopards= 0x3f2eDf9eA95b292e07876A07856BA53bc0C5E1AA;
    // address FatTigers= 0x752D6d2570a9d2961513d4E81e735dA3c49Ea24d;
    // address FatKittens= 0x10507a70B3562F4EE7Ad8824f052b146639505d4;
    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }


    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

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
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
