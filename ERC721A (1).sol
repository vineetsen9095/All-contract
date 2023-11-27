// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract My721Token is ERC721A, Ownable {

    constructor(address initialAddress) ERC721A("My721AToken", "M721AT") Ownable(initialAddress){}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/QmVVfs33J4tymRo59Xhqs99hpTz2amnW2CZP6qMdktbBkj/";
    }

    function Mint(uint256 Amount) public onlyOwner 
    {
        _safeMint(msg.sender,Amount);
    }

     function burn(uint256 tokenId) public onlyOwner{
        require(_exists(tokenId),"Token Does not exits"); 
        _burn(tokenId);
     }

    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

    //     string memory baseURI = _baseURI();
    //     return bytes(baseURI).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId),".json")):'';
    // }
}