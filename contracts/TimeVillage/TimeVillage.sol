// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TimeVillageToken is ERC20, ERC20Burnable, Pausable, Ownable,ReentrancyGuard {
  AggregatorV3Interface public priceFeed;

    using SafeERC20 for IERC20;
    bool public IsClaim;
    address AddminAddress;
    address USDT;

    struct userRecord{
        address user;
        uint amount;
        uint currency;
        uint cost;
        string selectedCurrency;
        bool claim;
        
    }

    mapping (address => mapping(uint => userRecord)) public TokenRecord;



    constructor(address ownerAddress ) ERC20("Time Village Token", "TVT") Ownable(ownerAddress){
    _mint(msg.sender, 2500000000 * 10 ** decimals());
    priceFeed = AggregatorV3Interface(0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22);
    USDT = 0x3c725134d74D5c45B4E4ABd2e5e2a109b5541288;


    }

    //ADMIN START

    function AdminAddToken(uint _amount) public onlyOwner{
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this) ,_amount);
    }

    // END

    function buyTokens(uint256 currency, uint256 amountInUSDT, string memory _selectedCurrency) public payable nonReentrant {
        // (, int256 answer, , , ) = priceFeed.latestRoundData();
        amountInUSDT= 10;
        uint cost  = (amountInUSDT* currency);
        // require(currency == amountInUSDT, "Incorrect amount in USDT");
        TokenRecord[address(this)][currency] = userRecord(msg.sender, currency, msg.value, cost, _selectedCurrency, true);
        payable(AddminAddress).transfer(cost);
        IERC20(address(this)).safeTransfer(msg.sender,currency);
    }



    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    // function _beforeTokenTransfer(address from, address to, uint256 amount)
    //     internal
    //     whenNotPaused
    //     override
    // {
    //     super._beforeTokenTransfer(from, to, amount);
    // }
}