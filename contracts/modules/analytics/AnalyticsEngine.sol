// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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
     * @dev 상위 사용자 조회 (기본 구현)
     */
    function getTopUsers(
        uint256 count
    ) external view returns (address[] memory) {
        // This is a simplified implementation
        // In production, you'd want to maintain sorted lists
        address[] memory topUsers = new address[](count);
        return topUsers;
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
}
