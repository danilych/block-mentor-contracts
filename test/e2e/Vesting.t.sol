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
        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);

        // Prepare event monitoring
        vm.expectEmit(true, true, false, true);
        emit Vesting.VestingScheduleCreated(bob, start, divisibleAmount);

        // Create vesting schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount);

        // Verify the vesting schedule was created correctly
        (
            address beneficiary,
            uint256 scheduleStart,
            uint256 periodDuration,
            uint256 totalPeriods,
            uint256 totalAmount,
            uint256 amountClaimed,
            uint256 amountPerPeriod,
            bool initialized
        ) = vesting.getVestingSchedule(bob);

        assertEq(beneficiary, bob, "Beneficiary mismatch");
        assertEq(scheduleStart, start, "Start timestamp mismatch");
        assertEq(periodDuration, PERIOD_DURATION, "Period duration mismatch");
        assertEq(totalPeriods, TOTAL_PERIODS, "Total periods mismatch");
        assertEq(totalAmount, divisibleAmount, "Total amount mismatch");
        assertEq(amountClaimed, 0, "Initial claimed amount should be zero");
        assertEq(amountPerPeriod, divisibleAmount / TOTAL_PERIODS, "Amount per period mismatch");
        assertTrue(initialized, "Schedule should be initialized");
    }

    // Test claiming tokens
    function testClaimTokens() public {
        uint256 start = block.timestamp;

        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);
        uint256 amountPerPeriod = divisibleAmount / TOTAL_PERIODS;

        // Create vesting schedule
        vm.startPrank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount);
        vm.stopPrank();

        // Advance time to the middle of the vesting period
        uint256 halfPeriods = TOTAL_PERIODS / 2;
        vm.warp(start + (halfPeriods * PERIOD_DURATION));

        // Calculate claimable amount
        uint256 claimableAmount = vesting.calculateClaimableAmount(bob);
        assertEq(claimableAmount, halfPeriods * amountPerPeriod, "Claimable amount mismatch");

        // Prepare event monitoring
        vm.expectEmit(true, false, false, true);
        emit Vesting.TokensClaimed(bob, claimableAmount);

        // Claim tokens
        vm.prank(bob);
        vesting.claimTokens();

        // Verify token balance updated
        assertEq(token.balanceOf(bob), claimableAmount, "Bob's token balance mismatch");

        // Verify vesting schedule updated
        (,,,,, uint256 amountClaimed,,) = vesting.getVestingSchedule(bob);
        assertEq(amountClaimed, claimableAmount, "Amount claimed mismatch");

        // No more tokens available to claim
        assertEq(vesting.calculateClaimableAmount(bob), 0, "Should be no more tokens to claim");

        // Advance time to the end of the vesting period
        vm.warp(start + (TOTAL_PERIODS * PERIOD_DURATION));

        // Calculate new claimable amount
        uint256 remainingAmount = divisibleAmount - claimableAmount;
        assertEq(vesting.calculateClaimableAmount(bob), remainingAmount, "Remaining claimable amount mismatch");

        // Claim remaining tokens
        vm.prank(bob);
        vesting.claimTokens();

        // Verify all tokens have been claimed
        assertEq(token.balanceOf(bob), divisibleAmount, "Bob should have all tokens");
    }

    // Test calculating claimable amount
    function testCalculateClaimableAmount() public {
        uint256 start = block.timestamp;

        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);
        uint256 amountPerPeriod = divisibleAmount / TOTAL_PERIODS;

        // Setup vesting schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount);

        // No tokens claimable at start
        assertEq(vesting.calculateClaimableAmount(bob), 0, "No tokens should be claimable at start");

        // After 1 period
        vm.warp(start + PERIOD_DURATION);
        assertEq(vesting.calculateClaimableAmount(bob), amountPerPeriod, "Wrong claimable amount after 1 period");

        // After 2 periods
        vm.warp(start + (2 * PERIOD_DURATION));
        assertEq(vesting.calculateClaimableAmount(bob), 2 * amountPerPeriod, "Wrong claimable amount after 2 periods");

        // After all periods
        vm.warp(start + (TOTAL_PERIODS * PERIOD_DURATION));
        assertEq(
            vesting.calculateClaimableAmount(bob), divisibleAmount, "All tokens should be claimable after all periods"
        );

        // Claim tokens
        vm.prank(bob);
        vesting.claimTokens();

        // After claiming all tokens, no more should be claimable
        assertEq(vesting.calculateClaimableAmount(bob), 0, "No more tokens should be claimable after claiming all");

        // Even after more time passes, still no more tokens can be claimed
        vm.warp(start + ((TOTAL_PERIODS + 1) * PERIOD_DURATION));
        assertEq(vesting.calculateClaimableAmount(bob), 0, "No more tokens should be claimable after claiming all");
    }

    // Test validation: Zero address
    function testRevertWithZeroAddress() public {
        uint256 start = block.timestamp;

        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);

        vm.prank(alice);
        vm.expectRevert(Errors.ZeroAddress.selector);
        vesting.createVestingSchedule(address(0), start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount);
    }

    // Test validation: Zero period duration
    function testRevertWithZeroPeriodDuration() public {
        uint256 start = block.timestamp;

        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);

        vm.prank(alice);
        vm.expectRevert(Errors.ZeroPeriodDuration.selector);
        vesting.createVestingSchedule(
            bob,
            start,
            0, // Zero period duration
            TOTAL_PERIODS,
            divisibleAmount
        );
    }

    // Test validation: Zero total periods
    function testRevertWithZeroTotalPeriods() public {
        uint256 start = block.timestamp;

        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_AMOUNT;

        vm.prank(alice);
        vm.expectRevert(Errors.ZeroTotalPeriods.selector);
        vesting.createVestingSchedule(
            bob,
            start,
            PERIOD_DURATION,
            0, // Zero total periods
            divisibleAmount
        );
    }

    // Test validation: Zero total amount
    function testRevertWithZeroTotalAmount() public {
        uint256 start = block.timestamp;

        vm.prank(alice);
        vm.expectRevert(Errors.ZeroTotalAmount.selector);
        vesting.createVestingSchedule(
            bob,
            start,
            PERIOD_DURATION,
            TOTAL_PERIODS,
            0 // Zero total amount
        );
    }

    // Test validation: Amount not divisible
    function testRevertWithAmountNotDivisible() public {
        uint256 start = block.timestamp;

        // Make sure amount is not divisible by total periods
        uint256 notDivisibleAmount = TOTAL_AMOUNT;
        if (notDivisibleAmount % TOTAL_PERIODS == 0) {
            notDivisibleAmount += 1;
        }

        vm.prank(alice);
        vm.expectRevert(Errors.AmountNotDivisible.selector);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, notDivisibleAmount);
    }

    // Test validation: Schedule already exists
    function testRevertWhenScheduleAlreadyExists() public {
        uint256 start = block.timestamp;

        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);

        // Create the schedule first time
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount);

        // Try to create the same schedule again
        vm.prank(alice);
        vm.expectRevert(Errors.ScheduleAlreadyExists.selector);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount);
    }

    // Test validation: No vesting schedule found when claiming
    function testRevertWhenNoScheduleFoundClaiming() public {
        vm.prank(bob);
        vm.expectRevert(Errors.NoVestingScheduleFound.selector);
        vesting.claimTokens();
    }

    // Test validation: No tokens available to claim
    function testRevertWhenNoTokensToClaim() public {
        uint256 start = block.timestamp;

        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);

        // Create vesting schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount);

        // Try to claim tokens before any are available
        vm.prank(bob);
        vm.expectRevert(Errors.NoTokensAvailableToClaim.selector);
        vesting.claimTokens();
    }

    // Test multiple beneficiaries
    function testMultipleBeneficiaries() public {
        uint256 start = block.timestamp;

        // Half for each beneficiary
        uint256 bobAmount = (TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS)) / 2;
        uint256 carolAmount = bobAmount;

        // Create vesting schedules
        vm.startPrank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, bobAmount);
        vesting.createVestingSchedule(carol, start, PERIOD_DURATION, TOTAL_PERIODS, carolAmount);
        vm.stopPrank();

        // Advance time to the end of vesting
        vm.warp(start + (TOTAL_PERIODS * PERIOD_DURATION));

        // Both beneficiaries claim their tokens
        vm.prank(bob);
        vesting.claimTokens();

        vm.prank(carol);
        vesting.claimTokens();

        // Verify token balances
        assertEq(token.balanceOf(bob), bobAmount, "Bob's token balance mismatch");
        assertEq(token.balanceOf(carol), carolAmount, "Carol's token balance mismatch");
    }

    // Test claiming in multiple transactions
    function testClaimingInMultipleTransactions() public {
        uint256 start = block.timestamp;

        // Ensure total amount is divisible by the number of periods
        uint256 divisibleAmount = TOTAL_PERIODS * (TOTAL_AMOUNT / TOTAL_PERIODS);
        uint256 amountPerPeriod = divisibleAmount / TOTAL_PERIODS;

        // Create vesting schedule
        vm.prank(alice);
        vesting.createVestingSchedule(bob, start, PERIOD_DURATION, TOTAL_PERIODS, divisibleAmount);

        // Claim after each period
        for (uint256 i = 1; i <= TOTAL_PERIODS; i++) {
            vm.warp(start + (i * PERIOD_DURATION));

            uint256 expectedClaimable = amountPerPeriod;
            assertEq(vesting.calculateClaimableAmount(bob), expectedClaimable, "Claimable amount mismatch");

            vm.prank(bob);
            vesting.claimTokens();

            assertEq(token.balanceOf(bob), i * amountPerPeriod, "Bob's token balance mismatch");
        }

        // Verify all tokens have been claimed
        assertEq(token.balanceOf(bob), divisibleAmount, "Bob should have all tokens");
    }
}
