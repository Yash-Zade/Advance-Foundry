// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant INITIAL_AMOUNT = 1 ether;
    uint256 constant SEND_AMOUNT = 0.1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, INITIAL_AMOUNT);
    }

    function testMinimumDollerIsFive() public {
        assertEq(fundMe.getMinAmount(), 5e18);
    }

    function testFundWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundingDatastructures() public funded {
        address funder = fundMe.getFunder(0);
        uint256 amount = fundMe.getFunderToAmount(USER);

        assertEq(funder, USER);
        assertEq(amount, SEND_AMOUNT);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //arrange
        uint256 startingContractBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingContractBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(endingContractBalance, 0);
        assertEq(startingContractBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), INITIAL_AMOUNT);
            fundMe.fund{value: SEND_AMOUNT}();
        }

        uint256 startingContractBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingContractBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(endingContractBalance, 0);
        assertEq(startingContractBalance + startingOwnerBalance, endingOwnerBalance);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_AMOUNT}();
        _;
    }
}
