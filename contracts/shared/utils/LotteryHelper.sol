// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LotteryUtils.sol";

contract LotteryHelper {
    using LotteryUtils for *;

    // Constants
    uint256 public constant WINNER_SHARE = 80; // 80%
    uint256 public constant DEVELOPER_FEE = 10; // 10%
    uint256 public constant TREASURY_FEE = 10; // 10%
    uint256 public constant REFERRAL_BONUS = 5; // 5%

    // Events
    event HelperFunctionCalled(string functionName, address caller, uint256 timestamp);

    // Helper functions for game logic
    function calculateWinnerPayout(uint256 jackpot) external pure returns (uint256) {
        return LotteryUtils.calculatePayout(jackpot, WINNER_SHARE);
    }

    function calculateDeveloperFee(uint256 jackpot) external pure returns (uint256) {
        return LotteryUtils.calculateDeveloperFee(jackpot, DEVELOPER_FEE);
    }

    function calculateTreasuryFee(uint256 jackpot) external pure returns (uint256) {
        return LotteryUtils.calculateTreasuryFee(jackpot, TREASURY_FEE);
    }

    function calculateReferralBonus(uint256 ticketPrice) external pure returns (uint256) {
        return LotteryUtils.calculateReferralBonus(ticketPrice, REFERRAL_BONUS);
    }

    function validateGameParameters(uint256 ticketPrice, uint256 gameDuration, uint256 maxTicketsPerPlayer)
        external
        pure
        returns (bool)
    {
        require(ticketPrice >= LotteryUtils.MIN_TICKET_PRICE, "Ticket price too low");
        require(ticketPrice <= LotteryUtils.MAX_TICKET_PRICE, "Ticket price too high");
        require(LotteryUtils.validateGameDuration(gameDuration), "Invalid game duration");
        require(maxTicketsPerPlayer > 0, "Invalid max tickets");
        return true;
    }

    function calculateGameEndTime(uint256 startTime, uint256 duration) external pure returns (uint256) {
        return LotteryUtils.calculateGameEndTime(startTime, duration);
    }

    function isGameActive(uint256 endTime) external view returns (bool) {
        return LotteryUtils.isGameActive(endTime);
    }

    function calculateTimeRemaining(uint256 endTime) external view returns (uint256) {
        return LotteryUtils.calculateTimeRemaining(endTime);
    }

    function validateTicketPurchase(
        uint256 ticketPrice,
        uint256 playerCount,
        uint256 maxTicketsPerPlayer,
        uint256 currentPlayerTickets,
        uint256 ticketCount
    ) external pure returns (bool) {
        require(
            LotteryUtils.validateTicketPurchase(ticketPrice, playerCount, maxTicketsPerPlayer, currentPlayerTickets),
            "Invalid ticket purchase"
        );
        require(LotteryUtils.validateTicketCount(ticketCount), "Invalid ticket count");
        return true;
    }

    function calculateTotalValue(uint256 ticketPrice, uint256 ticketCount) external pure returns (uint256) {
        return LotteryUtils.calculateTotalValue(ticketPrice, ticketCount);
    }

    function validatePayment(uint256 expectedValue, uint256 actualValue) external pure returns (bool) {
        return LotteryUtils.validatePayment(expectedValue, actualValue);
    }

    function validateReferrer(address referrer, address player) external pure returns (bool) {
        return LotteryUtils.validateReferrer(referrer, player);
    }

    function isPlayerEligible(uint256 lastPurchaseTime, uint256 cooldownPeriod) external view returns (bool) {
        return LotteryUtils.isPlayerEligible(lastPurchaseTime, cooldownPeriod);
    }

    function calculateCooldownPeriod(bool testMode) external pure returns (uint256) {
        return LotteryUtils.calculateCooldownPeriod(testMode);
    }

    function isGameEnded(uint256 endTime) external view returns (bool) {
        return LotteryUtils.isGameEnded(endTime);
    }

    function calculateWinnerIndex(uint256 playerCount, uint256 randomSeed) external pure returns (uint256) {
        return LotteryUtils.calculateWinnerIndex(playerCount, randomSeed);
    }

    function validateGameState(bool isActive, uint256 endTime) external view returns (bool) {
        return LotteryUtils.validateGameState(isActive, endTime);
    }

    function calculateJackpot(uint256 ticketPrice, uint256 playerCount) external pure returns (uint256) {
        return LotteryUtils.calculateJackpot(ticketPrice, playerCount);
    }

    function calculateTicketIndex(uint256 playerCount) external pure returns (uint256) {
        return LotteryUtils.calculateTicketIndex(playerCount);
    }

    function packGameData(uint256 gameNumber, uint256 ticketPrice, uint256 playerCount, uint256 jackpot)
        external
        pure
        returns (bytes32)
    {
        return LotteryUtils.packGameData(gameNumber, ticketPrice, playerCount, jackpot);
    }

    function calculateGasOptimizedValue(uint256 value) external pure returns (uint256) {
        return LotteryUtils.calculateGasOptimizedValue(value);
    }

    // Batch validation functions
    function validateBatchTicketPurchase(
        uint256[] memory ticketPrices,
        uint256[] memory playerCounts,
        uint256[] memory maxTicketsPerPlayers,
        uint256[] memory currentPlayerTickets,
        uint256[] memory ticketCounts
    ) external view returns (bool[] memory) {
        bool[] memory results = new bool[](ticketPrices.length);
        for (uint256 i = 0; i < ticketPrices.length; i++) {
            try this.validateTicketPurchase(
                ticketPrices[i], playerCounts[i], maxTicketsPerPlayers[i], currentPlayerTickets[i], ticketCounts[i]
            ) {
                results[i] = true;
            } catch {
                results[i] = false;
            }
        }
        return results;
    }

    // Emergency functions
    function validateEmergencyAction(address caller, address owner) external pure returns (bool) {
        return LotteryUtils.validateEmergencyAction(caller, owner);
    }

    // Statistics functions
    function calculateGameStats(uint256 totalPlayers, uint256 totalJackpot, uint256 totalTickets)
        external
        pure
        returns (uint256, uint256, uint256)
    {
        return LotteryUtils.calculateGameStats(totalPlayers, totalJackpot, totalTickets);
    }

    // Gas optimization functions
    function batchCalculateValues(uint256[] memory values) external pure returns (uint256[] memory) {
        uint256[] memory results = new uint256[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            results[i] = LotteryUtils.calculateGasOptimizedValue(values[i]);
        }
        return results;
    }

    // Event emission helper
    function emitHelperEvent(string memory functionName) internal {
        emit HelperFunctionCalled(functionName, msg.sender, block.timestamp);
    }
}
