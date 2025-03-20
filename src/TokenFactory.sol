// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";

import { Token } from "./tokens/Token.sol";
import { Errors } from "./libraries/Errors.sol";

contract TokenFactory is Ownable {
    event TokenCreated(address indexed owner, address indexed token, string name, string ticker, uint256 initialAmount);

    constructor() Ownable(msg.sender) { }

    function createToken(string memory name, string memory ticker, uint256 initialAmount) public {
        if (bytes(name).length == 0) {
            revert Errors.InvalidTokenName();
        }
        if (bytes(ticker).length == 0) {
            revert Errors.InvalidTokenTicker();
        }
        if (initialAmount == 0) {
            revert Errors.InvalidInitialAmount();
        }

        Token token = new Token(name, ticker, msg.sender, initialAmount);

        emit TokenCreated(msg.sender, address(token), name, ticker, initialAmount);
    }
}
