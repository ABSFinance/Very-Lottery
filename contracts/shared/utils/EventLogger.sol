// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEventLogger.sol";

/**
 * @title EventLogger
 * @dev 중앙화된 이벤트 로깅 시스템
 */
contract EventLogger is IEventLogger, Ownable {
    // 로깅 상태
    bool public loggingEnabled = true;

    // 이벤트 로그 구조체
    struct EventLog {
        string eventType;
        string message;
        address indexedAddress;
        bytes data;
        uint256 timestamp;
        uint256 blockNumber;
    }

    // 이벤트 로그 저장소
    EventLog[] public eventLogs;

    // 이벤트 타입별 카운터
    mapping(string => uint256) public eventTypeCounters;

    // Events
    event EventLogged(
        string indexed eventType,
        string message,
        address indexedAddress,
        uint256 timestamp
    );
    event LoggingToggled(bool enabled, uint256 timestamp);
    event LogsCleared(uint256 timestamp);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev 이벤트 로깅
     */
    function logEvent(
        string memory eventType,
        string memory message,
        address indexedAddress,
        bytes memory data
    ) external override {
        require(loggingEnabled, "Logging is disabled");

        EventLog memory newLog = EventLog({
            eventType: eventType,
            message: message,
            indexedAddress: indexedAddress,
            data: data,
            timestamp: block.timestamp,
            blockNumber: block.number
        });

        eventLogs.push(newLog);
        eventTypeCounters[eventType]++;

        emit EventLogged(eventType, message, indexedAddress, block.timestamp);
    }

    /**
     * @dev 로깅 활성화/비활성화 토글
     */
    function toggleLogging() external override onlyOwner {
        loggingEnabled = !loggingEnabled;
        emit LoggingToggled(loggingEnabled, block.timestamp);
    }

    /**
     * @dev 로깅 상태 확인
     */
    function isLoggingEnabled() external view override returns (bool) {
        return loggingEnabled;
    }

    /**
     * @dev 모든 로그 삭제 (긴급 상황용)
     */
    function clearLogs() external onlyOwner {
        delete eventLogs;
        emit LogsCleared(block.timestamp);
    }

    /**
     * @dev 이벤트 로그 개수 조회
     */
    function getEventLogCount() external view returns (uint256) {
        return eventLogs.length;
    }

    /**
     * @dev 특정 이벤트 타입의 로그 개수 조회
     */
    function getEventTypeCount(
        string memory eventType
    ) external view returns (uint256) {
        return eventTypeCounters[eventType];
    }

    /**
     * @dev 최근 로그 조회
     */
    function getRecentLogs(
        uint256 count
    ) external view returns (EventLog[] memory) {
        uint256 totalLogs = eventLogs.length;
        uint256 returnCount = count > totalLogs ? totalLogs : count;

        EventLog[] memory recentLogs = new EventLog[](returnCount);
        for (uint256 i = 0; i < returnCount; i++) {
            recentLogs[i] = eventLogs[totalLogs - 1 - i];
        }

        return recentLogs;
    }
}
