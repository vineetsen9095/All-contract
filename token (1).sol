// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyTokenForEscrow is ERC20, Ownable {
    constructor(address initialOwner) ERC20("StakingToken", "STK") Ownable(initialOwner) {
    _mint(msg.sender, 100000);
}
}