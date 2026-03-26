// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Script} from "forge-std/Script.sol"; 
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {LinkToken} from "test/mock/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script{
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = helperconfig.getConfig().vrfCoordinator;
        address account = helperconfig.getConfig().account;
        (uint256 subId,) = createSubscription(vrfCoordinator,account);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address){
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        return (subId,vrfCoordinator);
    }
    function run() public{
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is CodeConstants, Script{

    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public{
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = helperconfig.getConfig().vrfCoordinator;
        uint256 subId = helperconfig.getConfig().subscriptionId;
        address linkToken = helperconfig.getConfig().link;
        address account = helperconfig.getConfig().account;
        fundSubscription(vrfCoordinator, subId, linkToken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subId, address linkToken, address account) public{
        if(block.chainid == LOCAL_CHAIN_ID){
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else{
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() public{
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script{

    function addconsumerUsingconfig(address mostRecentdeployment) public {
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = helperconfig.getConfig().vrfCoordinator;
        uint256 subId = helperconfig.getConfig().subscriptionId;
        address account = helperconfig.getConfig().account;
        addConsumer(mostRecentdeployment, vrfCoordinator, subId, account);
    }

    function addConsumer(address consumer, address vrfCoordinator, uint256 subId, address account) public {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, consumer);
        vm.stopBroadcast();
    }

    function run() public{
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addconsumerUsingconfig(mostRecentDeployment);
    }
}