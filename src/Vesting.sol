// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { IERC20 } from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin-contracts/utils/ReentrancyGuard.sol";
import { Errors } from "./libraries/Errors.sol";

contract Vesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct VestingSchedule {
        address beneficiary; // Address of the beneficiary
        uint256 start; // Start timestamp
        uint256 periodDuration; // Duration of each period in seconds
        uint256 totalPeriods; // Total number of periods
        uint256 totalAmount; // Total amount of tokens to be vested
        uint256 amountClaimed; // Amount of tokens already claimed
        uint256[] unlockAmounts; // Amount to unlock for each period
        bool initialized; // Whether the schedule is initialized
    }

    // Token being vested
    IERC20 public token;

    // Mapping from beneficiary to their vesting schedule
    mapping(address => VestingSchedule) public vestingSchedules;

    // Events
    event VestingScheduleCreated(address indexed beneficiary, uint256 start, uint256 totalAmount);
    event TokensClaimed(address indexed beneficiary, uint256 amount);

    /**
     * @param _token The token being vested
     * @param initialOwner The owner of the contract
     */
    constructor(address _token, address initialOwner) Ownable(initialOwner) {
        if (_token == address(0)) revert Errors.ZeroAddress();
        token = IERC20(_token);
    }

    /**
     * @notice Creates a vesting schedule
     * @param _beneficiary Address of the beneficiary
     * @param _start Start timestamp of the vesting
     * @param _periodDuration Duration of each period in seconds
     * @param _totalPeriods Total number of periods
     * @param _totalAmount Total amount of tokens to be vested
     * @param _unlockAmounts Array of amounts to unlock for each period
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _periodDuration,
        uint256 _totalPeriods,
        uint256 _totalAmount,
        uint256[] calldata _unlockAmounts
    ) external nonReentrant {
        if (_beneficiary == address(0)) revert Errors.ZeroAddress();
        if (_periodDuration == 0) revert Errors.ZeroPeriodDuration();
        if (_totalPeriods == 0) revert Errors.ZeroTotalPeriods();
        if (_totalAmount == 0) revert Errors.ZeroTotalAmount();
        if (_unlockAmounts.length != _totalPeriods) revert Errors.UnlockAmountsMismatch();
        if (vestingSchedules[_beneficiary].initialized) revert Errors.ScheduleAlreadyExists();

        uint256 totalUnlockAmount = 0;
        for (uint256 i = 0; i < _unlockAmounts.length; i++) {
            totalUnlockAmount += _unlockAmounts[i];
        }
        if (totalUnlockAmount != _totalAmount) revert Errors.UnlockAmountsNotEqualTotal();

        // Transfer tokens from sender to this contract
        token.safeTransferFrom(msg.sender, address(this), _totalAmount);

        vestingSchedules[_beneficiary] = VestingSchedule({
            beneficiary: _beneficiary,
            start: _start,
            periodDuration: _periodDuration,
            totalPeriods: _totalPeriods,
            totalAmount: _totalAmount,
            amountClaimed: 0,
            unlockAmounts: _unlockAmounts,
            initialized: true
        });

        emit VestingScheduleCreated(_beneficiary, _start, _totalAmount);
    }

    /**
     * @notice Calculates the amount of tokens that have vested but not yet been claimed
     * @param _beneficiary Address of the beneficiary
     * @return The amount of tokens that can be claimed
     */
    function calculateClaimableAmount(address _beneficiary) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        if (!schedule.initialized) {
            return 0;
        }

        if (block.timestamp < schedule.start) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - schedule.start;
        uint256 completedPeriods = elapsedTime / schedule.periodDuration;

        if (completedPeriods >= schedule.totalPeriods) {
            // All periods completed
            return schedule.totalAmount - schedule.amountClaimed;
        }

        uint256 vestedAmount = 0;
        for (uint256 i = 0; i < completedPeriods; i++) {
            vestedAmount += schedule.unlockAmounts[i];
        }

        return vestedAmount - schedule.amountClaimed;
    }

    /**
     * @notice Claims vested tokens
     */
    function claimTokens() external nonReentrant {
        address beneficiary = msg.sender;
        VestingSchedule storage schedule = vestingSchedules[beneficiary];

        if (!schedule.initialized) revert Errors.NoVestingScheduleFound();

        uint256 claimableAmount = calculateClaimableAmount(beneficiary);
        if (claimableAmount == 0) revert Errors.NoTokensAvailableToClaim();

        schedule.amountClaimed += claimableAmount;

        token.safeTransfer(beneficiary, claimableAmount);

        emit TokensClaimed(beneficiary, claimableAmount);
    }

    /**
     * @notice Returns the vesting schedule for a beneficiary
     * @param _beneficiary Address of the beneficiary
     */
    function getVestingSchedule(address _beneficiary)
        external
        view
        returns (
            address beneficiary,
            uint256 start,
            uint256 periodDuration,
            uint256 totalPeriods,
            uint256 totalAmount,
            uint256 amountClaimed,
            uint256[] memory unlockAmounts,
            bool initialized
        )
    {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        return (
            schedule.beneficiary,
            schedule.start,
            schedule.periodDuration,
            schedule.totalPeriods,
            schedule.totalAmount,
            schedule.amountClaimed,
            schedule.unlockAmounts,
            schedule.initialized
        );
    }
}
