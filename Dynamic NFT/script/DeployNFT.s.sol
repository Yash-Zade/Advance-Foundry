// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MoodNFT} from "src/MoodNFT.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployNFT is Script {

    function run() public returns (MoodNFT){
        string memory happySvg = vm.readFile("images/happy.svg");
        string memory sadSvg = vm.readFile("images/sad.svg");
        MoodNFT moodNFT = new MoodNFT(svgToImageUri(happySvg), svgToImageUri(sadSvg)); 
        return moodNFT;
    }

    function svgToImageUri(string memory svg) public pure returns (string memory){
        string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoding = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURI, svgBase64Encoding));
    }
}