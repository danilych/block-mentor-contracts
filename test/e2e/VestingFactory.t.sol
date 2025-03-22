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
        assertEq(vesting.owner(), alice, "Owner mismatch");
    }

    // Test vesting contract creation with schedule
    function testCreateVestingContractWithSchedule() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // First, transfer tokens from Alice to the factory
        vm.startPrank(alice);
        token.transfer(address(vestingFactory), TOTAL_AMOUNT);

        // Now create the vesting contract with schedule
        address vestingAddress = vestingFactory.createVestingContractWithSchedule(
            address(token), bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts
        );
        vm.stopPrank();

        // Verify vesting contract
        Vesting vesting = Vesting(vestingAddress);
        assertEq(address(vesting.token()), address(token), "Token address mismatch");

        // Verify schedule creation - break this into smaller sections to avoid stack too deep
        verifyVestingSchedule(vesting, bob, start);

        // Check token balances
        assertEq(token.balanceOf(vestingAddress), TOTAL_AMOUNT, "Vesting contract should hold tokens");
    }

    // Helper function to verify vesting schedule to avoid stack too deep errors
    function verifyVestingSchedule(Vesting vesting, address beneficiary, uint256 expectedStart) internal view {
        (
            address scheduleBeneficiary,
            uint256 scheduleStart,
            uint256 periodDuration,
            uint256 totalPeriods,
            uint256 totalAmount,
            uint256 amountClaimed,
            uint256[] memory storedUnlockAmounts,
            bool initialized
        ) = vesting.getVestingSchedule(beneficiary);

        assertEq(scheduleBeneficiary, beneficiary, "Beneficiary mismatch");
        assertEq(scheduleStart, expectedStart, "Start timestamp mismatch");
        assertEq(periodDuration, PERIOD_DURATION, "Period duration mismatch");
        assertEq(totalPeriods, TOTAL_PERIODS, "Total periods mismatch");
        assertEq(totalAmount, TOTAL_AMOUNT, "Total amount mismatch");
        assertEq(amountClaimed, 0, "Initial claimed amount should be zero");
        assertTrue(initialized, "Schedule should be initialized");

        // Check that we have the right number of unlock amounts
        assertEq(storedUnlockAmounts.length, TOTAL_PERIODS, "Unlock amounts length mismatch");

        // Check the total of unlock amounts
        uint256 totalUnlocked = 0;
        for (uint256 i = 0; i < storedUnlockAmounts.length; i++) {
            totalUnlocked += storedUnlockAmounts[i];
        }
        assertEq(totalUnlocked, TOTAL_AMOUNT, "Total unlock amounts should equal total amount");
    }

    // Test validation: Zero address token
    function testRevertWhenZeroAddressToken() public {
        vm.prank(alice);
        vm.expectRevert(Errors.ZeroAddress.selector);
        vestingFactory.createVestingContract(address(0));
    }

    // Test creating multiple vesting contracts for the same token
    function testMultipleVestingContractsForSameToken() public {
        // Create first vesting contract
        vm.prank(alice);
        address firstVestingAddress = vestingFactory.createVestingContract(address(token));

        // Create second vesting contract
        vm.prank(bob);
        address secondVestingAddress = vestingFactory.createVestingContract(address(token));

        // Verify they are different contracts
        assertTrue(firstVestingAddress != secondVestingAddress, "Vesting contract addresses should be different");

        // Verify both contracts have the correct token
        Vesting firstVesting = Vesting(firstVestingAddress);
        Vesting secondVesting = Vesting(secondVestingAddress);

        assertEq(address(firstVesting.token()), address(token), "First vesting token mismatch");
        assertEq(address(secondVesting.token()), address(token), "Second vesting token mismatch");

        // Verify ownership
        assertEq(firstVesting.owner(), alice, "First vesting owner should be alice");
        assertEq(secondVesting.owner(), bob, "Second vesting owner should be bob");
    }

    // Test gas usage for vesting contract creation
    function testGasUsageForVestingContractCreation() public {
        uint256 startGas = gasleft();

        vm.prank(alice);
        vestingFactory.createVestingContract(address(token));

        uint256 gasUsed = startGas - gasleft();
        console2.log("Gas used for vesting contract creation:", gasUsed);
    }

    // Test gas usage for vesting contract creation with schedule
    function testGasUsageForVestingContractWithSchedule() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // First, transfer tokens from Alice to the factory
        vm.startPrank(alice);
        token.transfer(address(vestingFactory), TOTAL_AMOUNT);

        uint256 startGas = gasleft();

        vestingFactory.createVestingContractWithSchedule(
            address(token), bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts
        );
        vm.stopPrank();

        uint256 gasUsed = startGas - gasleft();
        console2.log("Gas used for vesting contract creation with schedule:", gasUsed);
    }
}
