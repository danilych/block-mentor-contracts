// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { TokenFactory } from "../src/TokenFactory.sol";
import { Token } from "../src/tokens/Token.sol";
import { Actors } from "./utils/Actors.sol";

contract TokenFactoryTest is Actors {
    // Test state variables
    TokenFactory public tokenFactory;

    // Token parameters
    string constant TOKEN_NAME = "Test Token";
    string constant TOKEN_TICKER = "TST";
    uint256 constant INITIAL_AMOUNT = 1000000 * 10 ** 18; // 1 million tokens with 18 decimals

    // Setup the fixture that can be reused across tests
    function fixture() public {
        // Deploy the contract from the deployer
        vm.prank(deployer);
        tokenFactory = new TokenFactory();
    }
}
