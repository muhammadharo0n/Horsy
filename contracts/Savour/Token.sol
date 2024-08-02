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
import "hardhat/console.sol";

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
        uint EnteredValue;
        uint priceOfCurrency;
        uint amountOfTokens;
        bool saleAvtive;
        currency choice;
        
    }
    struct Sale_1_tokens{ 
        uint price;
        uint startTime;
        uint endTime;
        uint supplyAvailable;
        bool saleActive;
    }

    struct Sale_2_tokens{ 
        uint price;
        uint startTime;
        uint endTime;
        uint supplyAvailable;
        bool saleActive;
    }

    mapping (address userAddress=> mapping(uint transectionNumber=> userRecord)) public TokenRecord;
    mapping (currency => uint) _currencyCoice;
    mapping (address =>uint) public NumberOfBuying;
    mapping (address => Sale_1_tokens) public pre_Sale_1_mapping;
    mapping (address => Sale_2_tokens) public pre_Sale_2_mapping;
    enum currency{USDT, BNB}
        
    event TokenPurchased(address indexed buyer, uint amount, currency choice, address mintContract);


    constructor(address ownerAddress, address _UsdcContract) ERC20("Time Village Token", "TVT") Ownable(ownerAddress){
    _mint(msg.sender, 100 * 10 ** decimals());
    // priceFeed = AggregatorV3Interface(0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22);
    UsdcContract = _UsdcContract;
    }

    //ADMIN START

    function AdminAddToken(uint _amount) public onlyOwner{
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this) ,_amount);
    }

    // END
    function preSale_1_Listing(uint _price, uint endTime, address mintContract) public { 

       
        pre_Sale_1_mapping[mintContract] = Sale_1_tokens(_price, block.timestamp, endTime, ((totalSupply() *1000000) / 100)/ (10 ** decimals()), true);

    }

    function preSale_2_Listing(uint _price, uint endTime, address mintContract) public { 

        pre_Sale_2_mapping[mintContract] = Sale_2_tokens(_price, block.timestamp, endTime, ((totalSupply() *1000000) / 100)/ (10 ** decimals()), true);

    }

    function buyTokens( uint amount, currency choice, address mintContract) public nonReentrant {
        console.log(block.timestamp);
        // require(block.timestamp <= pre_Sale_1_mapping[mintContract].endTime, "Minting time exceeded");
        require(block.timestamp< pre_Sale_1_mapping[mintContract].endTime, "Pre sale 1 finished");
        require( pre_Sale_1_mapping[mintContract].supplyAvailable <= 10000000 , "Presale 1 token Finished");
        require(_currencyCoice[choice]==1 || _currencyCoice[choice]==0, "Payment should be in USDT or BNB");
        require( pre_Sale_1_mapping[mintContract].saleActive = true , "You cannot mint token right now");

        // require(pre_Sale_1_mapping[mintContract].supplyAvailable == 0, "Presale 1 did not completed");

        // require(pre_Sale_2_mapping[mintContract].supplyAvailable == 0, "Presale 2 did not completed");
        
        // require(block.timestamp <= pre_Sale_2_mapping[mintContract].endTime, "Minting time exceeded");
        require(block.timestamp< pre_Sale_2_mapping[mintContract].endTime, "Pre sale 2 finished");
        require( pre_Sale_2_mapping[mintContract].supplyAvailable <= 100 , "Presale 2 token Finished");
        require( pre_Sale_2_mapping[mintContract].saleActive = true , "You cannot mint token right now");

        // require(pre_Sale_2_mapping[mintContract].supplyAvailable == 0, "Presale 2 did not completed");
        
        uint256 currencyinUSDT = 5;
        uint currencyinBNB = 7;
        uint amountOfTokens;
        _currencyCoice[currency.USDT] = 0;
        _currencyCoice[currency.BNB] = 1;
        numberOfTransactions.increment();
        console.log(amount);

        if(pre_Sale_1_mapping[mintContract].saleActive = true){
        if(_currencyCoice[choice] == 0){
            amountOfTokens = ((currencyinUSDT / pre_Sale_1_mapping[mintContract].price) * amount);

            (amountOfTokens * 10^18);
        }

        if(_currencyCoice[choice] ==  1){ 
            amountOfTokens = (currencyinBNB / pre_Sale_1_mapping[mintContract].price) * amount;
            (amountOfTokens * 10^18);

        }
    }   if(pre_Sale_2_mapping[mintContract].saleActive = true){
   
        if(_currencyCoice[choice] == 0){
            amountOfTokens = ((currencyinUSDT / pre_Sale_2_mapping[mintContract].price) * amount);

            (amountOfTokens * 10^18);
        }
        if(_currencyCoice[choice] ==  1){ 
            amountOfTokens = (currencyinBNB / pre_Sale_2_mapping[mintContract].price) * amount;
            (amountOfTokens * 10^18);

        }
    } 


        NumberOfBuying[msg.sender]++;
        uint currentTransactionCount = NumberOfBuying[msg.sender];
        TokenRecord[msg.sender][currentTransactionCount] = userRecord(msg.sender, amount, _currencyCoice[choice] == 0 ? currencyinUSDT : currencyinBNB, amountOfTokens, true, choice);
        pre_Sale_1_mapping[mintContract].supplyAvailable = pre_Sale_1_mapping[mintContract].supplyAvailable - (amountOfTokens);
        pre_Sale_2_mapping[mintContract].supplyAvailable = pre_Sale_2_mapping[mintContract].supplyAvailable - (amountOfTokens);
        IERC20(address(this)).transfer(msg.sender,amountOfTokens);
        IERC20(UsdcContract).safeTransferFrom(msg.sender, owner() ,amount);
        emit TokenPurchased(msg.sender, amount, choice, mintContract);
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




















