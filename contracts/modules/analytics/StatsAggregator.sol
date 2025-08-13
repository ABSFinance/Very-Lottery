// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {GasOptimizer} from "../../shared/utils/GasOptimizer.sol";

using GasOptimizer for address[];

/**
 * @title Cryptolotto Stats Aggregator
 * @author Cryptolotto Team
 * @notice Tracks game statistics and winner information
 * @dev Provides comprehensive statistics tracking for lottery games
 */
contract StatsAggregator is Ownable {
    /**
     * @notice Constructor for the StatsAggregator contract
     */
    constructor() Ownable() {}

    /**
     * @notice Emitted when a new winner is selected
     * @param winner The address of the winner
     * @param game The game number
     * @param players Number of players in the game
     * @param amount Amount won by the winner
     * @param gameType Type of game (1-day, 7-day, etc.)
     * @param winnerIndex Index of the winner in the players array
     * @param timestamp Timestamp when the winner was selected
     */
    event Winner(
        address indexed winner,
        uint256 indexed game,
        uint256 indexed players,
        uint256 amount,
        uint8 gameType,
        uint256 winnerIndex,
        uint256 timestamp
    );

    /**
     * @notice Mapping of player addresses to their win count
     */
    mapping(address => uint256) public winnerCount;
    /**
     * @notice Mapping of game numbers to winner addresses
     */
    mapping(uint256 => address) public gameWinners;
    /**
     * @notice Mapping of player addresses to their total winnings
     */
    mapping(address => uint256) public totalWinnings;

    // Top player 집계를 위한 상태 변수
    /**
     * @notice Array of all players who have participated
     */
    address[] public allPlayers;
    /**
     * @notice Mapping of player addresses to their scores
     */
    mapping(address => uint256) public playerScores;

    /**
     * @notice Record a new winner and update statistics
     * @param winner Winner address
     * @param game Game number
     * @param players Number of players in game
     * @param amount Amount won
     * @param gameType Type of game
     * @param winnerIndex Winner index in players array
     */
    function newWinner(
        address winner,
        uint256 game,
        uint256 players,
        uint256 amount,
        uint8 gameType,
        uint256 winnerIndex
    ) public {
        ++winnerCount[winner]; // solhint-disable-line gas-increment-by-one
        gameWinners[game] = winner;
        totalWinnings[winner] += amount;

        // Gas optimized player addition (improved duplicate check)
        bool exists = false;
        uint256 len = allPlayers.length;

        // Use early return pattern for gas optimization
        for (uint256 i = 0; i < len; ++i) {
            // solhint-disable-line gas-increment-by-one
            if (allPlayers[i] == winner) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            allPlayers.push(winner);
        }

        // playerScores에 당첨 금액 누적
        playerScores[winner] += amount;

        emit Winner(
            winner,
            game,
            players,
            amount,
            gameType,
            winnerIndex,
            block.timestamp // solhint-disable-line not-rely-on-time
        );
    }

    /**
     * @notice Get winner count for a specific player
     * @param player The player address
     * @return Number of wins for the player
     */
    function getWinnerCount(address player) public view returns (uint256) {
        return winnerCount[player];
    }

    /**
     * @notice Get total winnings for a specific player
     * @param player The player address
     * @return Total amount won by the player
     */
    function getTotalWinnings(address player) public view returns (uint256) {
        return totalWinnings[player];
    }

    /**
     * @notice Get winner of a specific game
     * @param game The game number
     * @return Address of the winner
     */
    function getGameWinner(uint256 game) public view returns (address) {
        return gameWinners[game];
    }

    /**
     * @notice Get comprehensive player statistics
     * @param player The player address
     * @return wins Number of wins
     * @return totalWon Total amount won
     * @return hasWon Whether the player has won at least once
     */
    function getPlayerStats(
        address player
    ) public view returns (uint256 wins, uint256 totalWon, bool hasWon) {
        return (
            winnerCount[player],
            totalWinnings[player],
            winnerCount[player] > 0
        );
    }

    /**
     * @notice Get top players (gas optimized version)
     * @param count Number of players to retrieve
     * @return topPlayers Array of top player addresses
     * @return scores Array of player scores
     */
    function getTopPlayers(
        uint256 count
    )
        public
        view
        returns (address[] memory topPlayers, uint256[] memory scores)
    {
        address[] storage players = allPlayers;
        uint256 length = players.length;
        uint256 found = 0;

        // Use fixed size array for gas optimization
        topPlayers = new address[](count);
        scores = new uint256[](count);

        // Gas optimized loop
        for (uint256 i = 0; i < length && found < count; ++i) {
            // solhint-disable-line gas-increment-by-one
            address player = players[i];
            uint256 score = playerScores[player];

            // 점수가 있는 플레이어만 추가
            if (score > 0) {
                topPlayers[found] = player;
                scores[found] = score;
                ++found; // solhint-disable-line gas-increment-by-one
            }
        }

        return (topPlayers, scores);
    }

    /**
     * @notice Get top winners (gas optimized version)
     * @param count Number of winners to retrieve
     * @return topWinners Array of top winner addresses
     */
    function getTopWinners(
        uint256 count
    ) public view returns (address[] memory topWinners) {
        // Use fixed size array for gas optimization
        topWinners = new address[](count);
        uint256 found = 0;

        // Gas optimized implementation
        address[] storage players = allPlayers;
        uint256 length = players.length;

        for (uint256 i = 0; i < length && found < count; ++i) {
            // solhint-disable-line gas-increment-by-one
            address player = players[i];
            if (winnerCount[player] > 0) {
                topWinners[found] = player;
                ++found; // solhint-disable-line gas-increment-by-one
            }
        }

        return topWinners;
    }

    /**
     * @notice Get batch winner statistics (gas optimized)
     * @param players Array of player addresses to query
     * @return winnerCounts Array of win counts
     * @return totalWinningsArray Array of total winnings
     */
    function getBatchWinnerStats(
        address[] calldata players
    )
        external
        view
        returns (
            uint256[] memory winnerCounts,
            uint256[] memory totalWinningsArray
        )
    {
        // Gas optimized duplicate removal
        address[] memory uniquePlayers = players.removeDuplicatesFromMemory();

        winnerCounts = new uint256[](uniquePlayers.length);
        totalWinningsArray = new uint256[](uniquePlayers.length);

        for (uint256 i = 0; i < uniquePlayers.length; ++i) {
            // solhint-disable-line gas-increment-by-one
            winnerCounts[i] = winnerCount[uniquePlayers[i]];
            totalWinningsArray[i] = totalWinnings[uniquePlayers[i]];
        }

        return (winnerCounts, totalWinningsArray);
    }

    /**
     * @notice Get top player analysis (gas optimized)
     * @param count Number of players to analyze
     * @return players Array of player addresses
     * @return scores Array of player scores
     * @return winRates Array of win rates
     */
    function getTopPlayerAnalysis(
        uint256 count
    )
        external
        view
        returns (
            address[] memory players,
            uint256[] memory scores,
            uint256[] memory winRates
        )
    {
        (players, scores) = getTopPlayers(count);
        winRates = new uint256[](count);

        for (uint256 i = 0; i < count; ++i) {
            // solhint-disable-line gas-increment-by-one
            if (players[i] != address(0)) {
                // Win rate calculation (gas optimized)
                uint256 wins = winnerCount[players[i]];
                uint256 totalGames = 0; // 실제로는 게임 참여 수를 추적해야 함
                winRates[i] = totalGames > 0 ? (wins * 100) / totalGames : 0;
            }
        }

        return (players, scores, winRates);
    }
}
