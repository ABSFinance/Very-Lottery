// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract DisableAllCircuitBreakers is Script {
    function run() public {
        // Get private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("=== DISABLING CIRCUIT BREAKERS FOR ALL CONTRACTS ===");
        console.log("Deployer:", deployer);

        // New contract addresses from successful deployment
        address cryptolotto1Day = 0x26D97e6580A423b2cf006500285455b85DCcCC4c;
        address cryptolotto7Days = 0x315Dbcc9E66a79C2E3f50B26AEE3Ca1b2e513f65;
        address cryptolottoAd = 0xF30AA92045FF4B077F2dfE61c7DE979a7dEDfF91;

        // Disable circuit breaker for Cryptolotto1Day
        console.log("Disabling circuit breaker for Cryptolotto1Day...");
        (bool success1, ) = cryptolotto1Day.call(
            abi.encodeWithSignature("toggleCircuitBreaker()")
        );
        if (success1) {
            console.log("SUCCESS: Cryptolotto1Day circuit breaker disabled");
        } else {
            console.log("FAILED: Cryptolotto1Day circuit breaker");
        }

        // Disable circuit breaker for Cryptolotto7Days
        console.log("Disabling circuit breaker for Cryptolotto7Days...");
        (bool success2, ) = cryptolotto7Days.call(
            abi.encodeWithSignature("toggleCircuitBreaker()")
        );
        if (success2) {
            console.log("SUCCESS: Cryptolotto7Days circuit breaker disabled");
        } else {
            console.log("FAILED: Cryptolotto7Days circuit breaker");
        }

        // Disable circuit breaker for CryptolottoAd
        console.log("Disabling circuit breaker for CryptolottoAd...");
        (bool success3, ) = cryptolottoAd.call(
            abi.encodeWithSignature("toggleCircuitBreaker()")
        );
        if (success3) {
            console.log("SUCCESS: CryptolottoAd circuit breaker disabled");
        } else {
            console.log("FAILED: CryptolottoAd circuit breaker");
        }

        vm.stopBroadcast();

        console.log("=== CIRCUIT BREAKER DISABLE COMPLETE ===");
    }
}
