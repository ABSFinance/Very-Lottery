// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IDistribution
 * @dev 분배 시스템 공통 인터페이스
 */
interface IDistribution {
    // 기본 분배 함수들
    function distributeFunds(address recipient, uint256 amount) external returns (bool);

    function calculateDistribution(address user, uint256 totalAmount) external view returns (uint256);

    function getDistributionHistory(address user)
        external
        view
        returns (uint256 totalReceived, uint256 lastDistribution, uint256 distributionCount);

    // 이벤트
    event FundsDistributed(address indexed recipient, uint256 amount, uint256 timestamp);
    event DistributionCalculated(
        address indexed user, uint256 totalAmount, uint256 distributionAmount, uint256 timestamp
    );
}
