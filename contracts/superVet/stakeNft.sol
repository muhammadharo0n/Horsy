// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    IERC721 public landContract;
    address public immutable tokenAddress;
    uint public totalLockedNft;
    uint public startTime;
    uint public endTime;

    struct NftDetails { 
        uint TokenId;
        address stakerAddress; 
        address currentOwnerAddress; 
        uint userWithdrawToken;
        uint withdrawMonth;
        uint stakeTime;
        bool isActive;
    }

    mapping(uint => NftDetails) public lockedNFT;

    modifier lockConditions(uint tokenId) {
        require(startTime != endTime, "Please wait...");
        require(startTime < block.timestamp, "Time Not Start...");
        require(endTime > block.timestamp, "Time End.");
        require(!lockedNFT[tokenId].isActive, "Already Staked");
        _;
    }

    modifier unlockConditions(uint tokenId, address stakerAddress) {
        require(endTime < block.timestamp, "Please wait...");
        require(lockedNFT[tokenId].stakerAddress == stakerAddress, "You are not owner of this NFT.");
        require(lockedNFT[tokenId].isActive, "NOT LOCKED.");
        _;
    }

    constructor(address initialOwner, IERC721 _landMinting, address _USDCAddress) Ownable(initialOwner) {
        landContract = _landMinting;
        tokenAddress = _USDCAddress;
    }

    function stakingPeriod(uint start, uint end) public onlyOwner {
        startTime = start;
        endTime = end;
    }

    function stakeNFT(address mintContract, address stakerAddress, uint tokenId) public lockConditions(tokenId) {
        lockedNFT[tokenId] = NftDetails(tokenId, stakerAddress, address(this), 0, 0, block.timestamp, true);
        totalLockedNft++;
        ERC721(mintContract).transferFrom(stakerAddress, address(this), tokenId);
    }

    function unStakeNFT(address mintContract, address stakerAddress, uint tokenId) public unlockConditions(tokenId, stakerAddress) {
        lockedNFT[tokenId].isActive = false;
        totalLockedNft--;
        ERC721(mintContract).transferFrom(address(this), stakerAddress, tokenId);
    }

    function userClaimFT(address userAddress, uint tokenId) public {
        (uint reward, uint month) = user_Staking_Rewards(tokenId);
        require(month != 0, "Please wait...");
        require(lockedNFT[tokenId].withdrawMonth != 12, "You have claimed your all rewards according to this NFT...");

        if (lockedNFT[tokenId].withdrawMonth + month < 12) {
            lockedNFT[tokenId].withdrawMonth += month;
            lockedNFT[tokenId].userWithdrawToken += (reward * month);
            IERC20(tokenAddress).safeTransfer(userAddress, (reward * month));
        } else {
            uint remainingMonth = (12 - lockedNFT[tokenId].withdrawMonth);
            lockedNFT[tokenId].withdrawMonth += remainingMonth;
            lockedNFT[tokenId].userWithdrawToken += (reward * remainingMonth);
            IERC20(tokenAddress).safeTransfer(userAddress, (reward * remainingMonth));
        }
    }

    function user_Staking_Rewards(uint tokenId) public view returns (uint rewards, uint month) {
        if (((block.timestamp - endTime) - (lockedNFT[tokenId].withdrawMonth * 60)) >= 60) {
            uint months = ((block.timestamp - endTime) - (lockedNFT[tokenId].withdrawMonth * 60)) / 60;
            uint reward = (1 * months);
            return (reward, months);
        } else {
            return (0,0);
        }
    }

    function adminDepositToken(address adminAddress, uint tokenDeposit) public onlyOwner { 
        IERC20(tokenAddress).safeTransferFrom(adminAddress, address(this), tokenDeposit);
    }

    function adminWithdrawToken(address adminAddress, uint tokenDeposit) public onlyOwner { 
        IERC20(tokenAddress).safeTransferFrom(address(this), adminAddress, tokenDeposit);
    }
}