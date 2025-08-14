// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract SimpleDeploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployer);

        // Simple test deployment
        console.log("Deploying simple test contract...");
        console.log("Deployer:", deployer);

        vm.stopBroadcast();
    }
}
