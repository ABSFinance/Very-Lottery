// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {GasOptimizer} from "../../shared/utils/GasOptimizer.sol";

using GasOptimizer for address[];
using GasOptimizer for uint256;

/**
 * @title AnalyticsEngine
 * @author Cryptolotto Team
 * @notice Contract for managing analytics and statistics
 * @dev This contract tracks user, game, and system analytics
 */
contract AnalyticsEngine is Initializable, OwnableUpgradeable {
    // Custom Errors
    error AnalyticsDisabled();
    error InvalidUser();
    error InvalidGameType();

    // User analytics structure
    struct UserAnalytics {
        uint256 totalTransactions;
        uint256 totalVolume;
        uint256 lastActivity;
        uint256 gamesPlayed;
        uint256 totalWinnings;
        uint256 referralEarnings;
    }

    // Game analytics structure
    struct GameAnalytics {
        uint256 totalGames;
        uint256 totalPlayers;
        uint256 totalVolume;
        uint256 averageTicketPrice;
        uint256 totalWinnings;
        uint256 lastGameTime;
    }

    // System analytics structure
    struct SystemAnalytics {
        uint256 totalUsers;
        uint256 totalVolume;
        uint256 totalTransactions;
        uint256 activeGames;
        uint256 totalWinnings;
        uint256 systemFees;
    }

    // State variables
    /**
     * @notice Mapping of user addresses to their analytics
     */
    mapping(address => UserAnalytics) public userAnalytics;
    /**
     * @notice Mapping of game types to their analytics
     */
    mapping(uint8 => GameAnalytics) public gameAnalytics;
    /**
     * @notice System-wide analytics
     */
    SystemAnalytics public systemAnalytics;

    // Daily statistics
    /**
     * @notice Daily volume by day
     */
    mapping(uint256 => uint256) public dailyVolume;
    /**
     * @notice Daily transactions by day
     */
    mapping(uint256 => uint256) public dailyTransactions;
    /**
     * @notice Daily users by day
     */
    mapping(uint256 => uint256) public dailyUsers;

    // Configuration
    /**
     * @notice Whether analytics is enabled
     */
    bool public analyticsEnabled;
    /**
     * @notice Last update timestamp
     */
    uint256 public lastUpdateTime;

    // Events
    /**
     * @notice Emitted when user analytics are updated
     * @param user The user address
     * @param transactions Number of transactions
     * @param volume Total volume
     * @param timestamp When the analytics were updated
     */
    event UserAnalyticsUpdated(
        address indexed user, uint256 indexed transactions, uint256 indexed volume, uint256 timestamp
    );

    /**
     * @notice Emitted when game analytics are updated
     * @param gameType The type of game
     * @param games Total number of games
     * @param players Total number of players
     * @param volume Total volume
     * @param timestamp When the analytics were updated
     */
    event GameAnalyticsUpdated(
        uint8 indexed gameType, uint256 indexed games, uint256 indexed players, uint256 volume, uint256 timestamp
    );
    /**
     * @notice Emitted when system analytics are updated
     * @param totalGames Total number of games
     * @param totalPlayers Total number of players
     * @param totalVolume Total volume
     * @param timestamp When the analytics were updated
     */
    event SystemAnalyticsUpdated(
        uint256 indexed totalGames, uint256 indexed totalPlayers, uint256 indexed totalVolume, uint256 timestamp
    );

    /**
     * @notice Emitted when analytics is toggled
     * @param enabled Whether analytics is enabled
     * @param timestamp When the setting was changed
     */
    event AnalyticsToggled(bool indexed enabled, uint256 indexed timestamp);

    /**
     * @notice Emitted when player analytics are updated
     * @param player The player address
     * @param gamesPlayed Number of games played
     * @param totalSpent Total amount spent
     * @param totalWon Total amount won
     * @param timestamp When the analytics were updated
     */
    event PlayerAnalyticsUpdated(
        address indexed player,
        uint256 indexed gamesPlayed,
        uint256 indexed totalSpent,
        uint256 totalWon,
        uint256 timestamp
    );

    /**
     * @notice Emitted when game analytics are completed
     * @param gameNumber The game number
     * @param playerCount Number of players
     * @param jackpot The jackpot amount
     * @param winner The winner address
     * @param timestamp When the game was completed
     */
    event GameAnalyticsCompleted(
        uint256 indexed gameNumber,
        uint256 indexed playerCount,
        uint256 indexed jackpot,
        address winner,
        uint256 timestamp
    );

    /**
     * @notice Emitted when revenue analytics are updated
     * @param dailyRevenue Daily revenue
     * @param weeklyRevenue Weekly revenue
     * @param monthlyRevenue Monthly revenue
     * @param timestamp When the analytics were updated
     */
    event RevenueAnalyticsUpdated(
        uint256 indexed dailyRevenue, uint256 indexed weeklyRevenue, uint256 indexed monthlyRevenue, uint256 timestamp
    );

    /**
     * @notice Emitted when performance metrics are updated
     * @param avgGameDuration Average game duration
     * @param avgPlayersPerGame Average players per game
     * @param avgJackpot Average jackpot
     * @param timestamp When the metrics were updated
     */
    event PerformanceMetricsUpdated(
        uint256 indexed avgGameDuration,
        uint256 indexed avgPlayersPerGame,
        uint256 indexed avgJackpot,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    /**
     * @notice Constructor for the AnalyticsEngine contract
     * @dev Disables initializers to prevent re-initialization
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the analytics engine contract
     * @param owner The owner of the contract
     */
    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        analyticsEnabled = true;
        lastUpdateTime = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Update user analytics data
     * @param user The user address
     * @param transactions Number of transactions
     * @param volume Total volume
     * @param gamesPlayed Number of games played
     * @param winnings Total winnings
     * @param referralEarnings Referral earnings
     */
    function updateUserAnalytics(
        address user,
        uint256 transactions,
        uint256 volume,
        uint256 gamesPlayed,
        uint256 winnings,
        uint256 referralEarnings
    ) external onlyOwner {
        if (!analyticsEnabled) {
            revert AnalyticsDisabled();
        }

        UserAnalytics storage analytics = userAnalytics[user];
        analytics.totalTransactions = transactions;
        analytics.totalVolume = volume;
        analytics.lastActivity = block.timestamp; // solhint-disable-line not-rely-on-time
        analytics.gamesPlayed = gamesPlayed;
        analytics.totalWinnings = winnings;
        analytics.referralEarnings = referralEarnings;

        emit UserAnalyticsUpdated(user, transactions, volume, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Update game analytics data
     * @param gameType The type of game
     * @param totalGames Total number of games
     * @param totalPlayers Total number of players
     * @param totalVolume Total volume
     * @param averageTicketPrice Average ticket price
     * @param totalWinnings Total winnings
     */
    function updateGameAnalytics(
        uint8 gameType,
        uint256 totalGames,
        uint256 totalPlayers,
        uint256 totalVolume,
        uint256 averageTicketPrice,
        uint256 totalWinnings
    ) external onlyOwner {
        if (!analyticsEnabled) {
            revert AnalyticsDisabled();
        }

        GameAnalytics storage analytics = gameAnalytics[gameType];
        analytics.totalGames = totalGames;
        analytics.totalPlayers = totalPlayers;
        analytics.totalVolume = totalVolume;
        analytics.averageTicketPrice = averageTicketPrice;
        analytics.totalWinnings = totalWinnings;
        analytics.lastGameTime = block.timestamp; // solhint-disable-line not-rely-on-time

        emit GameAnalyticsUpdated(gameType, totalGames, totalPlayers, totalVolume, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Update system analytics data
     * @param totalUsers Total number of users
     * @param totalVolume Total volume
     * @param totalTransactions Total transactions
     * @param activeGames Number of active games
     * @param totalWinnings Total winnings
     * @param systemFees System fees
     */
    function updateSystemAnalytics(
        uint256 totalUsers,
        uint256 totalVolume,
        uint256 totalTransactions,
        uint256 activeGames,
        uint256 totalWinnings,
        uint256 systemFees
    ) external onlyOwner {
        if (!analyticsEnabled) {
            revert AnalyticsDisabled();
        }

        systemAnalytics.totalUsers = totalUsers;
        systemAnalytics.totalVolume = totalVolume;
        systemAnalytics.totalTransactions = totalTransactions;
        systemAnalytics.activeGames = activeGames;
        systemAnalytics.totalWinnings = totalWinnings;
        systemAnalytics.systemFees = systemFees;

        lastUpdateTime = block.timestamp; // solhint-disable-line not-rely-on-time

        emit SystemAnalyticsUpdated(totalUsers, totalVolume, totalTransactions, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Update daily statistics
     * @param day The day number
     * @param volume Daily volume
     * @param transactions Daily transactions
     * @param users Daily users
     */
    function updateDailyStats(uint256 day, uint256 volume, uint256 transactions, uint256 users) external onlyOwner {
        if (!analyticsEnabled) {
            revert AnalyticsDisabled();
        }

        dailyVolume[day] = volume;
        dailyTransactions[day] = transactions;
        dailyUsers[day] = users;
    }

    /**
     * @notice Toggle analytics on/off
     */
    function toggleAnalytics() external onlyOwner {
        analyticsEnabled = !analyticsEnabled;
        emit AnalyticsToggled(analyticsEnabled, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Get user analytics
     * @param user The user address
     * @return UserAnalytics structure
     */
    function getUserAnalytics(address user) external view returns (UserAnalytics memory) {
        return userAnalytics[user];
    }

    /**
     * @notice Get game analytics
     * @param gameType The game type
     * @return GameAnalytics structure
     */
    function getGameAnalytics(uint8 gameType) external view returns (GameAnalytics memory) {
        return gameAnalytics[gameType];
    }

    /**
     * @notice Get system analytics
     * @return SystemAnalytics structure
     */
    function getSystemAnalytics() external view returns (SystemAnalytics memory) {
        return systemAnalytics;
    }

    /**
     * @notice Get daily statistics
     * @param day The day number
     * @return volume Daily volume
     * @return transactions Daily transactions
     * @return users Daily users
     */
    function getDailyStats(uint256 day) external view returns (uint256 volume, uint256 transactions, uint256 users) {
        return (dailyVolume[day], dailyTransactions[day], dailyUsers[day]);
    }

    /**
     * @notice Get period statistics
     * @param startDay Start day number
     * @param endDay End day number
     * @return totalVolume Total volume for the period
     * @return totalTransactions Total transactions for the period
     * @return totalUsers Total users for the period
     */
    function getPeriodStats(uint256 startDay, uint256 endDay)
        external
        view
        returns (uint256 totalVolume, uint256 totalTransactions, uint256 totalUsers)
    {
        for (uint256 day = startDay; day < endDay + 1; ++day) {
            totalVolume += dailyVolume[day];
            totalTransactions += dailyTransactions[day];
            totalUsers += dailyUsers[day];
        }
    }

    /**
     * @notice Get top users by activity
     * @return Array of top user addresses
     */
    function getTopUsers(uint256 /* limit */ ) external pure returns (address[] memory) {
        // In actual implementation, return top user list
        return new address[](0);
    }

    /**
     * @notice Analyze user activity (gas optimized)
     * @param users Array of users to analyze
     * @return activeUsers Number of active users
     * @return totalVolume Total volume
     */
    function analyzeUserActivity(address[] calldata users)
        external
        view
        returns (uint256 activeUsers, uint256 totalVolume)
    {
        // Gas optimized duplicate removal
        address[] memory uniqueUsers = users.removeDuplicatesFromMemory();

        for (uint256 i = 0; i < uniqueUsers.length; ++i) {
            UserAnalytics storage analytics = userAnalytics[uniqueUsers[i]];
            if (analytics.lastActivity > block.timestamp - 24 hours) {
                // solhint-disable-line not-rely-on-time
                ++activeUsers;
            }
            totalVolume += analytics.totalVolume;
        }

        return (activeUsers, totalVolume);
    }

    /**
     * @notice Get analytics statistics
     * @return enabled Whether analytics is enabled
     * @return updateTime Last update timestamp
     * @return totalUsers Total number of users
     * @return totalVolume Total volume
     * @return totalTransactions Total transactions
     */
    function getAnalyticsStats()
        external
        view
        returns (bool enabled, uint256 updateTime, uint256 totalUsers, uint256 totalVolume, uint256 totalTransactions)
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
     * @notice Compare statistics by game type (gas optimized)
     * @param gameTypes Array of game types to compare
     * @return volumes Volume for each game type
     * @return players Player count for each game type
     */
    function compareGameTypes(uint8[] calldata gameTypes)
        external
        view
        returns (uint256[] memory volumes, uint256[] memory players)
    {
        volumes = new uint256[](gameTypes.length);
        players = new uint256[](gameTypes.length);

        for (uint256 i = 0; i < gameTypes.length; ++i) {
            GameAnalytics storage analytics = gameAnalytics[gameTypes[i]];
            volumes[i] = analytics.totalVolume;
            players[i] = analytics.totalPlayers;
        }

        return (volumes, players);
    }

    /**
     * @notice Analyze user activity by period (gas optimized)
     * @param users Array of users to analyze
     * @param dayCount Period in days
     * @return activeUsers Number of active users
     * @return totalVolume Total volume
     */
    function analyzeUserActivityByPeriod(address[] calldata users, uint256 dayCount)
        external
        view
        returns (uint256 activeUsers, uint256 totalVolume)
    {
        // Gas optimized duplicate removal
        address[] memory uniqueUsers = users.removeDuplicatesFromMemory();
        uint256 cutoffTime = block.timestamp - (dayCount * 1 days); // solhint-disable-line not-rely-on-time

        for (uint256 i = 0; i < uniqueUsers.length; ++i) {
            UserAnalytics storage analytics = userAnalytics[uniqueUsers[i]];
            if (analytics.lastActivity > cutoffTime) {
                ++activeUsers;
            }
            totalVolume += analytics.totalVolume;
        }

        return (activeUsers, totalVolume);
    }
}
