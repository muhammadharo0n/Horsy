// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Marketplace is Ownable{
        uint256 private _nextTokenId;
        using SafeERC20 for IERC20;

    constructor (address initialOwner) Ownable(initialOwner) { 
        _nextTokenId = 1;
        // mintContract= _tokenAddress;
        // dividnd = _dividnd;


    }
        
    struct Tokens{
        uint quantity;
        uint price;
        address to;
        address seller;
        address mintContract;
    }
    mapping  (uint => Tokens ) public tokenListing;


    function listTokens (uint _quantity, uint _price, address _mintContract) public onlyOwner{ 
        tokenListing[_nextTokenId] = Tokens(_quantity, _price, address(this), msg.sender, _mintContract);
        IERC20(_mintContract).safeTransferFrom(msg.sender, address(this), _quantity);
        _nextTokenId++;
    }

} 