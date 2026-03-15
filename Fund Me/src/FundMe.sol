// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Conversion} from "./Conversion.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    error FundMe__InvalidAmount();
    error FundMe__Unauthorized();
    error FundMe__CallFailed();

    using Conversion for uint256;
    uint256 public constant MIN_AMOUNT = 5e18;
    address public immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    address[] funders;

    mapping(address => uint256) public funderToAmount;

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        if (msg.value.convertToDoller(s_priceFeed) < MIN_AMOUNT)
            revert FundMe__InvalidAmount();
        funders.push(msg.sender);
        funderToAmount[msg.sender] += msg.value;
    }

    function withdraw() public OnlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            funderToAmount[funders[i]] = 0;
        }
        funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert FundMe__CallFailed();
    }

    modifier OnlyOwner() {
        if (msg.sender != i_owner) revert FundMe__InvalidAmount();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
