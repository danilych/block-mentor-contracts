// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Test, console2 } from "forge-std/Test.sol";
import { TokenFactory } from "../src/TokenFactory.sol";
import { Token } from "../src/tokens/Token.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract TokenFactoryTest is Test {
    // Test state variables
    TokenFactory public tokenFactory;
    address public owner;
    address public user1;
    address public user2;

    // Token parameters
    string constant TOKEN_NAME = "Test Token";
    string constant TOKEN_TICKER = "TST";
    uint256 constant INITIAL_AMOUNT = 1000000 * 10 ** 18; // 1 million tokens with 18 decimals

    // Setup the fixture that can be reused across tests
    function fixture() public {
        // Setup addresses
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy the contract from the owner
        vm.prank(owner);
        tokenFactory = new TokenFactory();
    }

    // Run the fixture before each test
    function setUp() public {
        fixture();
    }
}
