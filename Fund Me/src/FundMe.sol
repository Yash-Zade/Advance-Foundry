// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Conversion} from "./Conversion.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    error FundMe__InvalidAmount();
    error FundMe__Unauthorized();
    error FundMe__CallFailed();

    using Conversion for uint256;
    uint256 private constant MIN_AMOUNT = 5e18;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    address[] private s_funders;
    mapping(address => uint256) private s_funderToAmount;

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function fund() public payable {
        if (msg.value.convertToDoller(s_priceFeed) < MIN_AMOUNT) {
            revert FundMe__InvalidAmount();
        }
        s_funders.push(msg.sender);
        s_funderToAmount[msg.sender] += msg.value;
    }

    function withdraw() public OnlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            s_funderToAmount[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
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

    //View Functions

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getMinAmount() external pure returns (uint256) {
        return MIN_AMOUNT;
    }

    function getFunder(uint256 _index) external view returns (address) {
        return s_funders[_index];
    }

    function getFunderToAmount(address _funder) external view returns (uint256) {
        return s_funderToAmount[_funder];
    }
}
