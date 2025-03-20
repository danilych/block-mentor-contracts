// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { ERC20 } from "@openzeppelin-contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";

contract Token is ERC20, ERC20Burnable, Ownable {
    constructor(string memory name, string memory ticker, address initialOwner, uint256 initialAmount)
        ERC20(name, ticker)
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialAmount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
