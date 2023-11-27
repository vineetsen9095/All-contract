// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNFT721 is ERC721, ERC721URIStorage, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _mintId;

    constructor(address initialOwner) ERC721("My721Token", "M721T") Ownable(initialOwner) {}

    function safeMint(address to, string memory uri) public onlyOwner{
         _mintId.increment();
         uint256 tokenId = _mintId.current();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

