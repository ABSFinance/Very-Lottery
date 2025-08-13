// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./StorageLayout.sol";
import "./StorageAccess.sol";

/**
 * @title StorageMigration
 * @dev 스토리지 마이그레이션 시스템
 * 업그레이드 시 데이터 마이그레이션을 안전하게 처리
 */
contract StorageMigration is Ownable, StorageAccess {
    // ============ MIGRATION EVENTS ============
    event MigrationStarted(
        uint256 fromVersion,
        uint256 toVersion,
        uint256 timestamp
    );
    event MigrationCompleted(
        uint256 version,
        uint256 recordsMigrated,
        uint256 timestamp
    );
    event MigrationFailed(uint256 version, string reason, uint256 timestamp);
    event RollbackCompleted(uint256 version, uint256 timestamp);

    // ============ MIGRATION STATE ============
    bool public isMigrationInProgress;
    uint256 public currentMigrationVersion;
    mapping(uint256 => MigrationPlan) public migrationPlans;

    struct MigrationPlan {
        bool exists;
        uint256 fromVersion;
        uint256 toVersion;
        string[] operations;
        bool isReversible;
        uint256 estimatedGas;
    }

    // ============ CONSTRUCTOR ============
    constructor() Ownable() {}

    // ============ MIGRATION PLANNING ============

    /**
     * @dev 마이그레이션 계획 생성
     */
    function createMigrationPlan(
        uint256 fromVersion,
        uint256 toVersion,
        string[] memory operations,
        bool isReversible,
        uint256 estimatedGas
    ) external onlyOwner {
        require(fromVersion < toVersion, "Invalid version order");
        require(operations.length > 0, "No operations specified");

        migrationPlans[toVersion] = MigrationPlan({
            exists: true,
            fromVersion: fromVersion,
            toVersion: toVersion,
            operations: operations,
            isReversible: isReversible,
            estimatedGas: estimatedGas
        });
    }

    /**
     * @dev 마이그레이션 시작
     */
    function startMigration(uint256 targetVersion) external onlyOwner {
        require(!isMigrationInProgress, "Migration already in progress");
        require(
            migrationPlans[targetVersion].exists,
            "Migration plan not found"
        );

        isMigrationInProgress = true;
        currentMigrationVersion = targetVersion;

        emit MigrationStarted(
            migrationPlans[targetVersion].fromVersion,
            targetVersion,
            block.timestamp
        );
    }

    // ============ MIGRATION OPERATIONS ============

    /**
     * @dev 게임 데이터 마이그레이션
     */
    function migrateGameData(uint256 gameId) external onlyOwner {
        require(isMigrationInProgress, "No migration in progress");

        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = gameStorage.games[gameId];

        // 게임 데이터 업데이트
        if (game.state == StorageLayout.GameState.WAITING) {
            game.state = StorageLayout.GameState.ACTIVE;
        }

        // 플레이어 데이터 정리
        address[] storage players = game.players;
        for (uint256 i = 0; i < players.length; i++) {
            // 플레이어 데이터 검증 및 정리
            if (players[i] == address(0)) {
                // 빈 주소 제거
                players[i] = players[players.length - 1];
                players.pop();
                i--;
            }
        }
    }

    /**
     * @dev 재무 데이터 마이그레이션
     */
    function migrateTreasuryData(
        string memory treasuryName
    ) external onlyOwner {
        require(isMigrationInProgress, "No migration in progress");

        StorageLayout.TreasuryStorage
            storage treasuryStorage = getTreasuryStorage();
        StorageLayout.Treasury storage treasury = treasuryStorage.treasuries[
            treasuryName
        ];

        // 재무 데이터 검증
        if (treasury.totalBalance < treasury.reservedBalance) {
            treasury.reservedBalance = treasury.totalBalance;
        }

        // 사용자 잔액 정리
        // mapping(address => uint256) storage userBalances = treasuryStorage.userBalances;
        // 0 잔액 사용자 정리 로직
    }

    /**
     * @dev 분석 데이터 마이그레이션
     */
    function migrateAnalyticsData() external onlyOwner {
        require(isMigrationInProgress, "No migration in progress");

        StorageLayout.AnalyticsStorage
            storage analyticsStorage = getAnalyticsStorage();

        // 승자 데이터 정리
        address[] storage allPlayers = analyticsStorage.allPlayers;
        for (uint256 i = 0; i < allPlayers.length; i++) {
            address player = allPlayers[i];
            if (
                analyticsStorage.winnerCount[player] == 0 &&
                analyticsStorage.totalWinnings[player] == 0
            ) {
                // 비활성 플레이어 제거
                allPlayers[i] = allPlayers[allPlayers.length - 1];
                allPlayers.pop();
                i--;
            }
        }
    }

    // ============ MIGRATION COMPLETION ============

    /**
     * @dev 마이그레이션 완료
     */
    function completeMigration() external onlyOwner {
        require(isMigrationInProgress, "No migration in progress");

        uint256 recordsMigrated = 0;

        // 마이그레이션 통계 수집
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        recordsMigrated += gameStorage.totalGames;

        StorageLayout.AnalyticsStorage
            storage analyticsStorage = getAnalyticsStorage();
        recordsMigrated += analyticsStorage.allPlayers.length;

        isMigrationInProgress = false;

        emit MigrationCompleted(
            currentMigrationVersion,
            recordsMigrated,
            block.timestamp
        );
    }

    /**
     * @dev 마이그레이션 실패 처리
     */
    function failMigration(string memory reason) external onlyOwner {
        require(isMigrationInProgress, "No migration in progress");

        isMigrationInProgress = false;

        emit MigrationFailed(currentMigrationVersion, reason, block.timestamp);
    }

    // ============ ROLLBACK OPERATIONS ============

    /**
     * @dev 마이그레이션 롤백
     */
    function rollbackMigration(uint256 targetVersion) external onlyOwner {
        require(!isMigrationInProgress, "Migration in progress");
        require(
            migrationPlans[targetVersion].isReversible,
            "Migration not reversible"
        );

        // 롤백 로직 구현
        // 이전 버전으로 데이터 복원

        emit RollbackCompleted(targetVersion, block.timestamp);
    }

    // ============ MIGRATION UTILITIES ============

    /**
     * @dev 마이그레이션 상태 확인
     */
    function getMigrationStatus()
        external
        view
        returns (
            bool inProgress,
            uint256 currentVersion,
            uint256 targetVersion,
            uint256 estimatedGas
        )
    {
        return (
            isMigrationInProgress,
            currentMigrationVersion,
            isMigrationInProgress ? currentMigrationVersion : 0,
            isMigrationInProgress
                ? migrationPlans[currentMigrationVersion].estimatedGas
                : 0
        );
    }

    /**
     * @dev 마이그레이션 계획 조회
     */
    function getMigrationPlan(
        uint256 version
    )
        external
        view
        returns (
            bool exists,
            uint256 fromVersion,
            uint256 toVersion,
            string[] memory operations,
            bool isReversible,
            uint256 estimatedGas
        )
    {
        MigrationPlan storage plan = migrationPlans[version];
        return (
            plan.exists,
            plan.fromVersion,
            plan.toVersion,
            plan.operations,
            plan.isReversible,
            plan.estimatedGas
        );
    }
}
