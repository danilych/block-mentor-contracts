// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { VestingFactoryTest } from "../VestingFactoryTest.sol";
import { Vesting } from "../../src/Vesting.sol";
import { Token } from "../../src/tokens/Token.sol";
import { Errors } from "../../src/libraries/Errors.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";

contract VestingFactoryE2ETest is VestingFactoryTest {
    // Setup the fixture that can be reused across tests
    function setUp() public {
        fixture();
    }

    // Test successful vesting contract creation
    function testCreateVestingContract() public {
        // Record logs to verify event emission
        vm.recordLogs();

        // Create vesting contract
        vm.prank(alice);
        address vestingAddress = vestingFactory.createVestingContract(address(token));

        // Get the logs to find and verify the event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 eventSig = keccak256("VestingContractCreated(address,address,address)");

        bool foundEvent = false;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == eventSig) {
                // Check indexed parameters
                assertEq(address(uint160(uint256(entries[i].topics[1]))), alice, "Event owner mismatch");
                assertEq(
                    address(uint160(uint256(entries[i].topics[2]))), vestingAddress, "Vesting contract address mismatch"
                );
                assertEq(address(uint160(uint256(entries[i].topics[3]))), address(token), "Token address mismatch");
                foundEvent = true;
                break;
            }
        }

        assertTrue(foundEvent, "VestingContractCreated event not found");

        // Verify the vesting contract was created correctly
        assertTrue(vestingAddress != address(0), "Vesting contract address should not be zero");

        // Verify vesting contract properties
        Vesting vesting = Vesting(vestingAddress);
        assertEq(address(vesting.token()), address(token), "Token address mismatch");
    }

    // Test creating a vesting contract with schedule in one transaction
    function testCreateVestingContractWithSchedule() public {
        uint256 start = block.timestamp;
        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);

        // First, transfer tokens from Alice to the factory
        vm.startPrank(alice);
        token.transfer(address(vestingFactory), divisibleAmount);

        // Now create the vesting contract with schedule
        address vestingAddress = vestingFactory.createVestingContractWithSchedule(
            address(token), bob, start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount
        );
        vm.stopPrank();

        // Verify vesting contract
        Vesting vesting = Vesting(vestingAddress);
        assertEq(address(vesting.token()), address(token), "Token address mismatch");

        // Verify schedule creation - break this into smaller sections to avoid stack too deep
        verifyVestingSchedule(vesting, bob, start, divisibleAmount);

        // Check token balances
        assertEq(token.balanceOf(vestingAddress), divisibleAmount, "Vesting contract should hold tokens");
    }

    // Helper function to verify vesting schedule to avoid stack too deep errors
    function verifyVestingSchedule(Vesting vesting, address beneficiary, uint256 expectedStart, uint256 expectedAmount)
        internal
        view
    {
        (
            address scheduleBeneficiary,
            uint256 scheduleStart,
            uint256 periodDuration,
            uint256 totalPeriods,
            uint256 totalAmount,
            uint256 amountClaimed,
            uint256 amountPerPeriod,
            bool initialized
        ) = vesting.getVestingSchedule(beneficiary);

        assertEq(scheduleBeneficiary, beneficiary, "Beneficiary mismatch");
        assertEq(scheduleStart, expectedStart, "Start timestamp mismatch");
        assertEq(periodDuration, PERIOD_DURATION, "Period duration mismatch");
        assertEq(totalPeriods, TOTAL_PERIODS, "Total periods mismatch");
        assertEq(totalAmount, expectedAmount, "Total amount mismatch");
        assertEq(amountClaimed, 0, "Initial claimed amount should be zero");
        assertEq(amountPerPeriod, expectedAmount / TOTAL_PERIODS, "Amount per period mismatch");
        assertTrue(initialized, "Schedule should be initialized");
    }

    // Test creating multiple vesting contracts for the same token
    function testMultipleVestingContractsForSameToken() public {
        // Create first vesting contract
        vm.prank(alice);
        address firstVestingAddress = vestingFactory.createVestingContract(address(token));

        // Create second vesting contract
        vm.prank(alice);
        address secondVestingAddress = vestingFactory.createVestingContract(address(token));

        // Verify they are different contracts
        assertTrue(firstVestingAddress != secondVestingAddress, "Should create distinct vesting contracts");

        // Verify both have the correct token
        assertEq(
            address(Vesting(firstVestingAddress).token()),
            address(token),
            "First vesting contract token address mismatch"
        );
        assertEq(
            address(Vesting(secondVestingAddress).token()),
            address(token),
            "Second vesting contract token address mismatch"
        );
    }

    // Test error case: Zero address for token
    function testRevertWithZeroAddressToken() public {
        vm.prank(alice);
        vm.expectRevert(Errors.ZeroAddress.selector);
        vestingFactory.createVestingContract(address(0));
    }

    // Test error case: Invalid token contract
    function testRevertWithInvalidTokenContract() public {
        // Create an invalid token address - must be a contract address that is not a valid ERC20 token
        address invalidTokenAddr = address(new InvalidTokenMock());

        vm.prank(alice);
        vm.expectRevert(Errors.InvalidTokenContract.selector);
        vestingFactory.createVestingContract(invalidTokenAddr);
    }

    // Test vesting contract with schedule error handling
    function testRevertCreateVestingContractWithScheduleWithInvalidArgs() public {
        uint256 start = block.timestamp;
        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);

        vm.startPrank(alice);
        token.transfer(address(vestingFactory), divisibleAmount);

        // Test with zero address for beneficiary
        vm.expectRevert(Errors.ZeroAddress.selector);
        vestingFactory.createVestingContractWithSchedule(
            address(token), address(0), start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount
        );

        vm.stopPrank();
    }
}

// Mock contract that doesn't implement ERC20 interface
contract InvalidTokenMock {
// Empty contract
}
