// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEventLogger {
    struct LogEntry {
        string eventType;
        string message;
        address indexedAddress;
        uint256 timestamp;
        uint256 blockNumber;
        bytes data;
    }

    function logEvent(
        string memory eventType,
        string memory message,
        address indexedAddress,
        bytes memory data
    ) external;

    function toggleLogging() external;

    function updateMaxLogs(
        uint256 newMaxLogsPerEvent,
        uint256 newMaxLogsPerAddress
    ) external;

    function getEventLogs(
        string memory eventType
    ) external view returns (LogEntry[] memory);

    function getAddressLogs(
        address targetAddress
    ) external view returns (LogEntry[] memory);

    function getRecentLogs(
        uint256 count
    ) external view returns (LogEntry[] memory);

    function getLogStats()
        external
        view
        returns (
            uint256 totalLogs,
            bool loggingEnabled,
            uint256 maxLogsPerEvent,
            uint256 maxLogsPerAddress,
            uint256 eventTypesCount
        );

    function searchLogs(
        string memory eventType,
        address targetAddress,
        uint256 startTime,
        uint256 endTime
    ) external view returns (LogEntry[] memory);
}
