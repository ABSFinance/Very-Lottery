// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../contracts/shared/utils/CircuitBreaker.sol";

contract DeployCircuitBreaker is Script {
    function run() public {
        // 환경변수에서 private key 가져오기
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy CircuitBreaker
        CircuitBreaker circuitBreaker = new CircuitBreaker();

        // Initialize CircuitBreaker
        circuitBreaker.initialize(deployer);

        vm.stopBroadcast();

        console.log("CircuitBreaker deployed successfully!");
        console.log("CircuitBreaker address:", address(circuitBreaker));
        console.log("Owner:", deployer);

        // Check initial state
        bool isEnabled = circuitBreaker.circuitBreakerEnabled();
        console.log("Circuit Breaker enabled:", isEnabled);

        if (isEnabled) {
            console.log("WARNING: Circuit Breaker is ENABLED by default");
            console.log(
                "You can now disable it using the DisableCircuitBreaker script"
            );
        }

        console.log("=== DEPLOYMENT COMPLETE ===");
        console.log("CIRCUIT_BREAKER_ADDRESS=", address(circuitBreaker));
    }
}
