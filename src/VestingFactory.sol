// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

import { Vesting } from "./Vesting.sol";
import { Errors } from "./libraries/Errors.sol";

contract VestingFactory is Ownable {
    using SafeERC20 for IERC20;

    event VestingContractCreated(address indexed owner, address indexed vestingContract, address indexed token);
    event VestingScheduleCreated(
        address indexed vestingContract,
        address indexed beneficiary,
        uint256 totalAmount,
        uint256 start,
        uint256 periodDuration,
        uint256 totalPeriods,
        string tokenName,
        string tokenSymbol,
        address token
    );

    constructor() Ownable(msg.sender) { }

    /**
     * @notice Creates a new vesting contract for a specific token
     * @param _token The token to be vested
     * @return The address of the created vesting contract
     */
    function createVestingContract(address _token) public returns (address) {
        if (_token == address(0)) {
            revert Errors.ZeroAddress();
        }

        // Verify the token is a valid ERC20 contract
        try IERC20(_token).totalSupply() returns (uint256) {
            // Token exists and implements totalSupply
        } catch {
            revert Errors.InvalidTokenContract();
        }

        Vesting vestingContract = new Vesting(_token, msg.sender);

        emit VestingContractCreated(msg.sender, address(vestingContract), _token);

        return address(vestingContract);
    }

    /**
     * @notice Creates a new vesting contract and sets up a vesting schedule in one transaction
     * @param _token The token to be vested
     * @param _beneficiary Address of the beneficiary
     * @param _start Start timestamp of the vesting
     * @param _periodDuration Duration of each period in seconds
     * @param _totalPeriods Total number of periods
     * @param _totalAmount Total amount of tokens to be vested
     * @return The address of the created vesting contract
     */
    function createVestingContractWithSchedule(
        address _token,
        address _beneficiary,
        uint256 _start,
        uint256 _periodDuration,
        uint256 _totalPeriods,
        uint256 _totalAmount
    ) external returns (address) {
        // Create the vesting contract
        address vestingContractAddress = createVestingContract(_token);
        Vesting vestingContract = Vesting(vestingContractAddress);

        // Transfer tokens directly from caller to the vesting contract
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _totalAmount);
        IERC20(_token).approve(vestingContractAddress, _totalAmount);

        // Create the vesting schedule
        vestingContract.createVestingSchedule(_beneficiary, _start, _periodDuration, _totalPeriods, _totalAmount);

        emit VestingScheduleCreated(
            vestingContractAddress,
            _beneficiary,
            _totalAmount,
            _start,
            _periodDuration,
            _totalPeriods,
            IERC20Metadata(_token).name(),
            IERC20Metadata(_token).symbol(),
            _token
        );

        return vestingContractAddress;
    }
}
