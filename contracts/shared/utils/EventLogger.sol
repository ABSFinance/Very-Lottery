// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEventLogger} from "../interfaces/IEventLogger.sol";

/**
 * @title EventLogger
 * @author Cryptolotto Team
 * @notice Centralized event logging system
 * @dev Provides comprehensive event logging and management functionality
 */
contract EventLogger is Ownable, IEventLogger {
    // Custom Errors
    error LoggingDisabled();
    error InvalidEventType();
    error InvalidMessage();
    error InvalidAddress();
    error InvalidData();

    // Event log structure
    struct EventLog {
        string eventType;
        string message;
        address indexedAddress;
        bytes data;
        uint256 timestamp;
        uint256 logIndex;
    }

    // State variables
    /**
     * @notice Whether logging is enabled
     */
    bool public loggingEnabled;
    /**
     * @notice Array of all event logs
     */
    EventLog[] public eventLogs;
    /**
     * @notice Mapping of event types to their count
     */
    mapping(string => uint256) public eventTypeCounters;

    // Events
    /**
     * @notice Emitted when an event is logged
     * @param eventType Type of event
     * @param message Event message
     * @param indexedAddress Associated address
     * @param timestamp Log timestamp
     */
    event EventLogged(
        string indexed eventType,
        string indexed message,
        address indexed indexedAddress,
        uint256 timestamp
    );
    /**
     * @notice Emitted when logging is toggled
     * @param enabled Whether logging is enabled
     * @param timestamp Toggle timestamp
     */
    event LoggingToggled(bool indexed enabled, uint256 indexed timestamp);
    /**
     * @notice Emitted when logs are cleared
     * @param timestamp Clear timestamp
     */
    event LogsCleared(uint256 indexed timestamp);

    /**
     * @notice Constructor for the event logger
     * @param owner Owner of the contract
     */
    constructor(address owner) Ownable() {
        loggingEnabled = true;
    }

    /**
     * @notice Log an event
     * @param eventType Type of event
     * @param message Event message
     * @param indexedAddress Associated address
     * @param data Additional data
     */
    function logEvent(
        string calldata eventType,
        string calldata message,
        address indexedAddress,
        bytes calldata data
    ) external override {
        if (!loggingEnabled) revert LoggingDisabled();
        if (bytes(eventType).length == 0) revert InvalidEventType();
        if (bytes(message).length == 0) revert InvalidMessage();

        EventLog memory newLog = _createEventLog(
            eventType,
            message,
            indexedAddress,
            data
        );
        _storeEventLog(newLog, eventType);
        _emitEventLogged(eventType, message, indexedAddress);
    }

    /**
     * @notice Create a new event log
     * @param eventType Type of event
     * @param message Event message
     * @param indexedAddress Associated address
     * @param data Additional data
     * @return newLog Created event log
     */
    function _createEventLog(
        string calldata eventType,
        string calldata message,
        address indexedAddress,
        bytes calldata data
    ) internal view returns (EventLog memory newLog) {
        return
            EventLog({
                eventType: eventType,
                message: message,
                indexedAddress: indexedAddress,
                data: data,
                timestamp: block.timestamp, // solhint-disable-line not-rely-on-time
                logIndex: eventLogs.length
            });
    }

    /**
     * @notice Store an event log
     * @param newLog Event log to store
     * @param eventType Type of event
     */
    function _storeEventLog(
        EventLog memory newLog,
        string calldata eventType
    ) internal {
        eventLogs.push(newLog);
        ++eventTypeCounters[eventType]; // solhint-disable-line gas-increment-by-one
    }

    /**
     * @notice Emit the EventLogged event
     * @param eventType Type of event
     * @param message Event message
     * @param indexedAddress Associated address
     */
    function _emitEventLogged(
        string calldata eventType,
        string calldata message,
        address indexedAddress
    ) internal {
        emit EventLogged(eventType, message, indexedAddress, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Toggle logging functionality
     */
    function toggleLogging() external onlyOwner {
        loggingEnabled = !loggingEnabled;
        emit LoggingToggled(loggingEnabled, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Check if logging is enabled
     * @return Whether logging is enabled
     */
    function isLoggingEnabled() external view returns (bool) {
        return loggingEnabled;
    }

    /**
     * @notice Clear all event logs
     */
    function clearLogs() external onlyOwner {
        delete eventLogs;
        emit LogsCleared(block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Get total event log count
     * @return Total number of event logs
     */
    function getEventLogCount() external view returns (uint256) {
        return eventLogs.length;
    }

    /**
     * @notice Get count of events by type
     * @param eventType Type of event
     * @return Count of events for the specified type
     */
    function getEventTypeCount(
        string calldata eventType
    ) external view returns (uint256) {
        return eventTypeCounters[eventType];
    }

    /**
     * @notice Get recent event logs
     * @param count Number of recent logs to retrieve
     * @return Array of recent event logs
     */
    function getRecentLogs(
        uint256 count
    ) external view returns (EventLog[] memory) {
        uint256 totalLogs = eventLogs.length;
        uint256 returnCount = count > totalLogs ? totalLogs : count;

        EventLog[] memory recentLogs = new EventLog[](returnCount);
        for (uint256 i = 0; i < returnCount; ++i) {
            // solhint-disable-line gas-increment-by-one
            recentLogs[i] = eventLogs[totalLogs - 1 - i];
        }

        return recentLogs;
    }
}
