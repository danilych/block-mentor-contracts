// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Script, console } from "forge-std/Script.sol";
import { OmnichainToken } from "src/tokens/OmnichainToken.sol";

contract DeployOmnichainToken is Script {
    OmnichainToken internal token;

    function run() external {
        vm.startBroadcast();

        token = new OmnichainToken("OmnichainToken", "OMNI", msg.sender, 1000000 ether);

        console.log("OmnichainToken deployed to:", address(token));

        vm.stopBroadcast();
    }
}
