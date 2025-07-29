// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title EventLogger
 * @dev 중앙화된 이벤트 로깅 시스템
 */
contract EventLogger is Initializable, OwnableUpgradeable {
    // Event struct
    struct LogEntry {
        string eventType;
        string message;
        address indexedAddress;
        uint256 timestamp;
        uint256 blockNumber;
        bytes data;
    }

    // Logging state
    mapping(string => LogEntry[]) public eventLogs;
    mapping(address => LogEntry[]) public addressLogs;
    uint256 public totalLogs;

    // Configuration
    bool public loggingEnabled;
    uint256 public maxLogsPerEvent = 1000;
    uint256 public maxLogsPerAddress = 1000;

    // Events
    event LogEntryCreated(
        string indexed eventType,
        address indexed indexedAddress,
        string message,
        uint256 timestamp,
        uint256 logId
    );
    event LoggingToggled(bool enabled, uint256 timestamp);
    event MaxLogsUpdated(uint256 oldMax, uint256 newMax, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        loggingEnabled = true;
    }

    /**
     * @dev 로그 엔트리 생성
     */
    function logEvent(
        string memory eventType,
        string memory message,
        address indexedAddress,
        bytes memory data
    ) external onlyOwner {
        require(loggingEnabled, "Logging is disabled");

        LogEntry memory entry = LogEntry({
            eventType: eventType,
            message: message,
            indexedAddress: indexedAddress,
            timestamp: block.timestamp,
            blockNumber: block.number,
            data: data
        });

        // 이벤트 타입별 로그 저장
        eventLogs[eventType].push(entry);
        if (eventLogs[eventType].length > maxLogsPerEvent) {
            // Remove oldest entry
            for (uint i = 0; i < eventLogs[eventType].length - 1; i++) {
                eventLogs[eventType][i] = eventLogs[eventType][i + 1];
            }
            eventLogs[eventType].pop();
        }

        // 주소별 로그 저장
        addressLogs[indexedAddress].push(entry);
        if (addressLogs[indexedAddress].length > maxLogsPerAddress) {
            // Remove oldest entry
            for (uint i = 0; i < addressLogs[indexedAddress].length - 1; i++) {
                addressLogs[indexedAddress][i] = addressLogs[indexedAddress][
                    i + 1
                ];
            }
            addressLogs[indexedAddress].pop();
        }

        totalLogs++;

        emit LogEntryCreated(
            eventType,
            indexedAddress,
            message,
            block.timestamp,
            totalLogs
        );
    }

    /**
     * @dev 로깅 활성화/비활성화
     */
    function toggleLogging() external onlyOwner {
        loggingEnabled = !loggingEnabled;
        emit LoggingToggled(loggingEnabled, block.timestamp);
    }

    /**
     * @dev 최대 로그 수 업데이트
     */
    function updateMaxLogs(
        uint256 newMaxLogsPerEvent,
        uint256 newMaxLogsPerAddress
    ) external onlyOwner {
        require(
            newMaxLogsPerEvent > 0,
            "Max logs per event must be greater than 0"
        );
        require(
            newMaxLogsPerAddress > 0,
            "Max logs per address must be greater than 0"
        );

        uint256 oldMaxEvent = maxLogsPerEvent;
        uint256 oldMaxAddress = maxLogsPerAddress;

        maxLogsPerEvent = newMaxLogsPerEvent;
        maxLogsPerAddress = newMaxLogsPerAddress;

        emit MaxLogsUpdated(oldMaxEvent, newMaxLogsPerEvent, block.timestamp);
    }

    /**
     * @dev 이벤트 타입별 로그 조회
     */
    function getEventLogs(
        string memory eventType
    ) external view returns (LogEntry[] memory) {
        return eventLogs[eventType];
    }

    /**
     * @dev 주소별 로그 조회
     */
    function getAddressLogs(
        address targetAddress
    ) external view returns (LogEntry[] memory) {
        return addressLogs[targetAddress];
    }

    /**
     * @dev 최근 로그 조회
     */
    function getRecentLogs(
        uint256 count
    ) external view returns (LogEntry[] memory) {
        require(count > 0, "Count must be greater than 0");

        // This is a simplified implementation
        // In production, you'd want to maintain a separate array for recent logs
        LogEntry[] memory recentLogs = new LogEntry[](count);
        return recentLogs;
    }

    /**
     * @dev 로그 통계 조회
     */
    function getLogStats()
        external
        view
        returns (
            uint256 totalLogs,
            bool loggingEnabled,
            uint256 maxLogsPerEvent,
            uint256 maxLogsPerAddress,
            uint256 eventTypesCount
        )
    {
        return (
            totalLogs,
            loggingEnabled,
            maxLogsPerEvent,
            maxLogsPerAddress,
            0 // Would need to count event types in production
        );
    }

    /**
     * @dev 로그 검색 (기본 구현)
     */
    function searchLogs(
        string memory eventType,
        address targetAddress,
        uint256 startTime,
        uint256 endTime
    ) external view returns (LogEntry[] memory) {
        // This is a simplified search implementation
        // In production, you'd want more sophisticated search logic
        return eventLogs[eventType];
    }
}
