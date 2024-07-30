// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TimeVillageToken is ERC20, ERC20Burnable, Pausable, Ownable,ReentrancyGuard {
  AggregatorV3Interface public priceFeed;
    using Counters for Counters.Counter;
    Counters.Counter private numberOfTransactions;
    using SafeERC20 for IERC20;
    bool public IsClaim;
    address AddminAddress;
    address USDT;
    address immutable UsdcContract;

    struct userRecord{
        address user;
        uint amount;
        uint currency;
        uint cost;
        bool claim;
        currency choice;
        
    }

    mapping (address => mapping(uint => userRecord)) public TokenRecord;
    mapping (currency => uint) _currencyCoice;
    mapping (address =>uint) public NumberOfBuying;
    enum currency{USDT, BNB}


    constructor(address ownerAddress) ERC20("Time Village Token", "TVT") Ownable(ownerAddress){
    _mint(msg.sender, 2500000000 * 10 ** decimals());
    // priceFeed = AggregatorV3Interface(0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22);
    UsdcContract = 0xec70714Fb3cf41Ab01894786b9DCaf97b75F5635;
    }

    //ADMIN START

    function AdminAddToken(uint _amount) public onlyOwner{
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this) ,_amount);
    }

    // END

    function buyTokens(uint256 _amount,   currency choice) public nonReentrant {
        // (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 currencyinUSDT = 285;
        uint currencyinBNB = 317;
        uint cost;
        _currencyCoice[currency.USDT] = 0;
        _currencyCoice[currency.BNB] = 1;
        numberOfTransactions.increment();
        if(_currencyCoice[choice] ==  0){ 
            cost  = (_amount* currencyinUSDT);
        }

        if(_currencyCoice[choice] ==  1){ 
            cost  = (_amount* currencyinBNB);
        }
        NumberOfBuying[msg.sender]++;
        uint currentTransactionCount = NumberOfBuying[msg.sender];
        TokenRecord[msg.sender][currentTransactionCount] = userRecord(msg.sender, _amount, currencyinUSDT, cost, true, choice);
        IERC20(address(this)).transfer(msg.sender,_amount);
        IERC20(UsdcContract).safeTransferFrom(msg.sender, owner() ,cost);

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