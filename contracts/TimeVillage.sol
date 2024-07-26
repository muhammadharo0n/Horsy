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

    struct userRecord{
        address user;
        uint amount;
        uint currency;
        bool claim;
    }

    mapping (address => mapping(uint => userRecord)) public TokenRecord;



    constructor(address ownerAddress, address _priceFeed) ERC20("Time Village Token", "TVT") Ownable(ownerAddress){
    _mint(msg.sender, 2500000000 * 10 ** decimals());
    priceFeed = AggregatorV3Interface(_priceFeed);


    }

    //ADMIN START

    function AdminAddToken(uint _amount) public onlyOwner{
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this) ,_amount);
    }

    // END

    function buyTokens(uint256 currency) public payable nonReentrant {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 amountInUSDT = uint256(answer);
        require(currency == amountInUSDT, "Incorrect amount in USDT");
        TokenRecord[address(this)][currency] = userRecord(msg.sender, currency, msg.value, true);
        payable(AddminAddress).transfer(msg.value);
        IERC20(address(this)).safeTransfer(msg.sender,amountInUSDT);
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