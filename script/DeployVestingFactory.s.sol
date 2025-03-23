// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Script, console } from "forge-std/Script.sol";
import { VestingFactory } from "src/VestingFactory.sol";

contract DeployVestingFactory is Script {
    VestingFactory internal factory;

    function run() external {
        vm.startBroadcast();

        factory = new VestingFactory();

        console.log("VestingFactory deployed to:", address(factory));

        vm.stopBroadcast();
    }
}
