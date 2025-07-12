// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";
import { Presale } from "../src/Presale.sol";
import { PresaleFactory } from "../src/PresaleFactory.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract PresaleFactoryTest is Test {
    PresaleFactory public factory;
    MockERC20 public token;
    
    address public owner = address(0x1);
    address public user = address(0x2);
    
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
        
        // Deploy the factory
        factory = new PresaleFactory(owner);
        
        vm.stopPrank();
    }
    
    function test_CreatePresale() public {
        // Calculate timestamps
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + PRESALE_DURATION;
        
        // Create a new presale
        vm.prank(owner);
        address presaleAddress = factory.createPresale(
            address(token),
            TOKEN_PRICE,
            TOKEN_LIMIT,
            startTime,
            endTime
        );
        
        // Verify the presale was created
        assertTrue(factory.isPresale(presaleAddress));
        assertEq(factory.presaleCount(), 1);
        
        // Verify the presale parameters
        Presale presale = Presale(presaleAddress);
        assertEq(presale.token(), address(token));
        assertEq(presale.price(), TOKEN_PRICE);
        assertEq(presale.limit(), TOKEN_LIMIT);
        assertEq(presale.start(), startTime);
        assertEq(presale.end(), endTime);
    }
    
    function test_OnlyOwnerCanCreatePresale() public {
        // Calculate timestamps
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + PRESALE_DURATION;
        
        // Try to create a presale from a non-owner address
        vm.prank(user);
        vm.expectRevert();
        factory.createPresale(
            address(token),
            TOKEN_PRICE,
            TOKEN_LIMIT,
            startTime,
            endTime
        );
    }
    
    function test_GetAllPresales() public {
        // Create multiple presales
        uint256 count = 3;
        
        for (uint256 i = 0; i < count; i++) {
            uint256 startTime = block.timestamp + (i + 1) * 1 days;
            uint256 endTime = startTime + PRESALE_DURATION;
            
            vm.prank(owner);
            factory.createPresale(
                address(token),
                TOKEN_PRICE,
                TOKEN_LIMIT,
                startTime,
                endTime
            );
        }
        
        // Get all presales
        address[] memory presales = factory.getAllPresales();
        assertEq(presales.length, count);
        
        // Verify each presale
        for (uint256 i = 0; i < count; i++) {
            assertTrue(factory.isPresale(presales[i]));
        }
    }
    
    function test_GetPresalesPaginated() public {
        // Create 5 presales
        uint256 totalPresales = 5;
        uint256 pageSize = 2;
        
        for (uint256 i = 0; i < totalPresales; i++) {
            uint256 startTime = block.timestamp + (i + 1) * 1 days;
            uint256 endTime = startTime + PRESALE_DURATION;
            
            vm.prank(owner);
            factory.createPresale(
                address(token),
                TOKEN_PRICE,
                TOKEN_LIMIT,
                startTime,
                endTime
            );
        }
        
        // Test pagination
        address[] memory page1 = factory.getPresalesPaginated(1, pageSize);
        address[] memory page2 = factory.getPresalesPaginated(2, pageSize);
        address[] memory page3 = factory.getPresalesPaginated(3, pageSize);
        
        assertEq(page1.length, pageSize);
        assertEq(page2.length, pageSize);
        assertEq(page3.length, totalPresales - 2 * pageSize); // Should be 1 item on the last page
    }
}
