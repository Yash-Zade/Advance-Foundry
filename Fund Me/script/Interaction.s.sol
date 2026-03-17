// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script{

    uint256 constant SEND_AMOUNT = 0.1 ether;

    function fundFundMe(address mostRecentDeployment) public{
        FundMe(payable(mostRecentDeployment)).fund{value: SEND_AMOUNT}();
    }

    function run() external{
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        vm.startBroadcast();
        fundFundMe(mostRecentDeployment);
        vm.stopBroadcast();
    }
}