// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingRewards is Ownable{ 
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    uint public duration;
    uint public finishAt;
    uint public updatedAt;
    uint public rewardRate;
    uint public rewardPerTokenStored;
    mapping(address=>uint) public userReward;
    mapping(address=>uint) public rewards;

    uint public totalSupply;
    mapping(address=>uint) public balanceOf;


constructor(address _stakingToken , address _rewardToken) Ownable(msg.sender) { 

    stakingToken = IERC20(_stakingToken);
    rewardsToken = IERC20(_rewardToken);
}
// modifier updateReward(address _account) { 
//     rewardPerTokenStored = rewardPerToken();
// }

    function setRewardDuration(uint _duration) external onlyOwner{ 

        require(finishAt < block.timestamp , "reward duration not finished");
        duration  =_duration;
    }

    function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
}
    function notifyRewardAmount(uint _amount) external{ 
        if(block.timestamp >finishAt){ 
            rewardRate = _amount/duration;
        } else { 
            uint remainingRewards = rewardRate *(finishAt-block.timestamp);
            rewardRate = (remainingRewards + _amount) /duration;
        }
        require(rewardRate>0 , "reward rate = 0");
        require(rewardRate*duration<= rewardsToken.balanceOf(address(this)),
        "reward amount >balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }
    
    function stake(uint _amount) external{ 
        require(_amount > 0,"amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }
    
    function withdraw(uint _amount) external{ 
        require(_amount>0,"amount= 0");
        balanceOf[msg.sender]-= _amount;
        totalSupply-=_amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function rewardPerToken() public  view returns (uint){
        if(totalSupply ==0){
            return rewardPerToken();
        } 
        return  rewardPerTokenStored + (rewardRate * (min(block.timestamp, finishAt) - updatedAt) * 1e18 ) / totalSupply;

    }
    function earned(address _account) external view returns (uint){ 
        return (balanceOf[_account]*((rewardPerToken()-userReward[_account]))/1e18) +rewards[_account];
    }
    
    function getReward() external{ 
        uint reward = rewards[msg.sender];
        if (reward>0){ 
            rewards[msg.sender]=0; 
            rewardsToken.transfer(msg.sender,reward);
        }
    }
    
    

}