// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title CircuitBreaker
 * @dev 서킷 브레이커 패턴 구현
 */
contract CircuitBreaker is Initializable, OwnableUpgradeable {
    // Circuit breaker states
    enum CircuitState {
        CLOSED, // Normal operation
        OPEN, // Circuit is open, operations are blocked
        HALF_OPEN // Testing if system is ready to close
    }

    // Circuit breaker struct
    struct Circuit {
        CircuitState state;
        uint256 failureCount;
        uint256 lastFailureTime;
        uint256 threshold;
        uint256 timeout;
        bool isActive;
    }

    // Circuit mappings
    mapping(string => Circuit) public circuits;
    mapping(address => Circuit) public addressCircuits;
    mapping(string => Circuit) public functionCircuits;

    // Global settings
    bool public circuitBreakerEnabled;
    uint256 public defaultThreshold = 5;
    uint256 public defaultTimeout = 300; // 5 minutes

    // Events
    event CircuitCreated(
        string indexed circuitName,
        uint256 threshold,
        uint256 timeout,
        uint256 timestamp
    );
    event CircuitOpened(
        string indexed circuitName,
        uint256 failureCount,
        uint256 timestamp
    );
    event CircuitClosed(string indexed circuitName, uint256 timestamp);
    event CircuitHalfOpened(string indexed circuitName, uint256 timestamp);
    event CircuitBreakerToggled(bool enabled, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        circuitBreakerEnabled = true;
    }

    /**
     * @dev 서킷 생성
     */
    function createCircuit(
        string memory circuitName,
        uint256 threshold,
        uint256 timeout
    ) external onlyOwner {
        _validateCircuitParams(threshold, timeout);
        _createCircuit(circuitName, threshold, timeout);
        emit CircuitCreated(circuitName, threshold, timeout, block.timestamp);
    }

    /**
     * @dev 서킷 매개변수 검증
     */
    function _validateCircuitParams(
        uint256 threshold,
        uint256 timeout
    ) internal pure {
        require(threshold > 0, "Threshold must be greater than 0");
        require(timeout > 0, "Timeout must be greater than 0");
    }

    /**
     * @dev 서킷 생성
     */
    function _createCircuit(
        string memory circuitName,
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
    }

    /**
     * @dev 주소별 서킷 생성
     */
    function createAddressCircuit(
        address targetAddress,
        uint256 threshold,
        uint256 timeout
    ) external onlyOwner {
        _validateCircuitParams(threshold, timeout);
        _createAddressCircuit(targetAddress, threshold, timeout);
        emit CircuitCreated(
            _addressToString(targetAddress),
            threshold,
            timeout,
            block.timestamp
        );
    }

    /**
     * @dev 주소별 서킷 생성
     */
    function _createAddressCircuit(
        address targetAddress,
        uint256 threshold,
        uint256 timeout
    ) internal {
        addressCircuits[targetAddress] = Circuit({
            state: CircuitState.CLOSED,
            failureCount: 0,
            lastFailureTime: 0,
            threshold: threshold,
            timeout: timeout,
            isActive: true
        });
    }

    /**
     * @dev 주소를 문자열로 변환
     */
    function _addressToString(
        address addr
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(addr));
    }

    /**
     * @dev 함수별 서킷 생성
     */
    function createFunctionCircuit(
        string memory functionName,
        uint256 threshold,
        uint256 timeout
    ) external onlyOwner {
        require(threshold > 0, "Threshold must be greater than 0");
        require(timeout > 0, "Timeout must be greater than 0");

        functionCircuits[functionName] = Circuit({
            state: CircuitState.CLOSED,
            failureCount: 0,
            lastFailureTime: 0,
            threshold: threshold,
            timeout: timeout,
            isActive: true
        });
    }

    /**
     * @dev 서킷 상태 확인
     */
    function checkCircuit(
        string memory circuitName
    ) external view returns (bool) {
        if (!circuitBreakerEnabled) return true;

        Circuit storage circuit = circuits[circuitName];
        if (!circuit.isActive) return true;

        return _checkCircuitState(circuit);
    }

    /**
     * @dev 주소 서킷 상태 확인
     */
    function checkAddressCircuit(
        address targetAddress
    ) external view returns (bool) {
        if (!circuitBreakerEnabled) return true;

        Circuit storage circuit = addressCircuits[targetAddress];
        if (!circuit.isActive) return true;

        return _checkCircuitState(circuit);
    }

    /**
     * @dev 함수 서킷 상태 확인
     */
    function checkFunctionCircuit(
        string memory functionName
    ) external view returns (bool) {
        if (!circuitBreakerEnabled) return true;

        Circuit storage circuit = functionCircuits[functionName];
        if (!circuit.isActive) return true;

        return _checkCircuitState(circuit);
    }

    /**
     * @dev 내부 서킷 상태 확인
     */
    function _checkCircuitState(
        Circuit storage circuit
    ) internal view returns (bool) {
        if (circuit.state == CircuitState.OPEN) {
            // Check if timeout has passed for half-open
            if (block.timestamp >= circuit.lastFailureTime + circuit.timeout) {
                return true; // Allow one request to test
            }
            return false;
        }
        return true;
    }

    /**
     * @dev 실패 기록
     */
    function recordFailure(string memory circuitName) external onlyOwner {
        Circuit storage circuit = circuits[circuitName];
        if (!circuit.isActive) return;

        circuit.failureCount++;
        circuit.lastFailureTime = block.timestamp;

        if (circuit.failureCount >= circuit.threshold) {
            circuit.state = CircuitState.OPEN;
            emit CircuitOpened(
                circuitName,
                circuit.failureCount,
                block.timestamp
            );
        }
    }

    /**
     * @dev 주소 실패 기록
     */
    function recordAddressFailure(address targetAddress) external onlyOwner {
        Circuit storage circuit = addressCircuits[targetAddress];
        if (!circuit.isActive) return;

        circuit.failureCount++;
        circuit.lastFailureTime = block.timestamp;

        if (circuit.failureCount >= circuit.threshold) {
            circuit.state = CircuitState.OPEN;
            emit CircuitOpened(
                string(abi.encodePacked(targetAddress)),
                circuit.failureCount,
                block.timestamp
            );
        }
    }

    /**
     * @dev 함수 실패 기록
     */
    function recordFunctionFailure(
        string memory functionName
    ) external onlyOwner {
        Circuit storage circuit = functionCircuits[functionName];
        if (!circuit.isActive) return;

        circuit.failureCount++;
        circuit.lastFailureTime = block.timestamp;

        if (circuit.failureCount >= circuit.threshold) {
            circuit.state = CircuitState.OPEN;
            emit CircuitOpened(
                functionName,
                circuit.failureCount,
                block.timestamp
            );
        }
    }

    /**
     * @dev 성공 기록 (서킷 닫기)
     */
    function recordSuccess(string memory circuitName) external onlyOwner {
        Circuit storage circuit = circuits[circuitName];
        if (!circuit.isActive) return;

        if (circuit.state == CircuitState.OPEN) {
            circuit.state = CircuitState.HALF_OPEN;
            emit CircuitHalfOpened(circuitName, block.timestamp);
        } else if (circuit.state == CircuitState.HALF_OPEN) {
            circuit.state = CircuitState.CLOSED;
            circuit.failureCount = 0;
            emit CircuitClosed(circuitName, block.timestamp);
        }
    }

    /**
     * @dev 주소 성공 기록
     */
    function recordAddressSuccess(address targetAddress) external onlyOwner {
        Circuit storage circuit = addressCircuits[targetAddress];
        if (!circuit.isActive) return;

        if (circuit.state == CircuitState.OPEN) {
            circuit.state = CircuitState.HALF_OPEN;
            emit CircuitHalfOpened(
                string(abi.encodePacked(targetAddress)),
                block.timestamp
            );
        } else if (circuit.state == CircuitState.HALF_OPEN) {
            circuit.state = CircuitState.CLOSED;
            circuit.failureCount = 0;
            emit CircuitClosed(
                string(abi.encodePacked(targetAddress)),
                block.timestamp
            );
        }
    }

    /**
     * @dev 함수 성공 기록
     */
    function recordFunctionSuccess(
        string memory functionName
    ) external onlyOwner {
        Circuit storage circuit = functionCircuits[functionName];
        if (!circuit.isActive) return;

        if (circuit.state == CircuitState.OPEN) {
            circuit.state = CircuitState.HALF_OPEN;
            emit CircuitHalfOpened(functionName, block.timestamp);
        } else if (circuit.state == CircuitState.HALF_OPEN) {
            circuit.state = CircuitState.CLOSED;
            circuit.failureCount = 0;
            emit CircuitClosed(functionName, block.timestamp);
        }
    }

    /**
     * @dev 서킷 브레이커 활성화/비활성화
     */
    function toggleCircuitBreaker() external onlyOwner {
        circuitBreakerEnabled = !circuitBreakerEnabled;
        emit CircuitBreakerToggled(circuitBreakerEnabled, block.timestamp);
    }

    /**
     * @dev 서킷 정보 조회
     */
    function getCircuitInfo(
        string memory circuitName
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
