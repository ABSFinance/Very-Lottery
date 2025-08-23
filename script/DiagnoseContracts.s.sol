// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract DiagnoseContracts is Script {
    function run() public {
        console.log("=== CONTRACT DIAGNOSIS ===");

        // Contract addresses from your deployment
        address cryptolotto1Day = 0x26D97e6580A423b2cf006500285455b85DCcCC4c;
        address cryptolotto7Days = 0x315Dbcc9E66a79C2E3f50B26AEE3Ca1b2e513f65;
        address cryptolottoAd = 0xF30AA92045FF4B077F2dfE61c7DE979a7dEDfF91;

        // Check each contract
        console.log("\n=== Cryptolotto1Day ===");
        _diagnoseContract(cryptolotto1Day, "Cryptolotto1Day");

        console.log("\n=== Cryptolotto7Days ===");
        _diagnoseContract(cryptolotto7Days, "Cryptolotto7Days");

        console.log("\n=== CryptolottoAd ===");
        _diagnoseContract(cryptolottoAd, "CryptolottoAd");

        console.log("\n=== DIAGNOSIS COMPLETE ===");
    }

    function _diagnoseContract(address contractAddr, string memory contractName) internal {
        console.log("Contract:", contractName);
        console.log("Address:", contractAddr);

        // Check if it's a proxy by calling implementation()
        try this.checkProxyStatus(contractAddr) {
            console.log("Proxy functions working");
        } catch {
            console.log("Proxy functions failed");
        }

        // Check circuit breaker
        try this.checkCircuitBreaker(contractAddr) {
            console.log("Circuit breaker check working");
        } catch {
            console.log("Circuit breaker check failed");
        }
    }

    function checkProxyStatus(address contractAddr) external view {
        // Check if it has proxy-related functions
        (bool success, bytes memory data) = contractAddr.staticcall(abi.encodeWithSignature("implementation()"));
        require(success, "implementation() failed");

        address impl = abi.decode(data, (address));
        console.log("Implementation address:", impl);
    }

    function checkCircuitBreaker(address contractAddr) external view {
        // Check circuit breaker status
        (bool success, bytes memory data) = contractAddr.staticcall(abi.encodeWithSignature("circuitBreakerEnabled()"));
        if (success) {
            bool enabled = abi.decode(data, (bool));
            console.log("Circuit breaker enabled:", enabled);
        } else {
            console.log("Circuit breaker function not found");
        }
    }
}
