// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { VestingFactory } from "../src/VestingFactory.sol";
import { Token } from "../src/tokens/Token.sol";
import { Actors } from "./utils/Actors.sol";
import { Test } from "forge-std/Test.sol";

contract VestingFactoryTest is Actors {
    // Test state variables
    VestingFactory public vestingFactory;
    Token public token;

    // Vesting parameters
    uint256 constant PERIOD_DURATION = 30 days;
    uint256 constant TOTAL_PERIODS = 4;
    uint256 constant TOTAL_AMOUNT = 1000 * 10 ** 18; // 1000 tokens with 18 decimals

    // Setup the fixture that can be reused across tests
    function fixture() public virtual {
        // Deploy a token for testing with alice as the initial holder to avoid transfer issues
        vm.startPrank(deployer);
        token = new Token("Test Token", "TST", alice, TOTAL_AMOUNT * 10);

        // Deploy the vesting factory
        vestingFactory = new VestingFactory();
        vm.stopPrank();
    }
}
