// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Linking is Ownable {

    using SafeERC20 for IERC20;

    //Enum
    enum category{ Starlight, Meteor, Stellar, Galaxy }

    //Storage Variable

    uint public totalLockedTokenId;
    address public immutable tokenAddress;
    uint public immutable dividend;
    uint public vastingStartTime;
    uint public vastingEndTime;
    


    //Struct
    struct NFT_Detail{
        category choice;
        uint tokenId;
        address stakerAddress;
        address currentOwnerAddress;
        uint userWithdrawToken;
        uint withdrawMonthCount;
        uint stakeTime;
        bool isActive;
    }

    //Mapping
    mapping(address mintAddress=> mapping (uint tokenId => NFT_Detail)) public allLockedNFT;
    mapping (category => uint ) public tokenSupply;

    //constructor
    constructor(address initialOwner,address _tokenAddress,uint _dividend) Ownable(initialOwner) {

        tokenAddress = _tokenAddress;
        dividend = _dividend;
        tokenSupply[category.Starlight] = (dividend*6)/100;
        tokenSupply[category.Meteor] = (dividend*13)/100;
        tokenSupply[category.Stellar] = (dividend*28)/100;
        tokenSupply[category.Galaxy] = (dividend*53)/100;
    }


    function vastingPeriod(uint start,uint end) public onlyOwner{
        vastingStartTime = start;
        vastingEndTime = end;
    }


    function lockStarlightNFT(address mintAddress,address stakerAddress,uint tokenId,category choice) public {
        require(vastingStartTime < block.timestamp,"Time Not Start Yet");
        require (vastingEndTime > block.timestamp,"Time End");
        require(choice == category.Starlight,"Category Not Matched");
        require(!allLockedNFT[mintAddress][tokenId].isActive,"Already Staked");
        allLockedNFT[mintAddress][tokenId] = NFT_Detail(category.Starlight,tokenId,stakerAddress,address(this),0,0,block.timestamp,true);
        totalLockedTokenId++;
        ERC721(mintAddress).transferFrom(stakerAddress, address(this), tokenId); 
    }

    function lockMeteorNFT(address mintAddress,address stakerAddress,uint tokenId,category choice) public {
        require(vastingStartTime < block.timestamp,"Time Not Start Yet");
        require (vastingEndTime > block.timestamp,"Time End");
        require(choice == category.Meteor,"Category Not Matched");
        require(!allLockedNFT[mintAddress][tokenId].isActive,"Already Staked");
        allLockedNFT[mintAddress][tokenId] = NFT_Detail(category.Meteor,tokenId,stakerAddress,address(this),0,0,block.timestamp,true);
        totalLockedTokenId++;
        ERC721(mintAddress).transferFrom(stakerAddress, address(this), tokenId); 
    }

    function lockStellarNFT(address mintAddress,address stakerAddress,uint tokenId,category choice) public {
        require(vastingStartTime < block.timestamp,"Time Not Start Yet");
        require (vastingEndTime > block.timestamp,"Time End");
        require(choice == category.Stellar,"Category Not Matched");
        require(!allLockedNFT[mintAddress][tokenId].isActive,"Already Staked");
        allLockedNFT[mintAddress][tokenId] = NFT_Detail(category.Stellar,tokenId,stakerAddress,address(this),0,0,block.timestamp,true);
        totalLockedTokenId++;
        ERC721(mintAddress).transferFrom(stakerAddress, address(this), tokenId); 
    }

    function lockGalaxyNFT(address mintAddress,address stakerAddress,uint tokenId,category choice) public {
        require(vastingStartTime < block.timestamp,"Time Not Start Yet");
        require (vastingEndTime > block.timestamp,"Time End");
        require(choice == category.Galaxy,"Category Not Matched");
        require(!allLockedNFT[mintAddress][tokenId].isActive,"Already Staked");
        allLockedNFT[mintAddress][tokenId] = NFT_Detail(category.Galaxy,tokenId,stakerAddress,address(this),0,0,block.timestamp,true);
        totalLockedTokenId++;
        ERC721(mintAddress).transferFrom(stakerAddress, address(this), tokenId); 
    }

    function unlockStarlightNFT(address mintAddress,address stakerAddress,uint tokenId,category choice) public {
        require(allLockedNFT[mintAddress][tokenId].stakerAddress == stakerAddress,"You are not owner of this NFT");
        require(choice == category.Starlight,"Category Not Matched");
        require(allLockedNFT[mintAddress][tokenId].isActive,"NOT LOCK");
        allLockedNFT[mintAddress][tokenId].isActive = false;
        totalLockedTokenId--;
        ERC721(mintAddress).transferFrom(address(this), stakerAddress, tokenId);
           
    }

    function unlockMeteorNFT(address mintAddress,address stakerAddress,uint tokenId,category choice) public {
        require(allLockedNFT[mintAddress][tokenId].stakerAddress == stakerAddress,"You are not owner of this NFT");
        require(choice == category.Meteor,"Category Not Matched");
        require(allLockedNFT[mintAddress][tokenId].isActive,"NOT LOCK");
        allLockedNFT[mintAddress][tokenId].isActive = false;
        totalLockedTokenId--;
        ERC721(mintAddress).transferFrom(address(this), stakerAddress, tokenId);
           
    }

    function unlockStellarNFT(address mintAddress,address stakerAddress,uint tokenId,category choice) public {
        require(allLockedNFT[mintAddress][tokenId].stakerAddress == stakerAddress,"You are not owner of this NFT");
        require(choice == category.Stellar,"Category Not Matched");
        require(allLockedNFT[mintAddress][tokenId].isActive,"NOT LOCK");
        allLockedNFT[mintAddress][tokenId].isActive = false;
        totalLockedTokenId--;
        ERC721(mintAddress).transferFrom(address(this), stakerAddress, tokenId);
          
    }

    function unlockGalaxyNFT(address mintAddress,address stakerAddress,uint tokenId,category choice) public {
        require(allLockedNFT[mintAddress][tokenId].stakerAddress == stakerAddress,"You are not owner of this NFT");
        require(choice == category.Galaxy,"Category Not Matched");
        require(allLockedNFT[mintAddress][tokenId].isActive,"NOT LOCK");
        allLockedNFT[mintAddress][tokenId].isActive = false;
        totalLockedTokenId--;
        ERC721(mintAddress).transferFrom(address(this), stakerAddress, tokenId);
           
    }

    function lockedNFTs(address mintAddress) public view returns(NFT_Detail[] memory){
        NFT_Detail[] memory detail = new NFT_Detail[](totalLockedTokenId);
        uint j=0;
        for (uint i = 0; i < 488; i++) {
            if(allLockedNFT[mintAddress][i].isActive){
                detail[j] = allLockedNFT[mintAddress][i];
                j++;
            }
        }
        return detail;
    }

    function adminDepositFT(address adminAdress,uint dopositTokenSupply) public onlyOwner {
        IERC20(tokenAddress).safeTransferFrom(adminAdress,address(this),dopositTokenSupply);
    }

    function adminWithdrawFT(address adminAdress,uint withdrawTokenSupply) public onlyOwner {
        IERC20(tokenAddress).safeTransferFrom(address(this),adminAdress,withdrawTokenSupply);
    }

    function userClaimFT(address mintAddress,uint tokenId,address userAddress,category choice) public {
        (uint reward,uint month) = userFT_Rewards(choice,allLockedNFT[mintAddress][tokenId].withdrawMonthCount);
        allLockedNFT[mintAddress][tokenId].withdrawMonthCount += month;
        allLockedNFT[mintAddress][tokenId].userWithdrawToken += (reward*month);
        IERC20(tokenAddress).safeTransferFrom(address(this),userAddress,(reward*month));
    }

    function userFT_Rewards(category choice,uint withdrawMonthCount) public view returns(uint rewards,uint month) {
        if ((block.timestamp-(vastingStartTime + (withdrawMonthCount*60))) >= ((withdrawMonthCount+1)*60)) {
   
            uint reward = ((10*tokenSupply[choice])/100);
            return (reward,((block.timestamp - vastingStartTime)/60));
        }
    }
}