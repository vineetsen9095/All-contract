// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Lottery {
    address public manager;
    address payable[] public participants;
    uint public commissionPercentage; 
     uint256 public  managerCommission=0;
     uint256 public amountToWinner=0;

     uint256 public minParticipants = 3; 
     uint256 public lotteryStartTime=0;
     uint256 public lotteryEndTime=0;

    constructor( uint256 initialCommissionPercentage) {
        commissionPercentage=initialCommissionPercentage;
          manager = msg.sender;
          lotteryStartTime = block.timestamp + 180;
          lotteryEndTime = lotteryStartTime + 360; 
    }

    mapping (address => uint256) public  userAmount;

    receive() external payable {

    }

    function addEtherToContract() public payable  {
         require(block.timestamp >= lotteryStartTime,"Lottery Not Started Yet");
         require(block.timestamp < lotteryEndTime,"Lottery is Now Ended");
         require(msg.value >= 10 wei, "You must send exactly 10 Wei to participate");
         participants.push(payable(msg.sender));
         userAmount[msg.sender]  =msg.value;
    } 

    function getBalance() public view returns (uint) {
        require(msg.sender == manager, "You are not the manager");
        return address(this).balance;
    }

    function random() internal view returns(uint) {
        bytes32 hash = blockhash(block.number - 1);
        return uint(keccak256(abi.encodePacked(hash, participants.length, block.timestamp)));
    }

    address payable public winner;

    modifier someCondition{
         require(msg.sender == manager, "You are not the manager");
        require(block.timestamp > lotteryEndTime,"Lottery is Not Ended Yet");
        _;
    }

    function pickWinner() public someCondition {
        require(participants.length >= minParticipants, "There is a Not Enough(3) participants In Your Lottery");
        
        uint256 r = random();
        uint256 index = r % participants.length;
        winner = participants[index];

        managerCommission = (address(this).balance * commissionPercentage) / 100;
        amountToWinner = address(this).balance - managerCommission;

        winner.transfer(amountToWinner);
        payable(manager).transfer(managerCommission);
        participants = new address payable[](0);
    }

    function retunAmount()public someCondition{

        require(!(participants.length >= minParticipants), "There is a Enough(3) participants In Your Lottery");
        managerCommission = (address(this).balance * 1) / 100; 
        payable(manager).transfer(managerCommission); 

        for (uint i = 0; i < participants.length; i++) {
            uint256 returnAmounts = (userAmount[participants[i]] * 99) / 100; // Deduct 1%
            participants[i].transfer(returnAmounts);
            userAmount[participants[i]]  = 0;
        }
        
        participants = new address payable[](0);
    }
}

