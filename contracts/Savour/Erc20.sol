// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20FlashMint {
    constructor(address initialOwner)
        ERC20("USD", "USDT")
        Ownable(initialOwner)
        ERC20Permit("USDT")
    {}

    function mint() public {
        _mint(msg.sender, 1000 *1e18);
    }
}