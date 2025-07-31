// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../shared/interfaces/IAnalyticsEngine.sol";
import "../../shared/utils/GasOptimizer.sol";

using GasOptimizer for address[];

/**
 * @title Cryptolotto Stats Aggregator
 * @dev Tracks game statistics and winner information
 */
contract StatsAggregator is Ownable {
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Winner event
     */
    event Winner(
        address indexed winner,
        uint game,
        uint players,
        uint amount,
        uint8 gameType,
        uint winnerIndex,
        uint timestamp
    );

    /**
     * @dev Store winner statistics
     */
    mapping(address => uint) public winnerCount;
    mapping(uint => address) public gameWinners;
    mapping(address => uint) public totalWinnings;

    // Top player 집계를 위한 상태 변수
    address[] public allPlayers;
    mapping(address => uint256) public playerScores;

    /**
     * @dev Write info to log about the new winner.
     *
     * @param winner Winner address
     * @param game Game number
     * @param players Number of players in game
     * @param amount Amount won
     * @param gameType Type of game
     * @param winnerIndex Winner index in players array
     */
    function newWinner(
        address winner,
        uint game,
        uint players,
        uint amount,
        uint8 gameType,
        uint winnerIndex
    ) public {
        winnerCount[winner]++;
        gameWinners[game] = winner;
        totalWinnings[winner] += amount;

        // allPlayers에 없으면 추가
        bool exists = false;
        uint len = allPlayers.length;
        for (uint i = 0; i < len; i++) {
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
            block.timestamp
        );
    }

    /**
     * @dev Get winner count for address
     */
    function getWinnerCount(address player) public view returns (uint) {
        return winnerCount[player];
    }

    /**
     * @dev Get total winnings for address
     */
    function getTotalWinnings(address player) public view returns (uint) {
        return totalWinnings[player];
    }

    /**
     * @dev Get winner of specific game
     */
    function getGameWinner(uint game) public view returns (address) {
        return gameWinners[game];
    }

    /**
     * @dev Get comprehensive player statistics
     */
    function getPlayerStats(
        address player
    ) public view returns (uint wins, uint totalWon, bool hasWon) {
        return (
            winnerCount[player],
            totalWinnings[player],
            winnerCount[player] > 0
        );
    }

    /**
     * @dev Get top winners (basic implementation)
     * Note: For full implementation, you might want to use a more sophisticated data structure
     */
    function getTopWinners(uint count) public view returns (address[] memory) {
        // This is a simplified implementation
        // For production, consider using a more efficient data structure
        address[] memory topWinners = new address[](count);
        uint found = 0;

        // This is a basic implementation - in production you'd want a more sophisticated approach
        for (uint i = 0; i < count && found < count; i++) {
            // This is just a placeholder - actual implementation would need to track winners properly
            if (found < count) {
                topWinners[found] = address(0);
                found++;
            }
        }

        return topWinners;
    }

    function getTopPlayers(
        uint256 count
    ) public view returns (address[] memory, uint256[] memory) {
        address[] storage players = allPlayers;
        uint256 length = players.length;
        uint256 found = 0;

        address[] memory topPlayers = new address[](count);
        uint256[] memory scores = new uint256[](count);

        for (uint i = 0; i < length && found < count; i++) {
            address player = players[i];
            uint256 score = playerScores[player];

            // 간단한 정렬 로직 (실제로는 더 효율적인 정렬이 필요)
            if (score > 0) {
                topPlayers[found] = player;
                scores[found] = score;
                found++;
            }
        }

        return (topPlayers, scores);
    }
}
