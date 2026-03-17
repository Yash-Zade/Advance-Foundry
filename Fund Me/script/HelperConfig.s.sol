// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

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
        NetworkConfig memory sapholiaNetworkConfig =
            NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sapholiaNetworkConfig;
    }

    function getAnvilNetworkConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});

        return anvilNetworkConfig;
    }
}
