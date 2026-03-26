// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
* @title A Lattory/Raffle contract
* @author Yash Zade
* @notice This contract is creating a sample raffle
* @dev Implements Chainlink VRFv2.5
*/
contract Raffle is VRFConsumerBaseV2Plus{

    /**Errors*/
    error Rafffle__NotEnoughAmountToEnterRaffle();
    error Raffle__TransactionFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint16 private constant REQUEST_CONFORMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entryAmount;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    address private s_recentWinner;
    RaffleState private s_raffleState;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);
    event RequestRaffleWinner(uint256 indexed requestId);

    constructor(uint256 entryAmount, uint256 interval, address _vrfCoordinator, bytes32 gaslane, uint256 subId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(_vrfCoordinator){
        i_entryAmount = entryAmount;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gaslane;
        i_subscriptionId = subId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable{
        if(msg.value < i_entryAmount){
            revert Rafffle__NotEnoughAmountToEnterRaffle();
        }

        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
        
    }
    
    function performUpkeep(bytes memory /*perdormDtta*/) external {

        (bool upkeepNeeded,) = checkUpkeep("");

        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFORMATION,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
           request
        );
        emit RequestRaffleWinner(requestId);
    }

    function checkUpkeep(bytes memory /*checkDaata*/) public view returns(bool upkeepNeeded, bytes memory /*perdormDtta*/) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0; 
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers && timeHasPassed;
        return(upkeepNeeded, "");
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override{
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_recentWinner = recentWinner;
        
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert Raffle__TransactionFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    function getRaffleState() external view returns (RaffleState memoy){
        return s_raffleState;
    }

    function getPlayersByIndex(uint256 index) external view returns (address){
        return s_players[index];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

}