// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract StakingContract is IERC721Receiver {

    using Counters for Counters.Counter;
    Counters.Counter private stakeNumber;

    IERC20 private token;
    IERC721 private nftToken;

    struct StakerInformation {
        uint256 timeWhenUserStaked;
        uint256 stakeTimePeriod;
        bool rewardWithdrawn;
        bool nftWithdrawn;
    }

    mapping(uint256 => address) public ownerOfStakeNumber;
    mapping(uint256 => StakerInformation) public stakerInformationOfStakeNumber;
    mapping(address => uint256[]) private stakeIdsByAddress;

    constructor(address _token, address _nftToken) {
        token = IERC20(_token);
        nftToken = IERC721(_nftToken);
    }

    function onERC721Received(address, address, uint256, bytes memory) external pure  override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function stakeNFT(uint256 tokenId, uint256 _time) external returns (uint256) {
        stakeNumber.increment();
        require(nftToken.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_time == 1 || _time == 2 || _time == 3, "Time for plans is only - 1, 2, 3 Minutes");
        uint256 current_time = block.timestamp;

        ownerOfStakeNumber[stakeNumber.current()] = msg.sender;
        stakeIdsByAddress[msg.sender].push(stakeNumber.current());

        require(nftToken.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT");
        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);

        stakerInformationOfStakeNumber[stakeNumber.current()] = StakerInformation({
            timeWhenUserStaked: current_time,
            stakeTimePeriod: _time * 60,
            rewardWithdrawn: false,
            nftWithdrawn: false
        });

        return stakeNumber.current();
    }

    function calculateYourReward(uint256 _stakeNumber) public view returns (uint256, uint256, uint256) {
        require(_stakeNumber <= stakeNumber.current(), "Invalid stake number");

        uint256 current_time = block.timestamp;
        uint256 stakingDuration = current_time - stakerInformationOfStakeNumber[_stakeNumber].timeWhenUserStaked;

        uint256 time = stakingDuration < stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod
            ? stakingDuration
            : stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod;

        uint256 reward;
        uint256 totalRewardTokens;

        if (stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod == 60) {
            totalRewardTokens = 20;
        } else if (stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod == 120) {
            totalRewardTokens = 40;
        } else if (stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod == 180) {
            totalRewardTokens = 60;
        }

        if (!stakerInformationOfStakeNumber[_stakeNumber].rewardWithdrawn && !stakerInformationOfStakeNumber[_stakeNumber].nftWithdrawn) {
    
            reward = (totalRewardTokens * time) / stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod;
        } else {
            reward = 0;
        }

        return (reward, time, totalRewardTokens);
    }

    function withdrawReward(uint256 _stakeNumber) public returns (uint256) {
        require(_stakeNumber <= stakeNumber.current(), "Invalid stake number");

        address staker = ownerOfStakeNumber[_stakeNumber];
        require(staker == msg.sender, "You are not the owner of this stake");

        (uint256 reward, uint256 time, ) = calculateYourReward(_stakeNumber);
        require(time >= stakerInformationOfStakeNumber[_stakeNumber].stakeTimePeriod, "StakeTimePeriod is not over");

        require(reward > 0, "No reward to withdraw");
        require(token.balanceOf(address(this)) >= reward,"Contract Does not have enought Token");

        stakerInformationOfStakeNumber[_stakeNumber].rewardWithdrawn = true;
        token.transfer(msg.sender, reward);
        return reward;
    }

    function withdrawStakedNFT(uint256 _stakeNumber) public {
        require(_stakeNumber <= stakeNumber.current(), "Invalid stake number");

        address staker = ownerOfStakeNumber[_stakeNumber];
        require(staker == msg.sender, "You are not the owner of this stake");

        (uint256 reward, , ) = calculateYourReward(_stakeNumber);

        require(nftToken.ownerOf(_stakeNumber) == address(this), "NFT not in contract");

        require(reward == 0, "Withdraw your reward first");
        require(!stakerInformationOfStakeNumber[_stakeNumber].nftWithdrawn, "You are already Unstake your NFT");


        stakerInformationOfStakeNumber[_stakeNumber].nftWithdrawn = true;
        nftToken.safeTransferFrom(address(this), msg.sender, _stakeNumber);
    }

    function getStakeIdsByAddress(address owner) public view returns (uint256[] memory) {
        return stakeIdsByAddress[owner];
    }
}
