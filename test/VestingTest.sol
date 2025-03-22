// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Vesting } from "../src/Vesting.sol";
import { Token } from "../src/tokens/Token.sol";
import { Actors } from "./utils/Actors.sol";

contract VestingTest is Actors {
    // Test state variables
    Vesting public vesting;
    Token public token;

    // Vesting parameters
    uint256 constant PERIOD_DURATION = 30 days;
    uint256 constant TOTAL_PERIODS = 4;
    uint256 constant TOTAL_AMOUNT = 1000 * 10 ** 18; // 1000 tokens with 18 decimals

    // Setup the fixture that can be reused across tests
    function fixture() public {
        // Deploy a token for testing
        vm.prank(deployer);
        token = new Token("Test Token", "TST", deployer, TOTAL_AMOUNT * 10);

        // Deploy the vesting contract
        vm.prank(deployer);
        vesting = new Vesting(address(token), deployer);

        // Transfer tokens to alice for creating vesting schedules
        vm.prank(deployer);
        token.transfer(alice, TOTAL_AMOUNT * 2);

        // Approve token spending for the vesting contract (from alice)
        vm.prank(alice);
        token.approve(address(vesting), TOTAL_AMOUNT * 2);
    }

    // Run the fixture before each test
    function setUp() public {
        fixture();
    }
}
