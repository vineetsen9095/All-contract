// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tokens.sol";
import "./Token1155.sol";

contract Swappping is Ownable(msg.sender){

    ERC20TOKEN public token;
    MyERC1155Token public nft;
    uint256 public tokenPriceInWei;
    address payable  admin;

    constructor(address ERC20tokenAddress, uint256 initialPriceTokenInWei,address ERC1155Address) {
        token = ERC20TOKEN(ERC20tokenAddress);
        nft = MyERC1155Token(ERC1155Address);
        tokenPriceInWei = initialPriceTokenInWei;
        admin = payable(msg.sender);
    }

    function setTokenPrice(uint256 newPrice) public onlyOwner {
        tokenPriceInWei = newPrice;
    }
    
    function getTokenPrice() public view returns (uint256) {
        return tokenPriceInWei;
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Send some Ether to buy tokens");
        require(msg.value % tokenPriceInWei == 0, "Amount must be a multiple of token price");
        address buyer = msg.sender;
        uint256 ethAmount = msg.value;
        uint256 tokenAmount = ethAmount / tokenPriceInWei; 
        admin.transfer(msg.value);
        token.transferFrom(admin,buyer,tokenAmount*1e18);
    }
    


    function swapTokensToNft(uint256 nftAmount) public {

      require(nftAmount >= 0,"Please Enter Correct Nft Amount Which You Want to Swap");

      address user1 = msg.sender;

      require(nft.balanceOf(admin,1) >= nftAmount," admin Dont Have Enough NFT To Swap");

      require(token.balanceOf(user1) >= nftAmount*1e18, "You Dont Have Enough Tokens To Swap");
    
      (bool sent1) = token.transferFrom(msg.sender,admin, nftAmount*1e18);
      require(sent1, "Token transfer from user1 to Admin failed");

      nft.safeTransferFrom(admin,user1,1,nftAmount,"");
    } 


    function swapNftToToken(uint256 tokenAmount) public {

      require(tokenAmount >= 0,"Please Enter Correct Token Amount Which You Want to Swap");

      address user1 = msg.sender;

      require(nft.balanceOf(user1,1) >= tokenAmount," You Dont Have Enough NFT To Swap");

      require(token.balanceOf(admin) >= tokenAmount*1e18, "Admin Dont Have Enough Tokens To Swap");
    
      (bool sent1) = token.transferFrom(admin,user1, tokenAmount*1e18);
      require(sent1, "Token transfer from Admin to User failed");

      nft.safeTransferFrom(user1,admin,1,tokenAmount,"");
    } 
}