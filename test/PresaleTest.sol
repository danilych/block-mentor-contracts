// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";
import { Presale } from "../src/Presale.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract PresaleTest is Test {
    Presale public presale;
    MockERC20 public token;
    
    address public owner = address(0x1);
    address public buyer = address(0x2);
    
    uint256 public constant TOKEN_PRICE = 0.1 ether;
    uint256 public constant TOKEN_LIMIT = 1000 * 1e18; // 1000 tokens
    uint256 public constant PRESALE_DURATION = 7 days;
    
    function setUp() public {
        // Set up the test environment
        vm.startPrank(owner);
        
        // Deploy a mock ERC20 token
        token = new MockERC20("Test Token", "TEST", 18);
        
        // Mint tokens to the owner
        token.mint(owner, TOKEN_LIMIT);
        
        // Calculate timestamps
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + PRESALE_DURATION;
        
        // Deploy the presale contract
        presale = new Presale(
            address(token),
            TOKEN_PRICE,
            TOKEN_LIMIT,
            startTime,
            endTime
        );
        
        // Approve the presale contract to spend owner's tokens
        token.approve(address(presale), TOKEN_LIMIT);
        
        vm.stopPrank();
    }
    
    function test_InitialState() public {
        assertEq(address(presale.token()), address(token));
        assertEq(presale.price(), TOKEN_PRICE);
        assertEq(presale.limit(), TOKEN_LIMIT);
        assertEq(presale.tokensSold(), 0);
    }
    
    function test_BuyTokens() public {
        uint256 buyAmount = 5;
        uint256 ethAmount = buyAmount * TOKEN_PRICE;
        
        // Fast forward to start time
        vm.warp(presale.start());
        
        // Buy tokens
        vm.deal(buyer, ethAmount);
        vm.prank(buyer);
        (bool success,) = address(presale).call{value: ethAmount}("");
        
        assertTrue(success);
        assertEq(presale.tokensSold(), buyAmount * 1e18);
        assertEq(token.balanceOf(buyer), buyAmount * 1e18);
    }
    
    function test_BuyTokens_InvalidAmount() public {
        // Try to buy with incorrect ETH amount
        vm.warp(presale.start());
        vm.deal(buyer, 1 ether);
        
        vm.prank(buyer);
        (bool success,) = address(presale).call{value: 0.05 ether}("");
        
        assertFalse(success);
    }
    
    function test_WithdrawFunds() public {
        // First buy some tokens
        test_BuyTokens();
        
        uint256 contractBalance = address(presale).balance;
        uint256 ownerBalanceBefore = owner.balance;
        
        // Withdraw funds as owner
        vm.prank(owner);
        presale.withdrawFunds();
        
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
    }
    
    function test_WithdrawUnsoldTokens() public {
        // Fast forward past end time
        vm.warp(presale.end() + 1);
        
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 unsoldTokens = TOKEN_LIMIT - presale.tokensSold();
        
        // Withdraw unsold tokens as owner
        vm.prank(owner);
        presale.withdrawUnsoldTokens();
        
        assertEq(token.balanceOf(owner), ownerBalanceBefore + unsoldTokens);
    }
}
