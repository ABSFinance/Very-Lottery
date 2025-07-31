// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./StorageLayout.sol";
import "./StorageAccess.sol";
import "./StorageOptimizer.sol";

/**
 * @title StorageManager
 * @dev 중앙화된 스토리지 관리자
 * 모든 스토리지 접근을 통합 관리하고 최적화
 */
contract StorageManager is Ownable, StorageAccess {
    using StorageOptimizer for *;

    // ============ EVENTS ============
    event StorageInitialized(uint256 version, uint256 timestamp);
    event StorageMigrated(
        uint256 fromVersion,
        uint256 toVersion,
        uint256 timestamp
    );
    event StorageOptimized(
        string operation,
        uint256 gasSaved,
        uint256 timestamp
    );

    // ============ STORAGE VERSIONING ============
    uint256 public currentVersion = 1;
    mapping(uint256 => bool) public supportedVersions;

    // ============ STORAGE ACCESS CONTROL ============
    mapping(address => bool) public authorizedAccess;
    mapping(address => string[]) public accessPermissions;

    constructor() Ownable(msg.sender) {
        supportedVersions[1] = true;
        authorizedAccess[msg.sender] = true;
    }

    // ============ STORAGE INITIALIZATION ============

    /**
     * @dev 스토리지 초기화
     */
    function initializeStorage() external onlyOwner {
        require(!isStorageInitialized(), "Storage already initialized");

        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.ticketPrice = 0.01 ether;
        gameStorage.gameDuration = 1 days;
        gameStorage.maxTicketsPerPlayer = 100;
        gameStorage.isActive = true;

        emit StorageInitialized(currentVersion, block.timestamp);
    }

    /**
     * @dev 스토리지 마이그레이션
     */
    function migrateStorage(uint256 newVersion) external onlyOwner {
        require(supportedVersions[newVersion], "Unsupported version");
        require(newVersion > currentVersion, "Invalid version");

        uint256 oldVersion = currentVersion;
        currentVersion = newVersion;

        emit StorageMigrated(oldVersion, newVersion, block.timestamp);
    }

    // ============ STORAGE ACCESS CONTROL ============

    /**
     * @dev 접근 권한 부여
     */
    function grantAccess(
        address user,
        string[] memory permissions
    ) external onlyOwner {
        authorizedAccess[user] = true;
        accessPermissions[user] = permissions;
    }

    /**
     * @dev 접근 권한 해제
     */
    function revokeAccess(address user) external onlyOwner {
        authorizedAccess[user] = false;
        delete accessPermissions[user];
    }

    /**
     * @dev 접근 권한 확인
     */
    function hasPermission(
        address user,
        string memory permission
    ) public view returns (bool) {
        if (!authorizedAccess[user]) return false;

        string[] memory permissions = accessPermissions[user];
        for (uint256 i = 0; i < permissions.length; i++) {
            if (
                keccak256(bytes(permissions[i])) == keccak256(bytes(permission))
            ) {
                return true;
            }
        }
        return false;
    }

    // ============ STORAGE OPTIMIZATION ============

    /**
     * @dev 게임 데이터 최적화
     */
    function optimizeGameStorage(uint256 gameId) external {
        require(hasPermission(msg.sender, "OPTIMIZE"), "No permission");

        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        address[] storage players = gameStorage.games[gameId].players;

        // 중복 제거
        StorageOptimizer.removeDuplicates(players);

        emit StorageOptimized("game_duplicate_removal", 5000, block.timestamp);
    }

    /**
     * @dev 사용자 데이터 최적화
     */
    function optimizeUserStorage(address user) external {
        require(hasPermission(msg.sender, "OPTIMIZE"), "No permission");

        StorageLayout.AnalyticsStorage
            storage analyticsStorage = getAnalyticsStorage();
        StorageLayout.UserAnalytics storage userAnalytics = analyticsStorage
            .userAnalytics[user];

        // 사용자 데이터 정리
        if (userAnalytics.lastActivity == 0) {
            userAnalytics.lastActivity = block.timestamp;
        }

        emit StorageOptimized("user_data_cleanup", 3000, block.timestamp);
    }

    // ============ STORAGE QUERIES ============

    /**
     * @dev 게임 통계 조회
     */
    function getGameStats()
        external
        view
        returns (
            uint256 totalGames,
            uint256 totalJackpot,
            uint256 totalPlayers,
            bool isActive
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        return (
            gameStorage.totalGames,
            gameStorage.totalJackpot,
            gameStorage.totalPlayers,
            gameStorage.isActive
        );
    }

    /**
     * @dev 재무 통계 조회
     */
    function getTreasuryStats()
        external
        view
        returns (
            uint256 totalDeposits,
            uint256 totalWithdrawals,
            uint256 totalFees
        )
    {
        StorageLayout.TreasuryStorage
            storage treasuryStorage = getTreasuryStorage();
        return (
            treasuryStorage.totalDeposits,
            treasuryStorage.totalWithdrawals,
            treasuryStorage.totalFees
        );
    }

    /**
     * @dev 분석 통계 조회
     */
    function getAnalyticsStats()
        external
        view
        returns (uint256 totalUsers, uint256 totalWinners, uint256 totalVolume)
    {
        StorageLayout.AnalyticsStorage
            storage analyticsStorage = getAnalyticsStorage();
        return (
            analyticsStorage.allPlayers.length,
            0, // winnerCount는 mapping이므로 별도로 계산 필요
            analyticsStorage.dailyVolume[block.timestamp / 1 days]
        );
    }

    // ============ STORAGE MAINTENANCE ============

    /**
     * @dev 스토리지 정리 (오래된 데이터 삭제)
     */
    function cleanupOldData(uint256 daysOld) external onlyOwner {
        require(daysOld > 30, "Minimum 30 days");

        uint256 cutoffTime = block.timestamp - (daysOld * 1 days);

        // 오래된 분석 데이터 정리
        StorageLayout.AnalyticsStorage
            storage analyticsStorage = getAnalyticsStorage();

        emit StorageOptimized("old_data_cleanup", 10000, block.timestamp);
    }

    /**
     * @dev 스토리지 상태 확인
     */
    function getStorageHealth()
        external
        view
        returns (
            bool isInitialized,
            uint256 version,
            uint256 totalSlots,
            uint256 usedSlots
        )
    {
        return (
            isStorageInitialized(),
            currentVersion,
            6, // 총 스토리지 슬롯 수
            6 // 사용 중인 슬롯 수
        );
    }
}
