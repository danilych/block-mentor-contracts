// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

library Errors {
    error InvalidTokenName();
    error InvalidTokenTicker();
    error InvalidInitialAmount();

    // Vesting errors
    error ZeroAddress();
    error ZeroPeriodDuration();
    error ZeroTotalPeriods();
    error ZeroTotalAmount();
    error UnlockAmountsMismatch();
    error ScheduleAlreadyExists();
    error UnlockAmountsNotEqualTotal();
    error PercentagesNotEqual100();
    error NoVestingScheduleFound();
    error NoTokensAvailableToClaim();
    error InvalidTokenContract();
    error AmountNotDivisible();
}
