// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyERC1155Token is ERC1155, Ownable {

    constructor(address initialOwner) ERC1155("https://ipfs.io/ipfs/QmUcKPJZSgV2ih9ciqrxsqDCZcQPHVJmzZrGqJwwoT37hf") Ownable(initialOwner){

        _mint(msg.sender, 1, 10,"");
    }
    

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, 1, amount,"");
    }
}
