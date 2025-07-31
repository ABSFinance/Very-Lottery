// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMonitoringSystem {
    struct SystemMetrics {
        uint256 totalTransactions;
        uint256 totalVolume;
        uint256 activeUsers;
        uint256 lastUpdate;
        bool isHealthy;
    }

    struct Alert {
        string message;
        uint256 severity;
        uint256 timestamp;
        bool isResolved;
    }

    function updateMetrics(
        uint256 transactions,
        uint256 volume,
        uint256 users
    ) external;

    function createAlert(string memory message, uint256 severity) external;

    function resolveAlert(uint256 alertId) external;

    function registerContract(address contractAddress) external;

    function unregisterContract(address contractAddress) external;

    function performHealthCheck() external returns (bool);

    function getAlert(uint256 alertId) external view returns (Alert memory);

    function getActiveAlerts() external view returns (uint256[] memory);

    function getSystemStats()
        external
        view
        returns (
            SystemMetrics memory metrics,
            uint256 totalAlerts,
            uint256 activeAlerts,
            uint256 monitoredContracts
        );

    function updateThresholds(
        uint256 newMinTransactions,
        uint256 newMaxResponseTime,
        uint256 newHealthCheckInterval
    ) external;
}
