// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Cryptolotto stats aggregator interface.
 */
interface ICryptolottoStatsAggregator {
    function newWinner(
        address winner,
        uint game,
        uint players,
        uint amount,
        uint8 gameType,
        uint winnerIndex
    ) external;

    function getWinnerCount(address player) external view returns (uint);

    function getTotalWinnings(address player) external view returns (uint);

    function getGameWinner(uint game) external view returns (address);

    function getPlayerStats(
        address player
    ) external view returns (uint wins, uint totalWon, bool hasWon);

    function getTopWinners(uint count) external view returns (address[] memory);
}
