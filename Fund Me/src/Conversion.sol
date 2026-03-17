// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library Conversion {
    function convertToDoller(uint256 _amount, AggregatorV3Interface _priceFeed) public view returns (uint256) {
        uint256 ethPrice = getEthPrice(_priceFeed);
        return ((_amount * ethPrice) / 1e18);
    }

    function getVersion(AggregatorV3Interface _priceFeed) public view returns (uint256) {
        return _priceFeed.version();
    }

    function getEthPrice(AggregatorV3Interface _priceFeed) public view returns (uint256) {
        (, int256 price,,,) = _priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }
}
