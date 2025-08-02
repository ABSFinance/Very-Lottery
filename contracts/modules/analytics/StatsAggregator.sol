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
        uint256 game,
        uint256 players,
        uint256 amount,
        uint8 gameType,
        uint256 winnerIndex,
        uint256 timestamp
    );

    /**
     * @dev Store winner statistics
     */
    mapping(address => uint256) public winnerCount;
    mapping(uint256 => address) public gameWinners;
    mapping(address => uint256) public totalWinnings;

    // Top player 집계를 위한 상태 변수
    address[] public allPlayers;
    mapping(address => uint256) public playerScores;

    /**
     * @dev Write info to log about the new winner.
     * @notice 가스 최적화된 승자 정보 기록
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
        winnerCount[winner]++;
        gameWinners[game] = winner;
        totalWinnings[winner] += amount;

        // 가스 최적화된 플레이어 추가 (중복 체크 개선)
        bool exists = false;
        uint256 len = allPlayers.length;

        // 가스 최적화를 위해 early return 패턴 사용
        for (uint256 i = 0; i < len; i++) {
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

        emit Winner(winner, game, players, amount, gameType, winnerIndex, block.timestamp);
    }

    /**
     * @dev Get winner count for address
     */
    function getWinnerCount(address player) public view returns (uint256) {
        return winnerCount[player];
    }

    /**
     * @dev Get total winnings for address
     */
    function getTotalWinnings(address player) public view returns (uint256) {
        return totalWinnings[player];
    }

    /**
     * @dev Get winner of specific game
     */
    function getGameWinner(uint256 game) public view returns (address) {
        return gameWinners[game];
    }

    /**
     * @dev Get comprehensive player statistics
     */
    function getPlayerStats(address player) public view returns (uint256 wins, uint256 totalWon, bool hasWon) {
        return (winnerCount[player], totalWinnings[player], winnerCount[player] > 0);
    }

    /**
     * @dev Get top players (가스 최적화 버전)
     * @notice 가스 효율적인 상위 플레이어 조회
     * @param count 조회할 플레이어 수
     * @return topPlayers 상위 플레이어 배열
     * @return scores 플레이어 점수 배열
     */
    function getTopPlayers(uint256 count) public view returns (address[] memory topPlayers, uint256[] memory scores) {
        address[] storage players = allPlayers;
        uint256 length = players.length;
        uint256 found = 0;

        // 가스 최적화를 위해 고정 크기 배열 사용
        topPlayers = new address[](count);
        scores = new uint256[](count);

        // 가스 최적화된 반복문
        for (uint256 i = 0; i < length && found < count; i++) {
            address player = players[i];
            uint256 score = playerScores[player];

            // 점수가 있는 플레이어만 추가
            if (score > 0) {
                topPlayers[found] = player;
                scores[found] = score;
                found++;
            }
        }

        return (topPlayers, scores);
    }

    /**
     * @dev Get top winners (가스 최적화 버전)
     * @notice 가스 효율적인 상위 승자 조회
     * @param count 조회할 승자 수
     * @return topWinners 상위 승자 배열
     */
    function getTopWinners(uint256 count) public view returns (address[] memory topWinners) {
        // 가스 최적화를 위해 고정 크기 배열 사용
        topWinners = new address[](count);
        uint256 found = 0;

        // 가스 최적화된 구현
        address[] storage players = allPlayers;
        uint256 length = players.length;

        for (uint256 i = 0; i < length && found < count; i++) {
            address player = players[i];
            if (winnerCount[player] > 0) {
                topWinners[found] = player;
                found++;
            }
        }

        return topWinners;
    }

    /**
     * @dev 승자 통계 일괄 조회 (가스 최적화)
     * @param players 조회할 플레이어 배열
     * @return winnerCounts 승자 횟수 배열
     * @return totalWinningsArray 총 상금 배열
     */
    function getBatchWinnerStats(address[] memory players)
        external
        view
        returns (uint256[] memory winnerCounts, uint256[] memory totalWinningsArray)
    {
        // 가스 최적화된 중복 제거
        address[] memory uniquePlayers = players.removeDuplicatesFromMemory();

        winnerCounts = new uint256[](uniquePlayers.length);
        totalWinningsArray = new uint256[](uniquePlayers.length);

        for (uint256 i = 0; i < uniquePlayers.length; i++) {
            winnerCounts[i] = winnerCount[uniquePlayers[i]];
            totalWinningsArray[i] = totalWinnings[uniquePlayers[i]];
        }

        return (winnerCounts, totalWinningsArray);
    }

    /**
     * @dev 상위 플레이어 점수 분석 (가스 최적화)
     * @param count 조회할 플레이어 수
     * @return players 플레이어 배열
     * @return scores 점수 배열
     * @return winRates 승률 배열
     */
    function getTopPlayerAnalysis(uint256 count)
        external
        view
        returns (address[] memory players, uint256[] memory scores, uint256[] memory winRates)
    {
        (players, scores) = getTopPlayers(count);
        winRates = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            if (players[i] != address(0)) {
                // 승률 계산 (가스 최적화)
                uint256 wins = winnerCount[players[i]];
                uint256 totalGames = 0; // 실제로는 게임 참여 수를 추적해야 함
                winRates[i] = totalGames > 0 ? (wins * 100) / totalGames : 0;
            }
        }

        return (players, scores, winRates);
    }
}
