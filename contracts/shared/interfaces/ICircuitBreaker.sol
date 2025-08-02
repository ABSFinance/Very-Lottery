// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICircuitBreaker {
    enum CircuitState {
        CLOSED, // Normal operation
        OPEN, // Circuit is open, operations are blocked
        HALF_OPEN // Testing if system is ready to close

    }

    struct Circuit {
        CircuitState state;
        uint256 failureCount;
        uint256 lastFailureTime;
        uint256 threshold;
        uint256 timeout;
        bool isActive;
    }

    function createCircuit(string memory circuitName, uint256 threshold, uint256 timeout) external;

    function createAddressCircuit(address targetAddress, uint256 threshold, uint256 timeout) external;

    function createFunctionCircuit(string memory functionName, uint256 threshold, uint256 timeout) external;

    function checkCircuit(string memory circuitName) external view returns (bool);

    function checkAddressCircuit(address targetAddress) external view returns (bool);

    function checkFunctionCircuit(string memory functionName) external view returns (bool);

    function recordFailure(string memory circuitName) external;

    function recordAddressFailure(address targetAddress) external;

    function recordFunctionFailure(string memory functionName) external;

    function recordSuccess(string memory circuitName) external;

    function recordAddressSuccess(address targetAddress) external;

    function recordFunctionSuccess(string memory functionName) external;

    function toggleCircuitBreaker() external;

    function getCircuitInfo(string memory circuitName)
        external
        view
        returns (
            CircuitState state,
            uint256 failureCount,
            uint256 lastFailureTime,
            uint256 threshold,
            uint256 timeout,
            bool isActive
        );
}
