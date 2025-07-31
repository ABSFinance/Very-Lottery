// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IEventLogger
 * @dev 중앙화된 이벤트 로깅을 위한 인터페이스
 */
interface IEventLogger {
    /**
     * @dev 이벤트 로깅
     * @param eventType 이벤트 타입
     * @param message 이벤트 메시지
     * @param indexedAddress 인덱싱된 주소
     * @param data 추가 데이터
     */
    function logEvent(
        string memory eventType,
        string memory message,
        address indexedAddress,
        bytes memory data
    ) external;

    /**
     * @dev 로깅 활성화/비활성화 토글
     */
    function toggleLogging() external;

    /**
     * @dev 로깅 상태 확인
     */
    function isLoggingEnabled() external view returns (bool);
}
