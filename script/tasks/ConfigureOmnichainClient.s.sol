// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Script, console } from "forge-std/Script.sol";
import { OmnichainToken } from "src/tokens/OmnichainToken.sol";

contract ConfigureOmnichainClient is Script {
    OmnichainToken internal token;

    uint256[] internal chains;
    address[] internal deployments;
    uint16[] internal confirmations;

    address tokenDeployment = 0xbd39A7fAbBc9D92df06d93B226C62EA820CCf325;

    function run() external {
        vm.startBroadcast();

        chains.push(84532);
        chains.push(421614);

        deployments.push(tokenDeployment);
        deployments.push(0x24260d046005f74aCa953e3aA00028DEFadABdC7);

        confirmations.push(1);
        confirmations.push(1);

        token = OmnichainToken(payable(tokenDeployment));

        token.configureClient(0xE700Ee5d8B7dEc62987849356821731591c048cF, chains, deployments, confirmations);

        console.log("OmnichainToken deployed to:", address(token));

        vm.stopBroadcast();
    }
}
