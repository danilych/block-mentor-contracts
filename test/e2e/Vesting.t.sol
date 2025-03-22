// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { VestingTest } from "../VestingTest.sol";
import { Vesting } from "../../src/Vesting.sol";
import { Token } from "../../src/tokens/Token.sol";
import { Errors } from "../../src/libraries/Errors.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";

contract VestingE2ETest is VestingTest {
    // Test successful vesting schedule creation
    function testCreateVestingSchedule() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // Prepare event monitoring
        vm.expectEmit(true, true, false, true);
        emit Vesting.VestingScheduleCreated(bob, start, TOTAL_AMOUNT);

        // Create vesting schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);

        // Verify the vesting schedule was created correctly
        (
            address beneficiary,
            uint256 scheduleStart,
            uint256 periodDuration,
            uint256 totalPeriods,
            uint256 totalAmount,
            uint256 amountClaimed,
            uint256[] memory storedUnlockAmounts,
            bool initialized
        ) = vesting.getVestingSchedule(bob);

        assertEq(beneficiary, bob, "Beneficiary mismatch");
        assertEq(scheduleStart, start, "Start timestamp mismatch");
        assertEq(periodDuration, PERIOD_DURATION, "Period duration mismatch");
        assertEq(totalPeriods, TOTAL_PERIODS, "Total periods mismatch");
        assertEq(totalAmount, TOTAL_AMOUNT, "Total amount mismatch");
        assertEq(amountClaimed, 0, "Initial claimed amount should be zero");
        assertTrue(initialized, "Schedule should be initialized");

        // Check unlock amounts
        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            assertEq(storedUnlockAmounts[i], unlockAmounts[i], "Unlock amount mismatch at period");
        }

        // Check token balances
        assertEq(token.balanceOf(address(vesting)), TOTAL_AMOUNT, "Vesting contract should hold tokens");
        assertEq(token.balanceOf(alice), TOTAL_AMOUNT, "Alice should have remaining tokens");
    }

    // Test claiming tokens after periods have passed
    function testClaimTokens() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // Create vesting schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);

        // Advance time by 1 period + 1 day
        vm.warp(start + PERIOD_DURATION + 1 days);

        // Prepare event monitoring
        vm.expectEmit(true, false, false, true);
        emit Vesting.TokensClaimed(bob, amountPerPeriod);

        // Claim tokens after first period
        vm.prank(bob);
        vesting.claimTokens();

        // Verify claimed amount
        (,,,,, uint256 amountClaimed,,) = vesting.getVestingSchedule(bob);
        assertEq(amountClaimed, amountPerPeriod, "Claimed amount should match one period");
        assertEq(token.balanceOf(bob), amountPerPeriod, "Bob should have claimed tokens");

        // Advance time by another period
        vm.warp(start + PERIOD_DURATION * 2 + 1 days);

        // Prepare event monitoring for second claim
        vm.expectEmit(true, false, false, true);
        emit Vesting.TokensClaimed(bob, amountPerPeriod);

        // Claim tokens after second period
        vm.prank(bob);
        vesting.claimTokens();

        // Verify claimed amount has increased
        (,,,,, amountClaimed,,) = vesting.getVestingSchedule(bob);
        assertEq(amountClaimed, amountPerPeriod * 2, "Claimed amount should match two periods");
        assertEq(token.balanceOf(bob), amountPerPeriod * 2, "Bob should have claimed tokens from two periods");
    }

    // Test calculating claimable amount
    function testCalculateClaimableAmount() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // Create vesting schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);

        // Check initial claimable amount (should be 0 at start)
        uint256 claimable = vesting.calculateClaimableAmount(bob);
        assertEq(claimable, 0, "Initial claimable amount should be zero");

        // Advance time by 1 period + 1 day
        vm.warp(start + PERIOD_DURATION + 1 days);

        // Check claimable amount after one period
        claimable = vesting.calculateClaimableAmount(bob);
        assertEq(claimable, amountPerPeriod, "Claimable amount should be one period worth");

        // Advance time by one more period
        vm.warp(start + PERIOD_DURATION * 2 + 1 days);

        // Check claimable amount after two periods
        claimable = vesting.calculateClaimableAmount(bob);
        assertEq(claimable, amountPerPeriod * 2, "Claimable amount should be two periods worth");

        // Claim tokens after two periods
        vm.prank(bob);
        vesting.claimTokens();

        // Check claimable amount after claiming (should be 0)
        claimable = vesting.calculateClaimableAmount(bob);
        assertEq(claimable, 0, "Claimable amount should be zero after claiming");

        // Advance time to end of vesting
        vm.warp(start + PERIOD_DURATION * TOTAL_PERIODS + 1 days);

        // Check claimable amount at end
        claimable = vesting.calculateClaimableAmount(bob);
        assertEq(claimable, amountPerPeriod * 2, "Claimable amount should be remaining two periods");
    }

    // Test validation: Zero address beneficiary
    function testRevertWhenZeroAddressBeneficiary() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        vm.prank(alice);
        vm.expectRevert(Errors.ZeroAddress.selector);
        vesting.createVestingSchedule(address(0), start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);
    }

    // Test validation: Zero period duration
    function testRevertWhenZeroPeriodDuration() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        vm.prank(alice);
        vm.expectRevert(Errors.ZeroPeriodDuration.selector);
        vesting.createVestingSchedule(
            bob,
            start,
            0, // Zero period duration
            TOTAL_PERIODS,
            TOTAL_AMOUNT,
            unlockAmounts
        );
    }

    // Test validation: Zero total periods
    function testRevertWhenZeroTotalPeriods() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](1); // Need at least one element

        vm.prank(alice);
        vm.expectRevert(Errors.ZeroTotalPeriods.selector);
        vesting.createVestingSchedule(
            bob,
            start,
            PERIOD_DURATION,
            0, // Zero total periods
            TOTAL_AMOUNT,
            unlockAmounts
        );
    }

    // Test validation: Zero total amount
    function testRevertWhenZeroTotalAmount() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);

        vm.prank(alice);
        vm.expectRevert(Errors.ZeroTotalAmount.selector);
        vesting.createVestingSchedule(
            bob,
            start,
            PERIOD_DURATION,
            TOTAL_PERIODS,
            0, // Zero total amount
            unlockAmounts
        );
    }

    // Test validation: Unlock amounts mismatch
    function testRevertWhenUnlockAmountsMismatch() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS - 1); // One less than required
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS - 1; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        vm.prank(alice);
        vm.expectRevert(Errors.UnlockAmountsMismatch.selector);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);
    }

    // Test validation: Schedule already exists
    function testRevertWhenScheduleAlreadyExists() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // Create first schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);

        // Try to create a second schedule for the same beneficiary
        vm.prank(alice);
        vm.expectRevert(Errors.ScheduleAlreadyExists.selector);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);
    }

    // Test validation: Unlock amounts not equal total
    function testRevertWhenUnlockAmountsNotEqualTotal() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / (TOTAL_PERIODS - 1); // This will make total too high

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        vm.prank(alice);
        vm.expectRevert(Errors.UnlockAmountsNotEqualTotal.selector);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);
    }

    // Test validation: No vesting schedule found
    function testRevertWhenNoVestingScheduleFound() public {
        vm.prank(bob);
        vm.expectRevert(Errors.NoVestingScheduleFound.selector);
        vesting.claimTokens();
    }

    // Test validation: No tokens available to claim
    function testRevertWhenNoTokensAvailableToClaim() public {
        uint256 start = block.timestamp + 1 days; // Starts in the future
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // Create vesting schedule that starts in the future
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);

        // Try to claim before start time
        vm.prank(bob);
        vm.expectRevert(Errors.NoTokensAvailableToClaim.selector);
        vesting.claimTokens();
    }

    // Test claiming all tokens at the end of vesting
    function testClaimAllTokensAtEnd() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // Create vesting schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);

        // Advance time past the end of vesting
        vm.warp(start + PERIOD_DURATION * TOTAL_PERIODS + 1 days);

        // Prepare event monitoring
        vm.expectEmit(true, false, false, true);
        emit Vesting.TokensClaimed(bob, TOTAL_AMOUNT);

        // Claim all tokens
        vm.prank(bob);
        vesting.claimTokens();

        // Verify all tokens claimed
        (,,,,, uint256 amountClaimed,,) = vesting.getVestingSchedule(bob);
        assertEq(amountClaimed, TOTAL_AMOUNT, "All tokens should be claimed");
        assertEq(token.balanceOf(bob), TOTAL_AMOUNT, "Bob should have all tokens");
        assertEq(token.balanceOf(address(vesting)), 0, "Vesting contract should have no tokens");
    }

    // Test multiple beneficiaries
    function testMultipleBeneficiaries() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS / 2; // Half for each beneficiary

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // Create vesting schedule for Bob
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT / 2, unlockAmounts);

        // Create vesting schedule for Carol
        vm.prank(alice);
        vesting.createVestingSchedule(carol, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT / 2, unlockAmounts);

        // Advance time past the first period
        vm.warp(start + PERIOD_DURATION + 1 days);

        // Both beneficiaries claim
        vm.prank(bob);
        vesting.claimTokens();

        vm.prank(carol);
        vesting.claimTokens();

        // Verify both claimed the correct amounts
        assertEq(token.balanceOf(bob), amountPerPeriod, "Bob should have claimed first period");
        assertEq(token.balanceOf(carol), amountPerPeriod, "Carol should have claimed first period");
    }

    // Test gas usage
    function testGasUsageForCreatingVestingSchedule() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        uint256 startGas = gasleft();

        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);

        uint256 gasUsed = startGas - gasleft();
        console2.log("Gas used for creating vesting schedule:", gasUsed);
    }

    // Test gas usage for claiming
    function testGasUsageForClaimingTokens() public {
        uint256 start = block.timestamp;
        uint256[] memory unlockAmounts = new uint256[](TOTAL_PERIODS);
        uint256 amountPerPeriod = TOTAL_AMOUNT / TOTAL_PERIODS;

        for (uint256 i = 0; i < TOTAL_PERIODS; i++) {
            unlockAmounts[i] = amountPerPeriod;
        }

        // Create vesting schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, TOTAL_AMOUNT, unlockAmounts);

        // Advance time
        vm.warp(start + PERIOD_DURATION + 1 days);

        uint256 startGas = gasleft();

        vm.prank(bob);
        vesting.claimTokens();

        uint256 gasUsed = startGas - gasleft();
        console2.log("Gas used for claiming tokens:", gasUsed);
    }
}
