// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Script, console } from "forge-std/Script.sol";
import { OmnichainToken } from "src/tokens/OmnichainToken.sol";

contract BridgeTokens is Script {
    OmnichainToken internal token;

    address tokenDeployment = 0x24260d046005f74aCa953e3aA00028DEFadABdC7;

    function run() external {
        vm.startBroadcast();

        token = OmnichainToken(payable(tokenDeployment));

        token.bridge(84532, msg.sender, 10000 ether);

        console.log("Tokens bridged to: ", msg.sender);

        vm.stopBroadcast();
    }
}
