// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC721 public landContract; // The ERC721 contract for the staked NFTs
    address public immutable tokenAddress; // Address of the ERC20 token used for rewards
    uint public totalLockedNft; // Total number of locked NFTs
    uint public startTime; // Start time for staking period
    uint public endTime; // End time for staking period

    struct NftDetails {
        uint TokenId; // Token ID of the staked NFT
        address stakerAddress; // Address of the staker
        address currentOwnerAddress; // Current owner of the NFT
        uint userWithdrawToken; // Amount of tokens withdrawn by the user
        uint withdrawMonth; // Number of months the rewards have been withdrawn for
        uint stakeTime; // Timestamp when the NFT was staked
        bool isActive; // Whether the NFT is currently staked
    }

    mapping(uint => NftDetails) public lockedNFT; // Mapping of token ID to NFT details

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

    /**
     * @dev Constructor to set initial values and addresses.
     * @param initialOwner Address of the initial owner of the contract.
     * @param _landMinting Address of the ERC721 contract.
     * @param _USDCAddress Address of the ERC20 token contract.
     */
    constructor(address initialOwner, IERC721 _landMinting, address _USDCAddress) Ownable(initialOwner) {
        landContract = _landMinting;
        tokenAddress = _USDCAddress;
    }

    /**
     * @dev Sets the staking period start and end times.
     * @param start The start time for staking.
     * @param end The end time for staking.
     */
    function stakingPeriod(uint start, uint end) public onlyOwner {
        startTime = start;
        endTime = end;
    }

    /**
     * @dev Stakes an NFT in the contract.
     * @param mintContract Address of the NFT contract.
     * @param stakerAddress Address of the staker.
     * @param tokenId Token ID of the NFT to stake.
     */
    function stakeNFT(address mintContract, address stakerAddress, uint tokenId) public lockConditions(tokenId) {
        lockedNFT[tokenId] = NftDetails(tokenId, stakerAddress, address(this), 0, 0, block.timestamp, true);
        totalLockedNft++;
        ERC721(mintContract).transferFrom(stakerAddress, address(this), tokenId);
    }

    /**
     * @dev Unstakes an NFT from the contract.
     * @param mintContract Address of the NFT contract.
     * @param stakerAddress Address of the staker.
     * @param tokenId Token ID of the NFT to unstake.
     */
    function unStakeNFT(address mintContract, address stakerAddress, uint tokenId) public unlockConditions(tokenId, stakerAddress) {
        lockedNFT[tokenId].isActive = false;
        totalLockedNft--;
        ERC721(mintContract).transferFrom(address(this), stakerAddress, tokenId);
    }

    /**
     * @dev Allows a user to claim their staking rewards.
     * @param userAddress Address of the user claiming rewards.
     * @param tokenId Token ID of the staked NFT.
     */
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

    /**
     * @dev Calculates the rewards for staking.
     * @param tokenId Token ID of the staked NFT.
     * @return rewards The calculated rewards.
     * @return month The number of months for which rewards are calculated.
     */
    function user_Staking_Rewards(uint tokenId) public view returns (uint rewards, uint month) {
        if (((block.timestamp - endTime) - (lockedNFT[tokenId].withdrawMonth * 60)) >= 60) {
            uint months = ((block.timestamp - endTime) - (lockedNFT[tokenId].withdrawMonth * 60)) / 60;
            uint reward = 1000;
            return (reward, months);
        } else {
            return (0, 0);
        }
    }

    /**
     * @dev Allows the admin to deposit tokens into the contract.
     * @param adminAddress Address of the admin.
     * @param tokenDeposit Amount of tokens to deposit.
     */
    function adminDepositToken(address adminAddress, uint tokenDeposit) public onlyOwner {
        IERC20(tokenAddress).safeTransferFrom(adminAddress, address(this), tokenDeposit);
    }

    /**
     * @dev Allows the admin to withdraw tokens from the contract.
     * @param adminAddress Address of the admin.
     * @param tokenDeposit Amount of tokens to withdraw.
     */
    function adminWithdrawToken(address adminAddress, uint tokenDeposit) public onlyOwner {
        IERC20(tokenAddress).safeTransferFrom(address(this), adminAddress, tokenDeposit);
    }
}
