// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../contracts/test/VerychainExample.sol";

contract SingleDeployScript is Script {
    function run() public {
        // Verychain 네트워크용 private key 사용
        uint256 deployerPrivateKey = 0x95257b51ddef4936f399ad55ef0f0aa234bea0a4265f5b4edef6e6fb5e8318af;
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("=== VERYCHAIN CONTRACT DEPLOYMENT ===");
        console.log("Deployer:", deployer);
        console.log("Network: Verychain");
        console.log("Chain ID: 4613");

        // Verychain 문서 예제 컨트랙트 배포
        ExampleContract exampleContract = new ExampleContract();
        console.log("ExampleContract deployed at:", address(exampleContract));

        vm.stopBroadcast();

        console.log("=== DEPLOYMENT COMPLETE ===");
        console.log("Contract address:", address(exampleContract));
        console.log("Please verify on Verychain explorer");
    }
}
