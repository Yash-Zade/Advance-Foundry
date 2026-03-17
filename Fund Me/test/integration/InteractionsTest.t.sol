// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe} from "../../script/Interaction.s.sol";

contract InteractionTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant INITIAL_AMOUNT = 1 ether;
    uint256 constant SEND_AMOUNT = 0.1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, INITIAL_AMOUNT);
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        vm.prank(USER);
        fundFundMe.fundFundMe(address(fundMe));
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
}
