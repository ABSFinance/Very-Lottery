// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Cryptolotto stats aggregator interface.
 */
interface ICryptolottoStatsAggregator {
    function newWinner(
        address winner,
        uint256 game,
        uint256 players,
        uint256 amount,
        uint8 gameType,
        uint256 winnerIndex
    ) external;

    function getWinnerCount(address player) external view returns (uint256);

    function getTotalWinnings(address player) external view returns (uint256);

    function getGameWinner(uint256 game) external view returns (address);

    function getPlayerStats(address player) external view returns (uint256 wins, uint256 totalWon, bool hasWon);

    function getTopWinners(uint256 count) external view returns (address[] memory);
}
