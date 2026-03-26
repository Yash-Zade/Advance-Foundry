// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, Vm, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/Deploy.s.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is CodeConstants, Test {

    Raffle public raffle;
    HelperConfig public helperConfig;
    address public PLAYER = makeAddr("palyer");
    uint256 public constant STARTING_PLAYERS_BALANCE = 10 ether;

    uint256 entryAmount;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;   

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffle();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entryAmount = config.entryAmount;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYERS_BALANCE);
    }

    function testRafffleInitializesWithOpenSatte() public{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testEnterRaffleRevertRevertWhnYouDidntPayEnough() public{
        // Arrange
        vm.prank(PLAYER);
        // Act/Assert
        vm.expectRevert(Raffle.Rafffle__NotEnoughAmountToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPalyersWhenTheyEnter() public{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryAmount}();

        assertEq(PLAYER, raffle.getPlayersByIndex(0));
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);

        raffle.enterRaffle{value: entryAmount}();
    }

    function testDontAllowPlayerToEntireRaffleCalculating() public enterRaffle {

        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryAmount}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECK UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testCheckUpkeepreturnsFalseWhenNoBalance() public{
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testChekUpkeepReturnsFalseIfRaffleIsNotOpen() public enterRaffle {

        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepRetuensFalseIfNotEnoughTimeHasPased() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryAmount}();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);

    }

    function testCheckUpkeepRetuensTrueWhneAllParametersAreGood() public enterRaffle {
        
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }


    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testPerformUpkeepOnlyRunsIfcheckUpkeepIsTrue() public enterRaffle {

        raffle.performUpkeep("");
    }

    function testPerformupkeepevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = address(raffle).balance;
        uint256 numberOfPalyers = 0;
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryAmount}();
        currentBalance += entryAmount;
        numberOfPalyers += 1;
        Raffle.RaffleState state = raffle.getRaffleState();

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numberOfPalyers, state)
        );
        raffle.performUpkeep("");
    }

    function testCheckPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public enterRaffle{

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestId = logs[1].topics[1];

        assert(requestId > 0);
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    function testFulfilRandomwordCanOnlyBeCalledAfterPerformUpkeep(uint256 reqId) public enterRaffle skipfork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(reqId, address(raffle));
    }

    
    function testFulfilRandomWordPickWinnnerAndSendMoney() public enterRaffle skipfork {
        address expectedWinner = address(1);
        
        for(uint160 i=1; i<4; i++){
            address newPlayer = address(i);
            hoax(newPlayer, STARTING_PLAYERS_BALANCE);
            raffle.enterRaffle{value: entryAmount}();
        }
        
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnersStartingbalance = expectedWinner.balance;
        
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestId = logs[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));
        
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState state = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 priceAmount = entryAmount * 4;
        
        assert(recentWinner == expectedWinner);
        assert(uint256(state) == 0);
        assert(winnerBalance == winnersStartingbalance + priceAmount);
        assert(endingTimeStamp > startingTimeStamp);
        assert(endingTimeStamp - startingTimeStamp > interval);
    }
    
    modifier enterRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryAmount}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipfork() {
        if(block.chainid != LOCAL_CHAIN_ID){
            return;
        }
        _;
    }
}  