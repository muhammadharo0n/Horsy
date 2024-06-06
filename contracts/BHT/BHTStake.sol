// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Linking is Ownable {

    using SafeERC20 for IERC20;

    uint public totalLockedNft;
    address public immutable tokenAddress;
    uint public dividnd;
    uint public startTime;
    uint public endTime;
    uint256 public rewardRate = 100;


    struct NftDetails{ 
        uint TokenId;
        address stakerAddress; 
        address currentOwnerAddress; 
        uint userWithdrwaToken;
        uint withdrawMonth;
        uint stakeTime;
        uint endTime;
        bool isActive;
    }
    mapping (address mintAddress => mapping (uint tokedId => NftDetails)) public NftSupply;
    mapping (address => mapping (uint =>uint)) public rewardAmount;

    constructor (address initialOwner, address _tokenAddress) Ownable(initialOwner) { 
        tokenAddress= _tokenAddress;
        // dividnd = _dividnd;


    }

    // function timePeriod(uint _startTime, uint _endTime) public { 
    //     startTime = block.timestamp;
    //     endTime = 1815585444;
    // }

    function stakeNft(address mintAddress, address _stakerAddress, uint tokenId ) public {
        
        // require(NftSupply[mintAddress][tokenId].stakerAddress == _stakerAddress,"You are not Owner");
        // require(startTime < block.timestamp, "Time cannot be started");
        // require(endTime > block.timestamp, "End time is not Correct");
        // require(!NftSupply[mintAddress][tokenId].isActive,"NFT already staked");
        NftSupply[mintAddress][tokenId] = NftDetails(tokenId, _stakerAddress, address(this), 0, 0, block.timestamp, block.timestamp+100 seconds, true);
        rewardAmount[_stakerAddress][tokenId] = NftSupply[mintAddress][tokenId].stakeTime ;
        startTime =  NftSupply[mintAddress][tokenId].stakeTime ;
        totalLockedNft++;
        ERC721(mintAddress).transferFrom(_stakerAddress, address(this), tokenId);
    }

   function unStakeNft(address mintAddress, address _stakerAddress, uint tokenId) public{

        require(NftSupply [mintAddress][tokenId].isActive , "Nft is not Staked in List");
        require(NftSupply[mintAddress][tokenId].stakerAddress == _stakerAddress, "You are not the owner");
        totalLockedNft--;
        NftSupply[mintAddress][tokenId].isActive = false;
        ERC721(mintAddress).transferFrom(address(this), _stakerAddress, tokenId);  
   }

    function checkReward(address mintAddress, uint tokenId) public view returns (uint reward,uint month){

        month = (block.timestamp - (NftSupply[mintAddress][tokenId].stakeTime + (NftSupply[mintAddress][tokenId].withdrawMonth*1 minutes)))/ 1 minutes;
        reward  = (rewardRate*(tokenAddress * month))/1 minutes;
        return(reward , month);
    }
    function claimReward (address mintAddress, address adminAddress, uint tokenId) public{
        (uint reward, uint month) = checkReward(mintAddress , NftSupply[mintAddress][tokenId].TokenId);
        NftSupply[mintAddress][tokenId].withdrawMonth += month;
        NftSupply[mintAddress][tokenId].userWithdrwaToken += (month*reward);
        IERC20(tokenAddress).safeTransfer(adminAddress,(month*reward));
    }

    function adminDepositToken(address adminAddress, uint tokenDeposit) public onlyOwner{ 
        IERC20(tokenAddress).safeTransferFrom(adminAddress, address(this), tokenDeposit);
   }
//       function adminWithdrawToken(address adminAddress, uint tokenDeposit) public onlyOwner{ 
//         IERC20(tokenAddress).safeTransferFrom( address(this), adminAddress, tokenDeposit);
//    }
 
}