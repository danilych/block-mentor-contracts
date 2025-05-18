// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/utils/ReentrancyGuard.sol";

import {Errors} from "./libraries/Errors.sol";

/// @title Token Presale Contract
/// @notice Allows a project owner to sell their ERC20 tokens in exchange for ETH
///         within a predefined time window and token cap.
/// @dev    The owner transfers the exact amount of tokens (`limit`) to this contract
///         upon deployment. Buyers send ETH and receive tokens at a fixed `price`.
contract Presale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Token being sold
    IERC20 public immutable token;

    /// @notice Price of one token in wei (‖ ETH)
    uint256 public immutable price;

    /// @notice Maximum amount of tokens to sell
    uint256 public immutable limit;

    /// @notice Timestamp when the presale starts (inclusive)
    uint256 public immutable start;

    /// @notice Timestamp when the presale ends (exclusive)
    uint256 public immutable end;

    /// @notice Total amount of tokens already sold
    uint256 public tokensSold;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event UnsoldTokensWithdrawn(uint256 amount);

    /// @dev Ensures the presale is active
    modifier saleActive() {
        if (block.timestamp < start || block.timestamp >= end)
            revert Errors.SaleNotActive();
        if (tokensSold >= limit) revert Errors.InsufficientTokensAvailable();
        _;
    }

    /// @param _token  Address of the ERC20 token to sell
    /// @param _price  Price of one token in wei
    /// @param _limit  Amount of tokens allocated for the presale
    /// @param _start  Start timestamp (unix)
    /// @param _end    End timestamp (unix)
    constructor(
        address _token,
        uint256 _price,
        uint256 _limit,
        uint256 _start,
        uint256 _end
    ) Ownable(msg.sender) {
        if (_token == address(0)) revert Errors.ZeroAddress();
        if (_price == 0) revert Errors.InvalidInitialAmount();
        if (_limit == 0) revert Errors.InvalidInitialAmount();
        if (_start >= _end) revert Errors.InvalidInitialAmount();

        token = IERC20(_token);
        price = _price;
        limit = _limit;
        start = _start;
        end = _end;

        // Transfer tokens from deployer to contract
        token.safeTransferFrom(msg.sender, address(this), _limit);
    }

    /// @notice Buy tokens by sending the exact ETH amount (`msg.value`)
    /// @dev    The sent ETH must be an exact multiple of `price`.
    function buyTokens() external payable nonReentrant saleActive {
        if (msg.value == 0) revert Errors.IncorrectETHSent();

        uint256 amount = msg.value / price;
        if (amount == 0 || msg.value != amount * price)
            revert Errors.IncorrectETHSent();
        if (tokensSold + amount > limit)
            revert Errors.InsufficientTokensAvailable();

        tokensSold += amount;
        token.safeTransfer(msg.sender, amount);

        emit TokensPurchased(msg.sender, amount, msg.value);
    }

    /// @notice Withdraw collected ETH proceeds to the owner
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.NoFundsAvailable();
        payable(owner()).transfer(balance);
        emit FundsWithdrawn(owner(), balance);
    }

    /// @notice Withdraw unsold tokens after the presale ends
    function withdrawUnsoldTokens() external onlyOwner {
        if (block.timestamp < end) revert Errors.SaleNotEnded();
        uint256 unsold = token.balanceOf(address(this));
        if (unsold == 0) revert Errors.InsufficientTokensAvailable();
        token.safeTransfer(owner(), unsold);
        emit UnsoldTokensWithdrawn(unsold);
    }
}
