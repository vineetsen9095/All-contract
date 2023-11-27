// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Escrow is Ownable(msg.sender) {

    IERC20 public token;
    address public buyer;
    address public seller;
    uint256 public amount;
    bool public isFundsReleased;
    bool public isDisputeByBuyer;
    bool public isDisputeBySeller;
    bool public isInitiate;
    bool public isDeliver;

    event EscrowInitiated(address indexed _buyer, address indexed _seller, uint256 _amount);
    event FundsReleased(address indexed _contract, address indexed _receiver, uint256 _amount);
    event DisputeResolved(address indexed _resolvedBy);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can call this function");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can call this function");
        _;
    }

    modifier initiatDeliver(){
        require(isInitiate, "The Assest not Initiated Till Now");
        _;
    }

    modifier assetDeliver(){
        require(isDeliver, "The Assest not Deliver Till Now");
        _;
    }

    modifier escrowNotReleased() {
        require(!isFundsReleased, "Funds have already been released");
        _;
    }

    modifier notInDisputeByBuyer() {
        require(!isDisputeByBuyer, "The contract is in dispute by Buyer");
        _;
    }


    function initiateEscrow(address _seller, uint256 _amount) external {
        require(buyer == address(0), "Escrow has already been initiated");
        require(_seller != address(0), "Invalid seller address");
        require(_amount > 0, "Invalid escrow amount");

        buyer = msg.sender;
        seller = _seller;
        amount = _amount;

        token.transferFrom(buyer, address(this), amount);

        emit EscrowInitiated(buyer, seller, amount);
    }

    function initiateDelivery() external onlySeller escrowNotReleased{
       require(!isInitiate,"Assets has already Deliverd You Can not Initiate again delivery");
       isInitiate= true;
    }

    function deliverdAsset() external onlyBuyer escrowNotReleased initiatDeliver{
        isDeliver = true;
    }

    function releaseFunds() external onlySeller escrowNotReleased notInDisputeByBuyer initiatDeliver assetDeliver {
        token.transfer(seller, amount);
        isFundsReleased = true;

        emit FundsReleased(address(this),seller, amount);
    }

    function initiateDisputeByBuyer() external onlyBuyer escrowNotReleased {
        require(!isDeliver,"Assets has already Deliver You Can not Rise a dispute");
        isDisputeByBuyer = true;
    }

    function initateDisputeBySeller() external onlySeller escrowNotReleased initiatDeliver{
        isDisputeBySeller = true;
    }

    function resolveDisputefBuyer() external onlyOwner escrowNotReleased {
        require(isDisputeByBuyer, "No dispute to resolve");

        token.transfer(buyer, amount);

        isFundsReleased = true;
        isDisputeByBuyer = false;

        emit DisputeResolved(owner());
    }

    function resolvedDisputefSeller() external onlyOwner escrowNotReleased initiatDeliver{
        require(isDisputeBySeller, "The contract is not in  dispute by Seller");
         isDeliver = true;
    }
}
