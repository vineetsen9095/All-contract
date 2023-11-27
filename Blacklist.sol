// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract BlackList {

    address public Owner;
    constructor(address initialOwner){
        Owner = initialOwner;
    }

    mapping (address =>bool) private  isBlacklist;

    modifier onlyOwner {
       require(msg.sender==Owner,"You Can not do this because you are not a Owner");
       _;
    }

    function AddBlocklist(address _user) public onlyOwner{
        require(!isBlacklist[_user],"user is already blacklisted");
        isBlacklist[_user]=true;
    }

    function RemoveBlocklist(address _user) public onlyOwner{
        require(isBlacklist[_user],"user is already whitelisted");
        isBlacklist[_user]=false;
    }

    function isBlocklists(address _user) public view returns (bool){

        return isBlacklist[_user];
    }
}