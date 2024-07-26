// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// Importing Chainlink Aggregator interface
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

contract TimeVillageToken is ERC20, ERC20Burnable, Pausable, Ownable,ReentrancyGuard {
  AggregatorV3Interface public priceFeed;

constructor(address ownerAddress ) ERC20("Time Village Token", "TVT") Ownable(ownerAddress){
    _mint(msg.sender, 2500000000 * 10 ** decimals());
    priceFeed = AggregatorV3Interface(0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22);


    }

function getMaticPrice() public view returns (uint256 MaticValue, uint256 decimal) {
    (, int256 answer, , uint256 updatedAt, ) = priceFeed.latestRoundData();

    require(answer > 0, "Negative Matic price received");

    return (uint256(answer), 10**8);
}

      function increment(uint counter) public pure {
        counter++;
        console.log("Counter is now", counter);
    }
}