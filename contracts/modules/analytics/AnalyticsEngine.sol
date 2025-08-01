// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../shared/utils/GasOptimizer.sol";

using GasOptimizer for address[];

/**
 * @title AnalyticsEngine
 * @dev 분석 및 통계를 위한 엔진
 */
contract AnalyticsEngine is Initializable, OwnableUpgradeable {
    // Analytics data structures
    struct UserAnalytics {
        uint256 totalTransactions;
        uint256 totalVolume;
        uint256 lastActivity;
        uint256 gamesPlayed;
        uint256 totalWinnings;
        uint256 referralEarnings;
    }

    struct GameAnalytics {
        uint256 totalGames;
        uint256 totalPlayers;
        uint256 totalVolume;
        uint256 averageTicketPrice;
        uint256 totalWinnings;
        uint256 lastGameTime;
    }

    struct SystemAnalytics {
        uint256 totalUsers;
        uint256 totalVolume;
        uint256 totalTransactions;
        uint256 activeGames;
        uint256 totalWinnings;
        uint256 systemFees;
    }

    // Analytics mappings
    mapping(address => UserAnalytics) public userAnalytics;
    mapping(uint8 => GameAnalytics) public gameAnalytics;
    SystemAnalytics public systemAnalytics;

    // Time-based analytics
    mapping(uint256 => uint256) public dailyVolume; // day => volume
    mapping(uint256 => uint256) public dailyTransactions; // day => count
    mapping(uint256 => uint256) public dailyUsers; // day => count

    // Configuration
    bool public analyticsEnabled;
    uint256 public lastUpdateTime;

    // Events
    event UserAnalyticsUpdated(
        address indexed user,
        uint256 transactions,
        uint256 volume,
        uint256 timestamp
    );
    event GameAnalyticsUpdated(
        uint8 indexed gameType,
        uint256 games,
        uint256 players,
        uint256 volume,
        uint256 timestamp
    );
    event SystemAnalyticsUpdated(
        uint256 totalGames,
        uint256 totalPlayers,
        uint256 totalVolume,
        uint256 timestamp
    );
    event AnalyticsToggled(bool enabled, uint256 timestamp);

    // 추가된 이벤트들
    event PlayerAnalyticsUpdated(
        address indexed player,
        uint256 gamesPlayed,
        uint256 totalSpent,
        uint256 totalWon,
        uint256 timestamp
    );
    event GameAnalyticsCompleted(
        uint256 indexed gameNumber,
        uint256 playerCount,
        uint256 jackpot,
        address winner,
        uint256 timestamp
    );
    event RevenueAnalyticsUpdated(
        uint256 dailyRevenue,
        uint256 weeklyRevenue,
        uint256 monthlyRevenue,
        uint256 timestamp
    );
    event PerformanceMetricsUpdated(
        uint256 avgGameDuration,
        uint256 avgPlayersPerGame,
        uint256 avgJackpot,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        analyticsEnabled = true;
        lastUpdateTime = block.timestamp;
    }

    /**
     * @dev 사용자 분석 데이터 업데이트
     */
    function updateUserAnalytics(
        address user,
        uint256 transactions,
        uint256 volume,
        uint256 gamesPlayed,
        uint256 winnings,
        uint256 referralEarnings
    ) external onlyOwner {
        require(analyticsEnabled, "Analytics is disabled");

        UserAnalytics storage analytics = userAnalytics[user];
        analytics.totalTransactions = transactions;
        analytics.totalVolume = volume;
        analytics.lastActivity = block.timestamp;
        analytics.gamesPlayed = gamesPlayed;
        analytics.totalWinnings = winnings;
        analytics.referralEarnings = referralEarnings;

        emit UserAnalyticsUpdated(user, transactions, volume, block.timestamp);
    }

    /**
     * @dev 게임 분석 데이터 업데이트
     */
    function updateGameAnalytics(
        uint8 gameType,
        uint256 totalGames,
        uint256 totalPlayers,
        uint256 totalVolume,
        uint256 averageTicketPrice,
        uint256 totalWinnings
    ) external onlyOwner {
        require(analyticsEnabled, "Analytics is disabled");

        GameAnalytics storage analytics = gameAnalytics[gameType];
        analytics.totalGames = totalGames;
        analytics.totalPlayers = totalPlayers;
        analytics.totalVolume = totalVolume;
        analytics.averageTicketPrice = averageTicketPrice;
        analytics.totalWinnings = totalWinnings;
        analytics.lastGameTime = block.timestamp;

        emit GameAnalyticsUpdated(
            gameType,
            totalGames,
            totalPlayers,
            totalVolume,
            block.timestamp
        );
    }

    /**
     * @dev 시스템 분석 데이터 업데이트
     */
    function updateSystemAnalytics(
        uint256 totalUsers,
        uint256 totalVolume,
        uint256 totalTransactions,
        uint256 activeGames,
        uint256 totalWinnings,
        uint256 systemFees
    ) external onlyOwner {
        require(analyticsEnabled, "Analytics is disabled");

        systemAnalytics.totalUsers = totalUsers;
        systemAnalytics.totalVolume = totalVolume;
        systemAnalytics.totalTransactions = totalTransactions;
        systemAnalytics.activeGames = activeGames;
        systemAnalytics.totalWinnings = totalWinnings;
        systemAnalytics.systemFees = systemFees;

        lastUpdateTime = block.timestamp;

        emit SystemAnalyticsUpdated(
            totalUsers,
            totalVolume,
            totalTransactions,
            block.timestamp
        );
    }

    /**
     * @dev 일일 통계 업데이트
     */
    function updateDailyStats(
        uint256 day,
        uint256 volume,
        uint256 transactions,
        uint256 users
    ) external onlyOwner {
        require(analyticsEnabled, "Analytics is disabled");

        dailyVolume[day] = volume;
        dailyTransactions[day] = transactions;
        dailyUsers[day] = users;
    }

    /**
     * @dev 분석 활성화/비활성화
     */
    function toggleAnalytics() external onlyOwner {
        analyticsEnabled = !analyticsEnabled;
        emit AnalyticsToggled(analyticsEnabled, block.timestamp);
    }

    /**
     * @dev 사용자 분석 조회
     */
    function getUserAnalytics(
        address user
    ) external view returns (UserAnalytics memory) {
        return userAnalytics[user];
    }

    /**
     * @dev 게임 분석 조회
     */
    function getGameAnalytics(
        uint8 gameType
    ) external view returns (GameAnalytics memory) {
        return gameAnalytics[gameType];
    }

    /**
     * @dev 시스템 분석 조회
     */
    function getSystemAnalytics()
        external
        view
        returns (SystemAnalytics memory)
    {
        return systemAnalytics;
    }

    /**
     * @dev 일일 통계 조회
     */
    function getDailyStats(
        uint256 day
    )
        external
        view
        returns (uint256 volume, uint256 transactions, uint256 users)
    {
        return (dailyVolume[day], dailyTransactions[day], dailyUsers[day]);
    }

    /**
     * @dev 기간별 통계 조회
     */
    function getPeriodStats(
        uint256 startDay,
        uint256 endDay
    )
        external
        view
        returns (
            uint256 totalVolume,
            uint256 totalTransactions,
            uint256 totalUsers
        )
    {
        uint256 volume = 0;
        uint256 transactions = 0;
        uint256 users = 0;

        for (uint256 day = startDay; day <= endDay; day++) {
            volume += dailyVolume[day];
            transactions += dailyTransactions[day];
            users += dailyUsers[day];
        }

        return (volume, transactions, users);
    }

    /**
     * @dev Get top users by activity
     * @return Array of top user addresses
     */
    function getTopUsers(
        uint256 /* limit */
    ) external pure returns (address[] memory) {
        // 실제 구현에서는 상위 사용자 목록을 반환
        return new address[](0);
    }

    /**
     * @dev 사용자 활동 분석 (가스 최적화)
     * @param users 분석할 사용자 배열
     * @return activeUsers 활성 사용자 수
     * @return totalVolume 총 거래량
     */
    function analyzeUserActivity(
        address[] memory users
    ) external view returns (uint256 activeUsers, uint256 totalVolume) {
        // 가스 최적화된 중복 제거
        address[] memory uniqueUsers = users.removeDuplicatesFromMemory();

        for (uint256 i = 0; i < uniqueUsers.length; i++) {
            UserAnalytics storage analytics = userAnalytics[uniqueUsers[i]];
            if (analytics.lastActivity > block.timestamp - 24 hours) {
                activeUsers++;
            }
            totalVolume += analytics.totalVolume;
        }

        return (activeUsers, totalVolume);
    }

    /**
     * @dev 분석 통계 조회
     */
    function getAnalyticsStats()
        external
        view
        returns (
            bool enabled,
            uint256 updateTime,
            uint256 totalUsers,
            uint256 totalVolume,
            uint256 totalTransactions
        )
    {
        return (
            analyticsEnabled,
            lastUpdateTime,
            systemAnalytics.totalUsers,
            systemAnalytics.totalVolume,
            systemAnalytics.totalTransactions
        );
    }

    /**
     * @dev 게임 타입별 통계 비교 (가스 최적화)
     * @param gameTypes 비교할 게임 타입 배열
     * @return volumes 각 게임 타입별 거래량
     * @return players 각 게임 타입별 플레이어 수
     */
    function compareGameTypes(
        uint8[] memory gameTypes
    )
        external
        view
        returns (uint256[] memory volumes, uint256[] memory players)
    {
        volumes = new uint256[](gameTypes.length);
        players = new uint256[](gameTypes.length);

        for (uint256 i = 0; i < gameTypes.length; i++) {
            GameAnalytics storage analytics = gameAnalytics[gameTypes[i]];
            volumes[i] = analytics.totalVolume;
            players[i] = analytics.totalPlayers;
        }

        return (volumes, players);
    }

    /**
     * @dev 기간별 사용자 활동 분석 (가스 최적화)
     * @param users 분석할 사용자 배열
     * @param dayCount 기간 (일)
     * @return activeUsers 활성 사용자 수
     * @return totalVolume 총 거래량
     */
    function analyzeUserActivityByPeriod(
        address[] memory users,
        uint256 dayCount
    ) external view returns (uint256 activeUsers, uint256 totalVolume) {
        // 가스 최적화된 중복 제거
        address[] memory uniqueUsers = users.removeDuplicatesFromMemory();
        uint256 cutoffTime = block.timestamp - (dayCount * 1 days);

        for (uint256 i = 0; i < uniqueUsers.length; i++) {
            UserAnalytics storage analytics = userAnalytics[uniqueUsers[i]];
            if (analytics.lastActivity > cutoffTime) {
                activeUsers++;
            }
            totalVolume += analytics.totalVolume;
        }

        return (activeUsers, totalVolume);
    }
}
