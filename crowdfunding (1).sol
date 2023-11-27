// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract CrowdFunding {
    mapping(address => uint256) public contributors;
    address public  manager;
    uint256 public  minimumContribution;
    uint256 public  deadline;
    uint256 public target;
    uint256 public raisedAmount;
    uint256 public noOfContributors;

    struct Request {
        string description;
        address payable recipient;
        uint256 value;
        bool completed;
        uint256 noOfVoters;
        mapping(address => bool) voters;
    }
    mapping(uint256 => Request) public requests;
    uint256 public numRequests;

    constructor(uint256 _target, uint256 _deadlineMin) {
        target = _target;
        deadline = block.timestamp + (_deadlineMin * 60); 
        minimumContribution = 10 wei;
        manager = msg.sender;
    }

    function sendEth() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minimumContribution, "Minimum Contribution is not met");
        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function refund() public {
        require(block.timestamp > deadline && raisedAmount < target, "You are not eligible for a refund");
        require(contributors[msg.sender] > 0,"You dont have a Contribution");
        uint256 refundAmount = contributors[msg.sender];
        contributors[msg.sender] = 0;
        address payable user = payable(msg.sender);

        require(user != address(0), "Invalid user address");

        user.transfer(refundAmount);
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint256 _value) public onlyManager {
        require(block.timestamp > deadline && raisedAmount >= target, "You are not eligible for a Create Request");
        numRequests++;
        Request storage newRequest = requests[numRequests];
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint256 _requestNo) public {
        require(_requestNo <= numRequests, "Invalid request number");
        require(contributors[msg.sender] > 0, "You must be a contributor");
        Request storage thisRequest = requests[_requestNo];
        require(!thisRequest.voters[msg.sender], "You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint256 _requestNo) public onlyManager {
        require(_requestNo <= numRequests, "Invalid request number");
         require(block.timestamp > deadline && raisedAmount >= target, "You are not eligible for a Make Payment");
        Request storage thisRequest = requests[_requestNo];
        require(!thisRequest.completed, "The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors / 2, "The majority does not support");
        thisRequest.completed = true;
        thisRequest.recipient.transfer(thisRequest.value);
    }

}
