// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IAnalytics
 * @dev 분석 시스템 공통 인터페이스
 */
interface IAnalytics {
    // 기본 분석 함수들
    function recordEvent(string memory eventType, address user, uint256 value) external;

    function getUserStats(address user)
        external
        view
        returns (uint256 totalActivity, uint256 lastActivity, uint256 activityCount);

    function getSystemStats() external view returns (uint256 totalUsers, uint256 totalEvents, uint256 lastUpdateTime);

    // 이벤트
    event AnalyticsRecorded(string indexed eventType, address indexed user, uint256 value, uint256 timestamp);
}
