// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAnalyticsEngine {
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

    function updateUserAnalytics(
        address user,
        uint256 transactions,
        uint256 volume,
        uint256 gamesPlayed,
        uint256 winnings,
        uint256 referralEarnings
    ) external;

    function updateGameAnalytics(
        uint8 gameType,
        uint256 totalGames,
        uint256 totalPlayers,
        uint256 totalVolume,
        uint256 averageTicketPrice,
        uint256 totalWinnings
    ) external;

    function updateSystemAnalytics(
        uint256 totalUsers,
        uint256 totalVolume,
        uint256 totalTransactions,
        uint256 activeGames,
        uint256 totalWinnings,
        uint256 systemFees
    ) external;

    function updateDailyStats(
        uint256 day,
        uint256 volume,
        uint256 transactions,
        uint256 users
    ) external;

    function toggleAnalytics() external;

    function getUserAnalytics(
        address user
    ) external view returns (UserAnalytics memory);

    function getGameAnalytics(
        uint8 gameType
    ) external view returns (GameAnalytics memory);

    function getSystemAnalytics()
        external
        view
        returns (SystemAnalytics memory);

    function getDailyStats(
        uint256 day
    )
        external
        view
        returns (uint256 volume, uint256 transactions, uint256 users);

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
        );

    function getTopUsers(
        uint256 count
    ) external view returns (address[] memory);

    function getAnalyticsStats()
        external
        view
        returns (
            bool analyticsEnabled,
            uint256 lastUpdateTime,
            uint256 totalUsers,
            uint256 totalVolume,
            uint256 totalTransactions
        );
}
