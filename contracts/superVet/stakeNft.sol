// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Marketplace is Ownable{
        
    using SafeERC20 for IERC20;
    uint256 public _nextTokenId;
    uint public _nftStakeId;
    uint tokenAddress;
    uint startTime;
    uint endTime;

    constructor (address initialOwner) Ownable(initialOwner) { 

        // mintContract= _tokenAddress;
        // dividnd = _dividnd;


    }
    struct NftStaking{ 
        uint tokenId;
        uint startTime;
        address stakedAddress;
        bool staked;
    }
    struct stakingNftIndex{ 
        uint tokenId;
        address mintContract;
    }   

    mapping(address  => NftStaking) public stakeListing;
    mapping(uint => stakingNftIndex) public stakingIndex;

    function tokenDeposit(uint amount, address _tokenAddress) public onlyOwner{ 
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
    }
    function stakeNft( uint _tokenId, address contractAddress) public { 
        
        _nftStakeId++;
        stakeListing[msg.sender] = NftStaking(_tokenId, block.timestamp, contractAddress, true);
        ERC721(contractAddress).transferFrom(msg.sender,address(this), _tokenId);
        stakingIndex[_nftStakeId] = stakingNftIndex(_tokenId, contractAddress);
   
    }
    function unStake(uint _tokenId, address contractAddress) public { 
        require(stakeListing[msg.sender].staked);
        _nftStakeId--;
        ERC721(contractAddress).transferFrom(msg.sender,address(this), _tokenId);
        stakingIndex[_nftStakeId] = stakingNftIndex(_tokenId, contractAddress);
    }
    function timePeriod( uint _startTime, uint _endTime) public { 
        startTime = _startTime;
        endTime = _endTime;
    }

    function checkReward (uint _tokenId, address userAddress) public  returns (uint reward, uint month) { 
        
    }

    function getReward(uint _tokenId, address userAddress) public { 
        require(stakeListing[msg.sender].staked = true,"There is no Nft to get Reward");
    }
}