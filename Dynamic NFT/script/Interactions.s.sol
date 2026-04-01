// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MoodNFT} from "src/MoodNFT.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract MintMoodNFT is Script{
    function run() public {
        address moodNFT = DevOpsTools.get_most_recent_deployment("MoodNFT", block.chainid);
        mintNFT(moodNFT);
    }
    function mintNFT(address moodNFT) public {
        vm.startBroadcast();
        MoodNFT(moodNFT).mintNft();
        vm.stopBroadcast();
    }
}

contract FlipMoodNFt is Script{ 
    uint256 public constant TOKEN_ID_TO_FLIP = 0;
    function run() public {
        address moodNFT = DevOpsTools.get_most_recent_deployment("MoodNFT", block.chainid);
        flipMood(moodNFT);
    }

    function flipMood(address moodNFT) public{
        vm.startBroadcast();
        MoodNFT(moodNFT).flipMood(TOKEN_ID_TO_FLIP);
        vm.stopBroadcast();
    }
}
