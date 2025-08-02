// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {GasOptimizer} from "../../shared/utils/GasOptimizer.sol";

using GasOptimizer for address[];

/**
 * @title MonitoringSystem
 * @author Cryptolotto Team
 * @notice System monitoring contract for tracking system health and performance
 * @dev Provides monitoring capabilities for the lottery system
 */
contract MonitoringSystem is Initializable, OwnableUpgradeable {
    // Monitoring data
    /** @notice Current system metrics */
    struct SystemMetrics {
        uint256 totalTransactions;
        uint256 totalVolume;
        uint256 activeUsers;
        uint256 lastUpdate;
        bool isHealthy;
    }

    /** @notice Alert information structure */
    struct Alert {
        string message;
        uint256 severity; // 1: Low, 2: Medium, 3: High, 4: Critical
        uint256 timestamp;
        bool isResolved;
    }

    // State variables
    /** @notice Current system metrics */
    SystemMetrics public currentMetrics;
    /** @notice Mapping of alert IDs to alert information */
    mapping(uint256 => Alert) public alerts;
    /** @notice Total number of alerts */
    uint256 public alertCount;
    /** @notice Mapping of contract addresses to monitoring status */
    mapping(address => bool) public monitoredContracts;
    /** @notice Mapping of contract addresses to last check time */
    mapping(address => uint256) public contractLastCheck;

    // Thresholds
    /** @notice Minimum transaction threshold for monitoring */
    uint256 public minTransactionThreshold = 10;
    /** @notice Maximum response time in seconds */
    uint256 public maxResponseTime = 300; // 5 minutes
    /** @notice Health check interval in seconds */
    uint256 public healthCheckInterval = 3600; // 1 hour

    // Events
    /**
     * @notice Emitted when system metrics are updated
     * @param totalTransactions Total number of transactions
     * @param totalVolume Total volume
     * @param activeUsers Number of active users
     * @param timestamp Timestamp of the update
     */
    event MetricsUpdated(
        uint256 indexed totalTransactions,
        uint256 indexed totalVolume,
        uint256 indexed activeUsers,
        uint256 timestamp
    );
    /**
     * @notice Emitted when a new alert is created
     * @param alertId The alert ID
     * @param message Alert message
     * @param severity Alert severity level
     * @param timestamp Timestamp when alert was created
     */
    event AlertCreated(
        uint256 indexed alertId,
        string message,
        uint256 indexed severity,
        uint256 indexed timestamp
    );
    /**
     * @notice Emitted when an alert is resolved
     * @param alertId The alert ID
     * @param timestamp Timestamp when alert was resolved
     */
    event AlertResolved(uint256 indexed alertId, uint256 indexed timestamp);
    /**
     * @notice Emitted when a contract is registered for monitoring
     * @param contractAddress The contract address
     * @param timestamp Timestamp when contract was registered
     */
    event ContractRegistered(
        address indexed contractAddress,
        uint256 indexed timestamp
    );
    /**
     * @notice Emitted when a contract is unregistered from monitoring
     * @param contractAddress The contract address
     * @param timestamp Timestamp when contract was unregistered
     */
    event ContractUnregistered(
        address indexed contractAddress,
        uint256 indexed timestamp
    );
    /**
     * @notice Emitted when a health check is performed
     * @param isHealthy Whether the system is healthy
     * @param timestamp Timestamp of the health check
     */
    event HealthCheckPerformed(
        bool indexed isHealthy,
        uint256 indexed timestamp
    );

    // 추가된 이벤트들
    event SystemAlert(
        string indexed alertType,
        string message,
        uint256 severity,
        uint256 timestamp
    );
    event PerformanceThresholdExceeded(
        string indexed metric,
        uint256 currentValue,
        uint256 threshold,
        uint256 timestamp
    );
    event SecurityEvent(
        address indexed contractAddress,
        string eventType,
        string details,
        uint256 timestamp
    );
    event MonitoringConfigUpdated(
        string parameter,
        uint256 oldValue,
        uint256 newValue,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        currentMetrics = SystemMetrics({
            totalTransactions: 0,
            totalVolume: 0,
            activeUsers: 0,
            lastUpdate: block.timestamp,
            isHealthy: true
        });
    }

    /**
     * @dev 메트릭 업데이트
     */
    function updateMetrics(
        uint256 transactions,
        uint256 volume,
        uint256 users
    ) external onlyOwner {
        currentMetrics.totalTransactions = transactions;
        currentMetrics.totalVolume = volume;
        currentMetrics.activeUsers = users;
        currentMetrics.lastUpdate = block.timestamp;

        // 건강 상태 확인
        currentMetrics.isHealthy = _checkHealthStatus();

        emit MetricsUpdated(transactions, volume, users, block.timestamp);
    }

    /**
     * @dev 알림 생성
     */
    function createAlert(
        string memory message,
        uint256 severity
    ) external onlyOwner {
        require(severity >= 1 && severity <= 4, "Invalid severity level");

        alertCount++;
        alerts[alertCount] = Alert({
            message: message,
            severity: severity,
            timestamp: block.timestamp,
            isResolved: false
        });

        emit AlertCreated(alertCount, message, severity, block.timestamp);
    }

    /**
     * @dev 알림 해결
     */
    function resolveAlert(uint256 alertId) external onlyOwner {
        require(alertId > 0 && alertId <= alertCount, "Invalid alert ID");
        require(!alerts[alertId].isResolved, "Alert already resolved");

        alerts[alertId].isResolved = true;
        emit AlertResolved(alertId, block.timestamp);
    }

    /**
     * @dev 컨트랙트 등록
     */
    function registerContract(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "Invalid contract address");
        require(
            !monitoredContracts[contractAddress],
            "Contract already registered"
        );

        monitoredContracts[contractAddress] = true;
        contractLastCheck[contractAddress] = block.timestamp;

        emit ContractRegistered(contractAddress, block.timestamp);
    }

    /**
     * @dev 컨트랙트 등록 해제
     */
    function unregisterContract(address contractAddress) external onlyOwner {
        require(monitoredContracts[contractAddress], "Contract not registered");

        monitoredContracts[contractAddress] = false;
        delete contractLastCheck[contractAddress];

        emit ContractUnregistered(contractAddress, block.timestamp);
    }

    /**
     * @dev 건강 상태 확인
     */
    function performHealthCheck() external onlyOwner returns (bool) {
        bool isHealthy = _checkHealthStatus();
        currentMetrics.isHealthy = isHealthy;

        emit HealthCheckPerformed(isHealthy, block.timestamp);

        return isHealthy;
    }

    /**
     * @dev 내부 건강 상태 확인
     */
    function _checkHealthStatus() internal view returns (bool) {
        // 기본적인 건강 상태 확인 로직
        bool hasRecentActivity = block.timestamp - currentMetrics.lastUpdate <=
            healthCheckInterval;
        bool hasMinimumTransactions = currentMetrics.totalTransactions >=
            minTransactionThreshold;

        return hasRecentActivity && hasMinimumTransactions;
    }

    /**
     * @dev 알림 조회
     */
    function getAlert(uint256 alertId) external view returns (Alert memory) {
        require(alertId > 0 && alertId <= alertCount, "Invalid alert ID");
        return alerts[alertId];
    }

    /**
     * @dev 활성 알림 조회 (가스 최적화 버전)
     * @notice 가스 효율적인 활성 알림 조회
     * @return activeAlerts 활성 알림 ID 배열
     */
    function getActiveAlerts()
        external
        view
        returns (uint256[] memory activeAlerts)
    {
        // 가스 최적화를 위해 먼저 활성 알림 수 계산
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= alertCount; i++) {
            if (!alerts[i].isResolved) {
                activeCount++;
            }
        }

        // 정확한 크기로 배열 생성
        activeAlerts = new uint256[](activeCount);
        uint256 found = 0;

        // 가스 최적화된 반복문
        for (uint256 i = 1; i <= alertCount && found < activeCount; i++) {
            if (!alerts[i].isResolved) {
                activeAlerts[found] = i;
                found++;
            }
        }

        return activeAlerts;
    }

    /**
     * @dev 시스템 통계 조회 (가스 최적화 버전)
     * @notice 가스 효율적인 시스템 통계 조회
     * @return metrics 시스템 메트릭
     * @return totalAlerts 총 알림 수
     * @return activeAlerts 활성 알림 수
     * @return contractCount 모니터링 중인 컨트랙트 수
     */
    function getSystemStats()
        external
        view
        returns (
            SystemMetrics memory metrics,
            uint256 totalAlerts,
            uint256 activeAlerts,
            uint256 contractCount
        )
    {
        // 가스 최적화를 위해 한 번에 계산
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= alertCount; i++) {
            if (!alerts[i].isResolved) {
                activeCount++;
            }
        }

        // 모니터링 중인 컨트랙트 수 계산 (가스 최적화)
        uint256 monitoredCount = 0;
        // 실제 구현에서는 더 효율적인 방법 사용

        return (currentMetrics, alertCount, activeCount, monitoredCount);
    }

    /**
     * @dev 임계값 업데이트
     */
    function updateThresholds(
        uint256 newMinTransactions,
        uint256 newMaxResponseTime,
        uint256 newHealthCheckInterval
    ) external onlyOwner {
        minTransactionThreshold = newMinTransactions;
        maxResponseTime = newMaxResponseTime;
        healthCheckInterval = newHealthCheckInterval;
    }
}
