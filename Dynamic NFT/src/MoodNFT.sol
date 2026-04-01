// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNFT is ERC721{

    error MoodNFT__CantFlipMoodIfNotOwner();

    enum Mood{
        HAPPY,
        SAD
    }

    uint256 private s_tokenCounter;
    string private s_happySvgUri;
    string private s_sadSvgUri;

    mapping(uint256 => Mood) s_tokenIdToMood;

    event CreatedNFT(uint256 indexed tokenId);

    constructor(string memory happySvgUri, string memory sadSvgUri) ERC721("Mood NFT", "MT"){
        s_tokenCounter = 0;
        s_happySvgUri = happySvgUri;
        s_sadSvgUri = sadSvgUri;
    }

    function mintNft() public {
        uint256 tokenCounter = s_tokenCounter;
        _safeMint(msg.sender, tokenCounter);
        s_tokenCounter++;
        emit CreatedNFT(tokenCounter);
    }  

    function flipMood(uint256 tokenId) public {
        if(getApproved(tokenId) != msg.sender && ownerOf(tokenId) != msg.sender){
            revert MoodNFT__CantFlipMoodIfNotOwner();
        }

        if(s_tokenIdToMood[tokenId] == Mood.HAPPY){
            s_tokenIdToMood[tokenId] = Mood.SAD;
        } else {
            s_tokenIdToMood[tokenId] = Mood.HAPPY;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        string memory imageUri = s_happySvgUri;
        if(s_tokenIdToMood[tokenId] == Mood.SAD){
            imageUri = s_sadSvgUri;
        }

        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                                name(), // You can add whatever name here
                                '", "description":"An NFT that reflects the mood of the owner, 100% on Chain!", ',
                                '"attributes": [{"trait_type": "moodiness", "value": 100}], "image":"',
                                imageUri,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function _baseURI() internal view override returns (string memory){
        return "data:application/json;base64,";
    }

    function getTokenCounter() public view returns (uint256){
        return s_tokenCounter;
    }

    function getHappySvgUri() public view returns (string memory){
        return s_happySvgUri;
    }

    function getSadSvgUri() public view returns (string memory){
        return s_sadSvgUri;
    }


}