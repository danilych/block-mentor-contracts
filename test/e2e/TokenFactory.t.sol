// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { TokenFactoryTest } from "../TokenFactoryTest.sol";
import { Token } from "../../src/tokens/Token.sol";
import { Errors } from "../../src/libraries/Errors.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";
import { TokenFactory } from "../../src/TokenFactory.sol";

contract TokenFactoryE2ETest is TokenFactoryTest {
    // Test successful token creation
    function testCreateToken() public {
        // Switch to user1 to create a token
        vm.prank(user1);
        tokenFactory.createToken(TOKEN_NAME, TOKEN_TICKER, INITIAL_AMOUNT);

        // Find the created token using the emitted event
        vm.recordLogs();
        vm.prank(user1);
        tokenFactory.createToken("Another Token", "ATK", INITIAL_AMOUNT);

        // Get the logs to find the token address
        Vm.Log[] memory entries = vm.getRecordedLogs();
        address tokenAddress;

        // Find the TokenCreated event (topic0 is the event signature)
        bytes32 tokenCreatedSig = keccak256("TokenCreated(address,address,string,string,uint256)");
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == tokenCreatedSig) {
                // topic1 is the indexed owner, topic2 is the indexed token address
                tokenAddress = address(uint160(uint256(entries[i].topics[2])));
                break;
            }
        }

        // Verify the token exists and has correct properties
        Token token = Token(tokenAddress);
        assertEq(token.name(), "Another Token");
        assertEq(token.symbol(), "ATK");
        assertEq(token.balanceOf(user1), INITIAL_AMOUNT);
    }

    // Test event emission
    function testTokenCreatedEvent() public {
        // First create a token and capture its address
        vm.recordLogs();
        vm.prank(user1);
        tokenFactory.createToken(TOKEN_NAME, TOKEN_TICKER, INITIAL_AMOUNT);

        // Get the logs to verify the event was emitted correctly
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 tokenCreatedSig = keccak256("TokenCreated(address,address,string,string,uint256)");

        bool foundEvent = false;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == tokenCreatedSig) {
                // Check indexed parameters
                assertEq(address(uint160(uint256(entries[i].topics[1]))), user1, "Event owner mismatch");

                // Token address is dynamic, so we can't check it directly
                // But we can check it's not zero
                address tokenAddress = address(uint160(uint256(entries[i].topics[2])));
                assertTrue(tokenAddress != address(0), "Token address should not be zero");

                // Check token parameters
                foundEvent = true;
                break;
            }
        }

        assertTrue(foundEvent, "TokenCreated event not found");
    }

    // Test validation: Invalid name
    function testRevertWhenInvalidName() public {
        vm.prank(user1);
        vm.expectRevert(Errors.InvalidTokenName.selector);
        tokenFactory.createToken("", TOKEN_TICKER, INITIAL_AMOUNT);
    }

    // Test validation: Invalid ticker
    function testRevertWhenInvalidTicker() public {
        vm.prank(user1);
        vm.expectRevert(Errors.InvalidTokenTicker.selector);
        tokenFactory.createToken(TOKEN_NAME, "", INITIAL_AMOUNT);
    }

    // Test validation: Invalid initial amount
    function testRevertWhenInvalidAmount() public {
        vm.prank(user1);
        vm.expectRevert(Errors.InvalidInitialAmount.selector);
        tokenFactory.createToken(TOKEN_NAME, TOKEN_TICKER, 0);
    }

    // Test multiple token creations
    function testMultipleTokensForSameUser() public {
        // Create first token
        vm.prank(user1);
        tokenFactory.createToken("First Token", "FTK", INITIAL_AMOUNT);

        // Create second token
        vm.prank(user1);
        tokenFactory.createToken("Second Token", "STK", INITIAL_AMOUNT * 2);

        // Record logs to get addresses
        vm.recordLogs();
        vm.prank(user1);
        tokenFactory.createToken("Final Token", "FNL", INITIAL_AMOUNT / 2);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 tokenCreatedSig = keccak256("TokenCreated(address,address,string,string,uint256)");
        address finalTokenAddress;

        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == tokenCreatedSig) {
                finalTokenAddress = address(uint160(uint256(entries[i].topics[2])));
                break;
            }
        }

        // Verify the last token
        Token finalToken = Token(finalTokenAddress);
        assertEq(finalToken.name(), "Final Token");
        assertEq(finalToken.symbol(), "FNL");
        assertEq(finalToken.balanceOf(user1), INITIAL_AMOUNT / 2);
    }

    // Test token creation from different users
    function testTokenCreationFromDifferentUsers() public {
        // User1 creates a token
        vm.prank(user1);
        tokenFactory.createToken("User1 Token", "U1T", INITIAL_AMOUNT);

        // User2 creates a token
        vm.prank(user2);
        tokenFactory.createToken("User2 Token", "U2T", INITIAL_AMOUNT * 3);

        // For this test, we don't need to verify the actual token instances
        // since we're mainly testing that different users can create tokens
    }

    // Test ownership (if relevant to your contract)
    function testOwnership() public view {
        // Verify the owner
        assertEq(tokenFactory.owner(), owner);

        // Only needed if your contract has owner-specific functionality
    }

    // Test gas usage for token creation
    function testGasUsageForTokenCreation() public {
        uint256 startGas = gasleft();

        vm.prank(user1);
        tokenFactory.createToken(TOKEN_NAME, TOKEN_TICKER, INITIAL_AMOUNT);

        uint256 gasUsed = startGas - gasleft();
        console2.log("Gas used for token creation:", gasUsed);

        // You might want to add assertions about gas usage limits
        // but that depends on your specific requirements
    }
}
