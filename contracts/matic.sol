// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

// Importing Chainlink Aggregator interface
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MaticPrice {
  // Matic/USD price feed address (replace with your network's address)
  AggregatorV3Interface public priceFeed;

  constructor(address _priceFeed) public {
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  // Function to get the latest Matic price
  function getMaticPrice() public view returns (uint256 MaticValue, uint256 decimal) {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // Handle negative price (unlikely but theoretically possible)
    require(answer > 0, "Negative Matic price received");
    return (uint256(answer),10**8);
  }
}