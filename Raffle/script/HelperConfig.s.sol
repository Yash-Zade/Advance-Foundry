// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol"; 
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import{LinkToken} from "test/mock/LinkToken.sol";

abstract contract CodeConstants{
    uint96 public constant MOCK_BASE_FEES = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
    
    uint256 public constant ETH_SAPHOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script{

    error HelperConfig__InvalidChainId();

    struct NetworkConfig{
        uint256 entryAmount;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;   
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping (uint256 => NetworkConfig) public networkConfig;

    constructor(){
        networkConfig[ETH_SAPHOLIA_CHAIN_ID] = getSapholiaEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory){
        if(networkConfig[chainId].vrfCoordinator != address(0)){
            return networkConfig[chainId];
        } else if(chainId == LOCAL_CHAIN_ID){
            return getOrCreateAnvilConfig();
        }else{
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }

    function setconfig(uint256 chainId, NetworkConfig memory config) public {
        if(chainId == LOCAL_CHAIN_ID){
            localNetworkConfig = config;
        }else{
            networkConfig[chainId] = config;
        }
    }

    function getSapholiaEthConfig() public pure returns (NetworkConfig memory){
        return NetworkConfig({
            entryAmount: 0.0001 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId:10018347176520067920447422793416750641414837151785527082000987493879151776535,
            callbackGasLimit: 100000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xe86fe0CEf2641C39CD0AfA85456471d58dc2D09d
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory){
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }

        vm.startBroadcast(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEES, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig =  NetworkConfig({
            entryAmount: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinator),
            gasLane: 0xa16a2316f92fa0abfd0029eea74e947d0613728e934d9794cd78bc02e2f69de4,
            subscriptionId:0,
            callbackGasLimit: 500000,
            link: address(link),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });

        return localNetworkConfig;
    }
}