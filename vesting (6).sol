// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Vesting is Ownable(msg.sender) {

    using Counters for Counters.Counter;
    Counters.Counter private vestingNumber;

    struct VestingInfo {
        address userAdd;
        uint256 unlockStartTime;
        uint256 AllocatedTokens;
        uint256 timeIntervalInMin;
        uint256 claimAmount;
    }

    IERC20 private  token;

    struct UserInfo {
        uint256 totalAllocatedAmount;                      
        uint256 totalClaimedAmount;
    }

    uint256 public adminComm;

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => VestingInfo) public userVestingInfo;
    mapping(address => uint256[]) private VestingIdsByAddress;
    mapping(address => bool) public allocatedUser;
    mapping(uint256 => address) public ownerOfVestingId;

     constructor(address _token, uint256 _adminComm) {
        require(_token != address(0), "Token address cannot be the zero address");
        require(_adminComm > 0, "Admin commission must be greater than 0");
        token = IERC20(_token);
        adminComm=_adminComm;
    }

    function updateAdminCommission(uint256 _adminComm) external onlyOwner {
        adminComm = _adminComm;
    }

    uint256 public timeIntervalsInMin = 60;

    function setTimeIntervalInMin(uint256 _timeIntervalInMin)public onlyOwner{
        timeIntervalsInMin= _timeIntervalInMin*60;
    }

    function allocateForVesting(address _user, uint256 _amount,uint256 _unlockStartTimeInMin) external onlyOwner {
        
        require(_user != address(0), "Address cannot be the zero address");
        require(_amount > 0, "Amount must be greater than 0");
        require(_unlockStartTimeInMin > 0, "unlockStartTimeInMin can be greater than 0");
        require(token.transferFrom(owner(), address(this), _amount), "Admin Does not have EnoughToken: transfer failed");

        _allocateAmount(_user, _amount,_unlockStartTimeInMin);
        allocatedUser[_user] = true;
    }

    function _allocateAmount(address _user, uint256 _amount,uint256 _unlockStartTime) internal {
        vestingNumber.increment();

        uint256 vestingStartTimestamp = block.timestamp + (_unlockStartTime * 60);

        userVestingInfo[vestingNumber.current()].userAdd = _user;
        userVestingInfo[vestingNumber.current()].unlockStartTime = vestingStartTimestamp;
        userVestingInfo[vestingNumber.current()].AllocatedTokens = _amount;
        userVestingInfo[vestingNumber.current()].timeIntervalInMin = timeIntervalsInMin;
        userVestingInfo[vestingNumber.current()].claimAmount = 0;

        VestingIdsByAddress[_user].push(vestingNumber.current());
        ownerOfVestingId[vestingNumber.current()] = _user;
        
        if (allocatedUser[_user]) {
            userInfo[_user].totalAllocatedAmount += _amount;
             userInfo[_user].totalClaimedAmount =  userInfo[_user].totalClaimedAmount;
        } else {
            userInfo[_user].totalAllocatedAmount = _amount;
            userInfo[_user].totalClaimedAmount = 0;
        }
    }


    function getUnlockedTokenAmount( uint256 _VestingId) public view returns (uint256) {
        require(_VestingId <= vestingNumber.current(), "Invalid Vesting Id");
        require(block.timestamp >= userVestingInfo[_VestingId].unlockStartTime, "Cannot claim before claim start time");
        uint256 allowedAmount = 0;

        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - userVestingInfo[_VestingId].unlockStartTime;

        uint256 tokensToUnlock = timeElapsed / timeIntervalsInMin;  // 2 min of interval(Every 2 minute one token has been unlocked)

        allowedAmount = userVestingInfo[_VestingId].AllocatedTokens >= tokensToUnlock ? tokensToUnlock :userVestingInfo[_VestingId].AllocatedTokens;
        uint256  tokensToSend = allowedAmount -  userVestingInfo[_VestingId].claimAmount;

        return tokensToSend;
    }
    
      function claimTokens(uint256 _VestingId) public {
        require(_VestingId <= vestingNumber.current(), "Invalid stake number");
        address vester = ownerOfVestingId[_VestingId];
        require(vester == msg.sender, "You are not the owner of this Vesting Id");
        require(block.timestamp >= userVestingInfo[_VestingId].unlockStartTime, "Cannot claim before claim start time");

        uint256 tokensToSend = getUnlockedTokenAmount(_VestingId);

        require(tokensToSend != 0, "Claim amount is insufficient");

        if (tokensToSend > 0) {
            uint256 fee = (tokensToSend * adminComm) / 10000;

            token.transfer(owner(), fee);

            token.transferFrom(owner(), msg.sender, (tokensToSend-fee));

            userVestingInfo[_VestingId].claimAmount += tokensToSend;
            userInfo[vester].totalClaimedAmount += tokensToSend;
        }
    }
    function getStakeIdsByAddress(address owner) public view returns (uint256[] memory) {
        return VestingIdsByAddress[owner];
    }

}
