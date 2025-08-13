// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LotteryUtils {
    // Constants
    uint256 public constant PRECISION = 1e18;
    uint256 public constant MAX_TICKETS_PER_PLAYER = 100;
    uint256 public constant MIN_TICKET_PRICE = 0.001 ether;
    uint256 public constant MAX_TICKET_PRICE = 1 ether;

    // Structs
    struct GameInfo {
        uint256 gameNumber;
        uint256 ticketPrice;
        uint256 playerCount;
        uint256 jackpot;
        bool isActive;
        uint256 endTime;
    }

    struct PlayerInfo {
        uint256 ticketCount;
        uint256 lastPurchaseTime;
        uint256 totalSpent;
        bool isActive;
    }

    // Events
    event TicketPurchased(
        address indexed player,
        uint256 indexed gameNumber,
        uint256 ticketIndex,
        uint256 timestamp
    );
    event WinnerSelected(
        address indexed winner,
        uint256 indexed gameNumber,
        uint256 amount,
        uint256 timestamp
    );
    event GameEnded(
        uint256 indexed gameNumber,
        uint256 totalPlayers,
        uint256 totalJackpot,
        uint256 timestamp
    );
    event EmergencyPaused(
        address indexed pauser,
        string reason,
        uint256 timestamp
    );
    event EmergencyResumed(address indexed resumer, uint256 timestamp);

    // Validation functions
    function validateTicketPrice(
        uint256 ticketPrice
    ) internal pure returns (bool) {
        require(ticketPrice >= MIN_TICKET_PRICE, "Ticket price too low");
        require(ticketPrice <= MAX_TICKET_PRICE, "Ticket price too high");
        return true;
    }

    function validateTicketCount(
        uint256 ticketCount
    ) internal pure returns (bool) {
        require(ticketCount > 0, "Must buy at least 1 ticket");
        require(ticketCount <= MAX_TICKETS_PER_PLAYER, "Too many tickets");
        return true;
    }

    // Utility functions
    function calculateJackpot(
        uint256 ticketPrice,
        uint256 playerCount
    ) internal pure returns (uint256) {
        return ticketPrice * playerCount;
    }

    function calculateTicketIndex(
        uint256 playerCount
    ) internal pure returns (uint256) {
        return playerCount + 1;
    }

    function isGameActive(uint256 endTime) internal view returns (bool) {
        return block.timestamp < endTime;
    }

    function calculateTimeRemaining(
        uint256 endTime
    ) internal view returns (uint256) {
        if (endTime <= block.timestamp) return 0;
        return endTime - block.timestamp;
    }

    function validateGameState(
        bool isActive,
        uint256 endTime
    ) internal view returns (bool) {
        return isActive && isGameActive(endTime);
    }

    function calculatePayout(
        uint256 jackpot,
        uint256 winnerShare
    ) internal pure returns (uint256) {
        return (jackpot * winnerShare) / 100;
    }

    function calculateDeveloperFee(
        uint256 jackpot,
        uint256 feePercentage
    ) internal pure returns (uint256) {
        return (jackpot * feePercentage) / 100;
    }

    function calculateTreasuryFee(
        uint256 jackpot,
        uint256 feePercentage
    ) internal pure returns (uint256) {
        return (jackpot * feePercentage) / 100;
    }

    function validateReferrer(
        address referrer,
        address player
    ) internal pure returns (bool) {
        return referrer != address(0) && referrer != player;
    }

    function calculateReferralBonus(
        uint256 ticketPrice,
        uint256 bonusPercentage
    ) internal pure returns (uint256) {
        return (ticketPrice * bonusPercentage) / 100;
    }

    function isPlayerEligible(
        uint256 lastPurchaseTime,
        uint256 cooldownPeriod
    ) internal view returns (bool) {
        return block.timestamp >= lastPurchaseTime + cooldownPeriod;
    }

    function calculateCooldownPeriod(
        bool testMode
    ) internal pure returns (uint256) {
        return testMode ? 1 minutes : 1 hours;
    }

    function validateGameDuration(
        uint256 duration
    ) internal pure returns (bool) {
        return duration >= 1 hours && duration <= 7 days;
    }

    function calculateGameEndTime(
        uint256 startTime,
        uint256 duration
    ) internal pure returns (uint256) {
        return startTime + duration;
    }

    function isGameEnded(uint256 endTime) internal view returns (bool) {
        return block.timestamp >= endTime;
    }

    function calculateWinnerIndex(
        uint256 playerCount,
        uint256 randomSeed
    ) internal pure returns (uint256) {
        return randomSeed % playerCount;
    }

    function validateTicketPurchase(
        uint256 ticketPrice,
        uint256 playerCount,
        uint256 maxTicketsPerPlayer,
        uint256 currentPlayerTickets
    ) internal pure returns (bool) {
        require(ticketPrice > 0, "Invalid ticket price");
        require(playerCount < maxTicketsPerPlayer, "Game is full");
        require(
            currentPlayerTickets < maxTicketsPerPlayer,
            "Player ticket limit reached"
        );
        return true;
    }

    function calculateTotalValue(
        uint256 ticketPrice,
        uint256 ticketCount
    ) internal pure returns (uint256) {
        return ticketPrice * ticketCount;
    }

    function validatePayment(
        uint256 expectedValue,
        uint256 actualValue
    ) internal pure returns (bool) {
        require(actualValue == expectedValue, "Incorrect payment amount");
        return true;
    }

    function updatePlayerInfo(
        PlayerInfo storage player,
        uint256 ticketCount,
        uint256 ticketPrice
    ) internal {
        player.ticketCount = player.ticketCount + ticketCount;
        player.lastPurchaseTime = block.timestamp;
        player.totalSpent = player.totalSpent + (ticketPrice * ticketCount);
        player.isActive = true;
    }

    function resetPlayerInfo(PlayerInfo storage player) internal {
        player.ticketCount = 0;
        player.lastPurchaseTime = 0;
        player.totalSpent = 0;
        player.isActive = false;
    }

    function calculateGameStats(
        uint256 totalPlayers,
        uint256 totalJackpot,
        uint256 totalTickets
    ) internal pure returns (uint256, uint256, uint256) {
        return (totalPlayers, totalJackpot, totalTickets);
    }

    function validateEmergencyAction(
        address caller,
        address owner
    ) internal pure returns (bool) {
        require(caller == owner, "Not authorized");
        return true;
    }

    function calculateGasOptimizedValue(
        uint256 value
    ) internal pure returns (uint256) {
        // Gas optimization: use unchecked for arithmetic operations
        unchecked {
            return value + 1;
        }
    }

    function packGameData(
        uint256 gameNumber,
        uint256 ticketPrice,
        uint256 playerCount,
        uint256 jackpot
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(gameNumber, ticketPrice, playerCount, jackpot)
            );
    }

    function unpackGameData(
        bytes32 /* packedData */
    ) internal pure returns (uint256, uint256, uint256, uint256) {
        // This is a simplified version - in practice you'd need more complex unpacking
        return (0, 0, 0, 0);
    }
}
