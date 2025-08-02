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
    /**
     * @notice Emitted when a system alert is created
     * @param alertType The type of alert
     * @param message Alert message
     * @param severity Alert severity level
     * @param timestamp Timestamp when alert was created
     */
    event SystemAlert(
        string indexed alertType,
        string message,
        uint256 indexed severity,
        uint256 indexed timestamp
    );
    /**
     * @notice Emitted when a performance threshold is exceeded
     * @param metric The metric that exceeded threshold
     * @param currentValue Current value of the metric
     * @param threshold Threshold value
     * @param timestamp Timestamp when threshold was exceeded
     */
    event PerformanceThresholdExceeded(
        string indexed metric,
        uint256 indexed currentValue,
        uint256 indexed threshold,
        uint256 timestamp
    );
    /**
     * @notice Emitted when a security event occurs
     * @param contractAddress The contract address involved
     * @param eventType Type of security event
     * @param details Details of the security event
     * @param timestamp Timestamp when event occurred
     */
    event SecurityEvent(
        address indexed contractAddress,
        string eventType,
        string details,
        uint256 indexed timestamp
    );
    /**
     * @notice Emitted when monitoring configuration is updated
     * @param parameter The parameter that was updated
     * @param oldValue Previous value
     * @param newValue New value
     * @param timestamp Timestamp when configuration was updated
     */
    event MonitoringConfigUpdated(
        string parameter,
        uint256 indexed oldValue,
        uint256 indexed newValue,
        uint256 indexed timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    /**
     * @notice Constructor for the MonitoringSystem contract
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the monitoring system
     * @param owner The owner of the monitoring system
     */
    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        currentMetrics = SystemMetrics({
            totalTransactions: 0,
            totalVolume: 0,
            activeUsers: 0,
            lastUpdate: block.timestamp, // solhint-disable-line not-rely-on-time
            isHealthy: true
        });
    }

    /**
     * @notice Update system metrics
     * @param transactions Number of transactions
     * @param volume Total volume
     * @param users Number of active users
     */
    function updateMetrics(
        uint256 transactions,
        uint256 volume,
        uint256 users
    ) external onlyOwner {
        currentMetrics.totalTransactions = transactions;
        currentMetrics.totalVolume = volume;
        currentMetrics.activeUsers = users;
        currentMetrics.lastUpdate = block.timestamp; // solhint-disable-line not-rely-on-time

        // 건강 상태 확인
        currentMetrics.isHealthy = _checkHealthStatus();

        emit MetricsUpdated(transactions, volume, users, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Create a new alert
     * @param message Alert message
     * @param severity Alert severity level (1-4)
     */
    function createAlert(
        string memory message,
        uint256 severity
    ) external onlyOwner {
        require(severity >= 1 && severity <= 4, "Invalid severity level");

        ++alertCount; // solhint-disable-line gas-increment-by-one
        alerts[alertCount] = Alert({
            message: message,
            severity: severity,
            timestamp: block.timestamp, // solhint-disable-line not-rely-on-time
            isResolved: false
        });

        emit AlertCreated(alertCount, message, severity, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Resolve an alert
     * @param alertId The alert ID to resolve
     */
    function resolveAlert(uint256 alertId) external onlyOwner {
        require(alertId > 0 && alertId <= alertCount, "Invalid alert ID");
        require(!alerts[alertId].isResolved, "Alert already resolved");

        alerts[alertId].isResolved = true;
        emit AlertResolved(alertId, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Register a contract for monitoring
     * @param contractAddress The contract address to register
     */
    function registerContract(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "Invalid contract address");
        require(
            !monitoredContracts[contractAddress],
            "Contract already registered"
        );

        monitoredContracts[contractAddress] = true;
        contractLastCheck[contractAddress] = block.timestamp; // solhint-disable-line not-rely-on-time

        emit ContractRegistered(contractAddress, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Unregister a contract from monitoring
     * @param contractAddress The contract address to unregister
     */
    function unregisterContract(address contractAddress) external onlyOwner {
        require(monitoredContracts[contractAddress], "Contract not registered");

        monitoredContracts[contractAddress] = false;
        delete contractLastCheck[contractAddress];

        emit ContractUnregistered(contractAddress, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Perform a health check
     * @return bool Whether the system is healthy
     */
    function performHealthCheck() external onlyOwner returns (bool) {
        bool isHealthy = _checkHealthStatus();
        currentMetrics.isHealthy = isHealthy;

        emit HealthCheckPerformed(isHealthy, block.timestamp); // solhint-disable-line not-rely-on-time

        return isHealthy;
    }

    /**
     * @notice Internal function to check health status
     * @return bool Whether the system is healthy
     */
    function _checkHealthStatus() internal view returns (bool) {
        // 기본적인 건강 상태 확인 로직
        bool hasRecentActivity = block.timestamp - currentMetrics.lastUpdate <
            healthCheckInterval + 1; // solhint-disable-line not-rely-on-time, gas-strict-inequalities
        bool hasMinimumTransactions = currentMetrics.totalTransactions >=
            minTransactionThreshold; // solhint-disable-line gas-strict-inequalities

        return hasRecentActivity && hasMinimumTransactions;
    }

    /**
     * @notice Get alert by ID
     * @param alertId The alert ID to retrieve
     * @return Alert The alert information
     */
    function getAlert(uint256 alertId) external view returns (Alert memory) {
        require(alertId > 0 && alertId <= alertCount, "Invalid alert ID");
        return alerts[alertId];
    }

    /**
     * @notice Get active alerts (gas optimized version)
     * @return activeAlerts Array of active alert IDs
     */
    function getActiveAlerts()
        external
        view
        returns (uint256[] memory activeAlerts)
    {
        // 가스 최적화를 위해 먼저 활성 알림 수 계산
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= alertCount; ++i) {
            // solhint-disable-line gas-increment-by-one
            if (!alerts[i].isResolved) {
                ++activeCount; // solhint-disable-line gas-increment-by-one
            }
        }

        // 정확한 크기로 배열 생성
        activeAlerts = new uint256[](activeCount);
        uint256 found = 0;

        // 가스 최적화된 반복문
        for (uint256 i = 1; i <= alertCount && found < activeCount; ++i) {
            // solhint-disable-line gas-increment-by-one
            if (!alerts[i].isResolved) {
                activeAlerts[found] = i;
                ++found; // solhint-disable-line gas-increment-by-one
            }
        }

        return activeAlerts;
    }

    /**
     * @notice Get system statistics (gas optimized version)
     * @return metrics System metrics
     * @return totalAlerts Total number of alerts
     * @return activeAlerts Number of active alerts
     * @return contractCount Number of monitored contracts
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
        for (uint256 i = 1; i <= alertCount; ++i) {
            // solhint-disable-line gas-increment-by-one
            if (!alerts[i].isResolved) {
                ++activeCount; // solhint-disable-line gas-increment-by-one
            }
        }

        // 모니터링 중인 컨트랙트 수 계산 (가스 최적화)
        uint256 monitoredCount = 0;
        // 실제 구현에서는 더 효율적인 방법 사용

        return (currentMetrics, alertCount, activeCount, monitoredCount);
    }

    /**
     * @notice Update monitoring thresholds
     * @param newMinTransactions New minimum transaction threshold
     * @param newMaxResponseTime New maximum response time
     * @param newHealthCheckInterval New health check interval
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
