// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../contracts/shared/utils/CircuitBreaker.sol";

contract DisableCircuitBreaker is Script {
    function run() public {
        // 환경변수에서 private key 가져오기
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);

        // Circuit Breaker 계약 주소 (배포 후 수동으로 설정 필요)
        address circuitBreakerAddress = vm.envAddress("CIRCUIT_BREAKER_ADDRESS");

        if (circuitBreakerAddress == address(0)) {
            console.log("ERROR: CIRCUIT_BREAKER_ADDRESS not set in environment");
            console.log("Please set the deployed CircuitBreaker contract address");
            return;
        }

        console.log("Circuit Breaker address:", circuitBreakerAddress);

        // Circuit Breaker 계약 인스턴스 생성
        CircuitBreaker circuitBreaker = CircuitBreaker(circuitBreakerAddress);

        vm.startBroadcast(deployerPrivateKey);

        try circuitBreaker.toggleCircuitBreaker() {
            console.log("Circuit Breaker toggled successfully");

            // 상태 확인
            bool isEnabled = circuitBreaker.circuitBreakerEnabled();
            console.log("Circuit Breaker enabled:", isEnabled);

            if (!isEnabled) {
                console.log("SUCCESS: Circuit Breaker has been DISABLED");
                console.log("Transactions should now work normally");
            } else {
                console.log("WARNING: Circuit Breaker is still ENABLED");
                console.log("You may need to call toggleCircuitBreaker() again");
            }
        } catch Error(string memory reason) {
            console.log("Failed to toggle Circuit Breaker:");
            console.log("Reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Failed to toggle Circuit Breaker (low level error)");
            console.logBytes(lowLevelData);
        }

        vm.stopBroadcast();
    }
}
