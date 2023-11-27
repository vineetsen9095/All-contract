// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract StakingContract {

    using Counters for Counters.Counter;
    Counters.Counter private stakeNumber;

    IERC20 private token;

    struct stakersInformation {
        uint256 stakedTokenAmount;
        uint256 timeWhenUserStaked;
        uint256 stakeTimePeriod; 
        bool rewardWithDraw;
        bool withdrawStakedToken;
    }

    mapping(uint256 => address) public ownerOfStakeNumber;
    mapping(uint256 => stakersInformation) public stakerInformationOfStakeNumber;
    mapping(address => uint256[]) private stakeIdsByAddress;
    
    constructor(address _token) {
        token = IERC20(_token);
    }

    function stakeToken(uint256 numberOfTokens, uint256 _time) external returns (uint256) {
        stakeNumber.increment();

        require(numberOfTokens > 0, "You cannot stake 0 amount of token");
        require(token.balanceOf(msg.sender) >= numberOfTokens, "You do not have enough tokens that you entered for stake");
        require(_time == 4 || _time == 2 || _time == 3, " Time for plans is only - 1,2,3 Minutes");

        uint256 current_time = block.timestamp;
        ownerOfStakeNumber[stakeNumber.current()] = msg.sender;

        stakeIdsByAddress[msg.sender].push(stakeNumber.current());
        
        require(token.transferFrom(msg.sender, address(this), numberOfTokens), "Please approve this contract to spend your stake amount in your ERC20 token contract");
        
        stakerInformationOfStakeNumber[stakeNumber.current()].stakedTokenAmount += numberOfTokens;
        stakerInformationOfStakeNumber[stakeNumber.current()].timeWhenUserStaked = current_time;
        stakerInformationOfStakeNumber[stakeNumber.current()].stakeTimePeriod = _time * 60;
        stakerInformationOfStakeNumber[stakeNumber.current()].rewardWithDraw=false;
        stakerInformationOfStakeNumber[stakeNumber.current()].withdrawStakedToken=false;

        return stakeNumber.current();
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

   function calculateYourReward(uint256 _stakeNumber) public view returns (uint256, uint256,uint256) {
    require(_stakeNumber <= stakeNumber.current(), "Invalid stake number");
    uint256 current_time = block.timestamp;
    uint256 stakingDuration = current_time - stakerInformationOfStakeNumber[_stakeNumber].timeWhenUserStaked;

    uint256 time = stakingDuration < stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod
        ? stakingDuration
        : stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod;

    uint256 reward;
    uint256 rateOfInterest;

    if (stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod == 240) {
        rateOfInterest = 10;
    } else if (stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod == 120) {
        rateOfInterest = 12;
    } else if (stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod == 180) {
        rateOfInterest = 13;
    }

     if((stakerInformationOfStakeNumber[_stakeNumber].rewardWithDraw == false) && (stakerInformationOfStakeNumber[_stakeNumber].withdrawStakedToken  == false)){
      reward = (stakerInformationOfStakeNumber[_stakeNumber].stakedTokenAmount * rateOfInterest * time) / (100 * 60);
     }
     else{
        reward=0;
     }

    return (reward,time,rateOfInterest);
}

function withdrawReward(uint256 _stakeNumber) public returns (uint256) {
    require(_stakeNumber <= stakeNumber.current(), "Invalid stake number");

    address staker = ownerOfStakeNumber[_stakeNumber];
    require(staker == msg.sender, "You are not the owner of this stake");

    (uint256 reward, uint256 time, ) = calculateYourReward(_stakeNumber);
    require(time >= stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod, "StakeTimePeriod is not over");

    require(reward > 0, "No reward to withdraw");
      
    stakerInformationOfStakeNumber[_stakeNumber].rewardWithDraw=true;
    token.transfer(msg.sender, reward);
    return reward;
}

function withdrawStakedTokens(uint256 _stakeNumber) public {
    require(_stakeNumber <= stakeNumber.current(), "Invalid stake number");

    address staker = ownerOfStakeNumber[_stakeNumber];
    require(staker == msg.sender, "You are not the owner of this stake");

    (uint256 reward,, ) = calculateYourReward(_stakeNumber);

    uint256 stakedAmount = stakerInformationOfStakeNumber[_stakeNumber].stakedTokenAmount;

    require(stakedAmount > 0, "No staked tokens to withdraw");
    stakerInformationOfStakeNumber[_stakeNumber].withdrawStakedToken=true;
    stakerInformationOfStakeNumber[_stakeNumber].rewardWithDraw=true;
    token.transfer(msg.sender, stakedAmount);
    token.transfer(msg.sender, reward);

    stakerInformationOfStakeNumber[_stakeNumber].stakedTokenAmount = 0;
   }
    
    function getStakeIdsByAddress(address owner) public view returns (uint256[] memory) {
        return stakeIdsByAddress[owner];
    }

}

