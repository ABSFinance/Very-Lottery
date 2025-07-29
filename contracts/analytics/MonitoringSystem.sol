// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title MonitoringSystem
 * @dev 시스템 모니터링을 위한 컨트랙트
 */
contract MonitoringSystem is Initializable, OwnableUpgradeable {
    // Monitoring data
    struct SystemMetrics {
        uint256 totalTransactions;
        uint256 totalVolume;
        uint256 activeUsers;
        uint256 lastUpdate;
        bool isHealthy;
    }

    struct Alert {
        string message;
        uint256 severity; // 1: Low, 2: Medium, 3: High, 4: Critical
        uint256 timestamp;
        bool isResolved;
    }

    // State variables
    SystemMetrics public currentMetrics;
    mapping(uint256 => Alert) public alerts;
    uint256 public alertCount;
    mapping(address => bool) public monitoredContracts;
    mapping(address => uint256) public contractLastCheck;

    // Thresholds
    uint256 public minTransactionThreshold = 10;
    uint256 public maxResponseTime = 300; // 5 minutes
    uint256 public healthCheckInterval = 3600; // 1 hour

    // Events
    event MetricsUpdated(
        uint256 totalTransactions,
        uint256 totalVolume,
        uint256 activeUsers,
        uint256 timestamp
    );
    event AlertCreated(
        uint256 indexed alertId,
        string message,
        uint256 severity,
        uint256 timestamp
    );
    event AlertResolved(uint256 indexed alertId, uint256 timestamp);
    event ContractRegistered(
        address indexed contractAddress,
        uint256 timestamp
    );
    event ContractUnregistered(
        address indexed contractAddress,
        uint256 timestamp
    );
    event HealthCheckPerformed(bool isHealthy, uint256 timestamp);

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
     * @dev 활성 알림 조회
     */
    function getActiveAlerts() external view returns (uint256[] memory) {
        uint256[] memory activeAlerts = new uint256[](alertCount);
        uint256 activeCount = 0;

        for (uint256 i = 1; i <= alertCount; i++) {
            if (!alerts[i].isResolved) {
                activeAlerts[activeCount] = i;
                activeCount++;
            }
        }

        // Resize array to actual active count
        assembly {
            mstore(activeAlerts, activeCount)
        }

        return activeAlerts;
    }

    /**
     * @dev 시스템 통계 조회
     */
    function getSystemStats()
        external
        view
        returns (
            SystemMetrics memory metrics,
            uint256 totalAlerts,
            uint256 activeAlerts,
            uint256 monitoredContracts
        )
    {
        uint256 activeCount = 0;
        uint256 monitoredCount = 0;

        for (uint256 i = 1; i <= alertCount; i++) {
            if (!alerts[i].isResolved) {
                activeCount++;
            }
        }

        // Count monitored contracts (simplified)
        monitoredCount = 0; // Would need to iterate through mapping in production

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
