// SPDEX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 11555111) {
            activeNetworkConfig = getSapholiaNetworkConfig();
        } else {
            activeNetworkConfig = getAnvilNetworkConfig();
        }
    }

    function getSapholiaNetworkConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sapholiaNetworkConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sapholiaNetworkConfig;
    }

    function getAnvilNetworkConfig() public returns (NetworkConfig memory){

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(8,2000e8);
        vm.stopBroadcast();
        
        NetworkConfig memory anvilNetworkConfig = NetworkConfig({
            priceFeed:address(mockPriceFeed)
        });

        return anvilNetworkConfig;
    }
}
