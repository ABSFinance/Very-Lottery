// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title CircuitBreaker
 * @author Cryptolotto Team
 * @notice Circuit breaker pattern implementation for system protection
 * @dev Manages circuit states and failure tracking for system components
 */
contract CircuitBreaker is Initializable, OwnableUpgradeable {
    // Custom Errors
    error CircuitBreakerDisabled();
    error CircuitNotFound();
    error InvalidCircuitParams();
    error CircuitAlreadyExists();
    error InvalidAddress();
    error InvalidFunctionName();
    error CircuitNotOpen();
    error CircuitNotHalfOpen();

    // Circuit state enum
    enum CircuitState {
        CLOSED, // Normal operation
        OPEN, // Circuit is open (failing)
        HALF_OPEN // Testing if circuit can close
    }

    // Circuit information struct
    struct Circuit {
        CircuitState state;
        uint256 failureCount;
        uint256 lastFailureTime;
        uint256 threshold;
        uint256 timeout;
        bool isActive;
    }

    // State variables
    /**
     * @notice Mapping of circuit names to circuit information
     */
    mapping(string => Circuit) public circuits;
    /**
     * @notice Mapping of addresses to circuit information
     */
    mapping(address => Circuit) public addressCircuits;
    /**
     * @notice Mapping of function names to circuit information
     */
    mapping(string => Circuit) public functionCircuits;

    // Circuit breaker settings
    /**
     * @notice Whether circuit breaker is enabled
     */
    bool public circuitBreakerEnabled;
    /**
     * @notice Default failure threshold
     */
    uint256 public defaultThreshold;
    /**
     * @notice Default timeout period
     */
    uint256 public defaultTimeout;

    // Events
    /**
     * @notice Emitted when a circuit is created
     * @param circuitName Name of the circuit
     * @param threshold Failure threshold
     * @param timeout Timeout period
     * @param timestamp Creation timestamp
     */
    event CircuitCreated(
        string indexed circuitName,
        uint256 indexed threshold,
        uint256 indexed timeout,
        uint256 timestamp
    );
    /**
     * @notice Emitted when a circuit is opened
     * @param circuitName Name of the circuit
     * @param failureCount Number of failures
     * @param timestamp Opening timestamp
     */
    event CircuitOpened(
        string indexed circuitName,
        uint256 indexed failureCount,
        uint256 indexed timestamp
    );
    /**
     * @notice Emitted when a circuit is closed
     * @param circuitName Name of the circuit
     * @param timestamp Closing timestamp
     */
    event CircuitClosed(string indexed circuitName, uint256 indexed timestamp);
    /**
     * @notice Emitted when a circuit is half-opened
     * @param circuitName Name of the circuit
     * @param timestamp Half-opening timestamp
     */
    event CircuitHalfOpened(
        string indexed circuitName,
        uint256 indexed timestamp
    );
    /**
     * @notice Emitted when circuit breaker is toggled
     * @param enabled Whether circuit breaker is enabled
     * @param timestamp Toggle timestamp
     */
    event CircuitBreakerToggled(
        bool indexed enabled,
        uint256 indexed timestamp
    );

    /**
     * @notice Initialize the circuit breaker contract
     * @param owner Owner of the contract
     */
    function initialize(address owner) public initializer {
        __Ownable_init();
        circuitBreakerEnabled = true;
        defaultThreshold = 5;
        defaultTimeout = 300; // 5 minutes
    }

    /**
     * @notice Create a new circuit
     * @param circuitName Name of the circuit
     * @param threshold Failure threshold
     * @param timeout Timeout period
     */
    function createCircuit(
        string calldata circuitName,
        uint256 threshold,
        uint256 timeout
    ) external onlyOwner {
        _validateCircuitParams(threshold, timeout);
        if (circuits[circuitName].isActive) revert CircuitAlreadyExists();
        _createCircuit(circuitName, threshold, timeout);
    }

    /**
     * @notice Validate circuit parameters
     * @param threshold Failure threshold
     * @param timeout Timeout period
     */
    function _validateCircuitParams(
        uint256 threshold,
        uint256 timeout
    ) internal pure {
        if (threshold == 0) revert InvalidCircuitParams();
        if (timeout == 0) revert InvalidCircuitParams();
    }

    /**
     * @notice Create a circuit with given parameters
     * @param circuitName Name of the circuit
     * @param threshold Failure threshold
     * @param timeout Timeout period
     */
    function _createCircuit(
        string calldata circuitName,
        uint256 threshold,
        uint256 timeout
    ) internal {
        circuits[circuitName] = Circuit({
            state: CircuitState.CLOSED,
            failureCount: 0,
            lastFailureTime: 0,
            threshold: threshold,
            timeout: timeout,
            isActive: true
        });

        emit CircuitCreated(circuitName, threshold, timeout, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Create a circuit for a specific address
     * @param targetAddress Address to create circuit for
     * @param threshold Failure threshold
     * @param timeout Timeout period
     */
    function createAddressCircuit(
        address targetAddress,
        uint256 threshold,
        uint256 timeout
    ) external onlyOwner {
        if (targetAddress == address(0)) revert InvalidAddress();
        _validateCircuitParams(threshold, timeout);
        if (addressCircuits[targetAddress].isActive) {
            revert CircuitAlreadyExists();
        }
        _createAddressCircuit(targetAddress, threshold, timeout);
    }

    /**
     * @notice Create an address circuit with given parameters
     * @param targetAddress Address to create circuit for
     * @param threshold Failure threshold
     * @param timeout Timeout period
     */
    function _createAddressCircuit(
        address targetAddress,
        uint256 threshold,
        uint256 timeout
    ) internal {
        string memory circuitName = _addressToString(targetAddress);
        addressCircuits[targetAddress] = Circuit({
            state: CircuitState.CLOSED,
            failureCount: 0,
            lastFailureTime: 0,
            threshold: threshold,
            timeout: timeout,
            isActive: true
        });

        emit CircuitCreated(circuitName, threshold, timeout, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Convert address to string
     * @param addr Address to convert
     * @return String representation of address
     */
    function _addressToString(
        address addr
    ) internal pure returns (string memory) {
        return string(abi.encodePacked("ADDR_", toHexString(addr)));
    }

    /**
     * @notice Convert address to hex string
     * @param addr Address to convert
     * @return Hex string representation
     */
    function toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(40);
        for (uint256 i = 0; i < 20; ++i) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(addr)) / (2 ** (8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            buffer[2 * i] = char(hi);
            buffer[2 * i + 1] = char(lo);
        }
        return string(buffer);
    }

    /**
     * @notice Convert byte to character
     * @param b Byte to convert
     * @return Character representation
     */
    function char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @notice Create a circuit for a specific function
     * @param functionName Name of the function
     * @param threshold Failure threshold
     * @param timeout Timeout period
     */
    function createFunctionCircuit(
        string calldata functionName,
        uint256 threshold,
        uint256 timeout
    ) external onlyOwner {
        if (bytes(functionName).length == 0) revert InvalidFunctionName();
        _validateCircuitParams(threshold, timeout);
        if (functionCircuits[functionName].isActive) {
            revert CircuitAlreadyExists();
        }
        _createFunctionCircuit(functionName, threshold, timeout);
    }

    /**
     * @notice Create a function circuit with given parameters
     * @param functionName Name of the function
     * @param threshold Failure threshold
     * @param timeout Timeout period
     */
    function _createFunctionCircuit(
        string calldata functionName,
        uint256 threshold,
        uint256 timeout
    ) internal {
        functionCircuits[functionName] = Circuit({
            state: CircuitState.CLOSED,
            failureCount: 0,
            lastFailureTime: 0,
            threshold: threshold,
            timeout: timeout,
            isActive: true
        });

        emit CircuitCreated(functionName, threshold, timeout, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Check if a circuit is open
     * @param circuitName Name of the circuit
     * @return Whether circuit is open
     */
    function checkCircuit(
        string calldata circuitName
    ) external view returns (bool) {
        if (!circuitBreakerEnabled) return false;
        Circuit storage circuit = circuits[circuitName];
        if (!circuit.isActive) return false;
        return _checkCircuitState(circuit);
    }

    /**
     * @notice Check if an address circuit is open
     * @param targetAddress Address to check
     * @return Whether address circuit is open
     */
    function checkAddressCircuit(
        address targetAddress
    ) external view returns (bool) {
        if (!circuitBreakerEnabled) return false;
        Circuit storage circuit = addressCircuits[targetAddress];
        if (!circuit.isActive) return false;
        return _checkCircuitState(circuit);
    }

    /**
     * @notice Check if a function circuit is open
     * @param functionName Name of the function
     * @return Whether function circuit is open
     */
    function checkFunctionCircuit(
        string calldata functionName
    ) external view returns (bool) {
        if (!circuitBreakerEnabled) return false;
        Circuit storage circuit = functionCircuits[functionName];
        if (!circuit.isActive) return false;
        return _checkCircuitState(circuit);
    }

    /**
     * @notice Check circuit state
     * @param circuit Circuit to check
     * @return Whether circuit is open
     */
    function _checkCircuitState(
        Circuit storage circuit
    ) internal view returns (bool) {
        if (circuit.state == CircuitState.OPEN) {
            if (block.timestamp >= circuit.lastFailureTime + circuit.timeout) {
                // solhint-disable-line not-rely-on-time
                return false; // Allow one request to test
            }
            return true;
        }
        return false;
    }

    /**
     * @notice Record a failure for a circuit
     * @param circuitName Name of the circuit
     */
    function recordFailure(string calldata circuitName) external {
        if (!circuitBreakerEnabled) revert CircuitBreakerDisabled();
        Circuit storage circuit = circuits[circuitName];
        if (!circuit.isActive) revert CircuitNotFound();

        ++circuit.failureCount; // solhint-disable-line gas-increment-by-one
        circuit.lastFailureTime = block.timestamp; // solhint-disable-line not-rely-on-time

        if (circuit.failureCount >= circuit.threshold) {
            circuit.state = CircuitState.OPEN;
            emit CircuitOpened(
                circuitName,
                circuit.failureCount,
                block.timestamp
            ); // solhint-disable-line not-rely-on-time
        }
    }

    /**
     * @notice Record a failure for an address circuit
     * @param targetAddress Address to record failure for
     */
    function recordAddressFailure(address targetAddress) external {
        if (!circuitBreakerEnabled) revert CircuitBreakerDisabled();
        Circuit storage circuit = addressCircuits[targetAddress];
        if (!circuit.isActive) revert CircuitNotFound();

        ++circuit.failureCount; // solhint-disable-line gas-increment-by-one
        circuit.lastFailureTime = block.timestamp; // solhint-disable-line not-rely-on-time

        if (circuit.failureCount >= circuit.threshold) {
            circuit.state = CircuitState.OPEN;
            string memory circuitName = _addressToString(targetAddress);
            emit CircuitOpened(
                circuitName,
                circuit.failureCount,
                block.timestamp
            ); // solhint-disable-line not-rely-on-time
        }
    }

    /**
     * @notice Record a failure for a function circuit
     * @param functionName Name of the function
     */
    function recordFunctionFailure(string calldata functionName) external {
        if (!circuitBreakerEnabled) revert CircuitBreakerDisabled();
        Circuit storage circuit = functionCircuits[functionName];
        if (!circuit.isActive) revert CircuitNotFound();

        ++circuit.failureCount; // solhint-disable-line gas-increment-by-one
        circuit.lastFailureTime = block.timestamp; // solhint-disable-line not-rely-on-time

        if (circuit.failureCount >= circuit.threshold) {
            circuit.state = CircuitState.OPEN;
            emit CircuitOpened(
                functionName,
                circuit.failureCount,
                block.timestamp
            ); // solhint-disable-line not-rely-on-time
        }
    }

    /**
     * @notice Record a success for a circuit
     * @param circuitName Name of the circuit
     */
    function recordSuccess(string calldata circuitName) external {
        if (!circuitBreakerEnabled) revert CircuitBreakerDisabled();
        Circuit storage circuit = circuits[circuitName];
        if (!circuit.isActive) revert CircuitNotFound();

        if (circuit.state == CircuitState.HALF_OPEN) {
            circuit.state = CircuitState.CLOSED;
            circuit.failureCount = 0;
            emit CircuitClosed(circuitName, block.timestamp); // solhint-disable-line not-rely-on-time
        }
    }

    /**
     * @notice Record a success for an address circuit
     * @param targetAddress Address to record success for
     */
    function recordAddressSuccess(address targetAddress) external {
        if (!circuitBreakerEnabled) revert CircuitBreakerDisabled();
        Circuit storage circuit = addressCircuits[targetAddress];
        if (!circuit.isActive) revert CircuitNotFound();

        if (circuit.state == CircuitState.HALF_OPEN) {
            circuit.state = CircuitState.CLOSED;
            circuit.failureCount = 0;
            string memory circuitName = _addressToString(targetAddress);
            emit CircuitClosed(circuitName, block.timestamp); // solhint-disable-line not-rely-on-time
        }
    }

    /**
     * @notice Record a success for a function circuit
     * @param functionName Name of the function
     */
    function recordFunctionSuccess(string calldata functionName) external {
        if (!circuitBreakerEnabled) revert CircuitBreakerDisabled();
        Circuit storage circuit = functionCircuits[functionName];
        if (!circuit.isActive) revert CircuitNotFound();

        if (circuit.state == CircuitState.HALF_OPEN) {
            circuit.state = CircuitState.CLOSED;
            circuit.failureCount = 0;
            emit CircuitClosed(functionName, block.timestamp); // solhint-disable-line not-rely-on-time
        }
    }

    /**
     * @notice Toggle circuit breaker functionality
     */
    function toggleCircuitBreaker() external onlyOwner {
        circuitBreakerEnabled = !circuitBreakerEnabled;
        emit CircuitBreakerToggled(circuitBreakerEnabled, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Get circuit information
     * @param circuitName Name of the circuit
     * @return state Circuit state
     * @return failureCount Number of failures
     * @return lastFailureTime Last failure timestamp
     * @return threshold Failure threshold
     * @return timeout Timeout period
     * @return isActive Whether circuit is active
     */
    function getCircuitInfo(
        string calldata circuitName
    )
        external
        view
        returns (
            CircuitState state,
            uint256 failureCount,
            uint256 lastFailureTime,
            uint256 threshold,
            uint256 timeout,
            bool isActive
        )
    {
        Circuit storage circuit = circuits[circuitName];
        return (
            circuit.state,
            circuit.failureCount,
            circuit.lastFailureTime,
            circuit.threshold,
            circuit.timeout,
            circuit.isActive
        );
    }
}
