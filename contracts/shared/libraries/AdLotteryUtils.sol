// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./LotteryUtils.sol";

library AdLotteryUtils {
    // Ad Lottery 전용 상수
    uint256 public constant AD_GAME_DURATION = 1 days;
    uint256 public constant AD_MAX_TICKETS = 100;
    uint256 public constant AD_TICKET_PRICE = 1 ether; // 1 AD Token
    uint256 public constant AD_LOTTERY_FEE = 3; // 3% (1Day/7Days에서 받는 수수료)
    uint256 public constant AD_LOTTERY_FEE_MAX = 10; // 최대 10%
    uint256 public constant AD_LOTTERY_PRIZE = 0.1 ether; // 고정 상금
    uint256 public constant MIN_BLOCK_DELAY = 1; // 최소 블록 지연
    uint256 public constant MAX_BLOCK_DELAY = 256; // 최대 블록 지연
    uint256 public constant PURCHASE_COOLDOWN = 1 minutes; // 구매 쿨다운

    // Ad Lottery 전용 이벤트
    event AdTicketPurchased(
        address indexed player, uint256 indexed gameNumber, uint256 ticketCount, uint256 adTokensUsed, uint256 timestamp
    );

    event AdLotteryWinnerSelected(
        address indexed winner, uint256 indexed gameNumber, uint256 prizeAmount, uint256 timestamp
    );

    event AdLotteryFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee, uint256 timestamp);

    event AdLotteryPerformanceMetrics(
        uint256 indexed gameNumber, uint256 gasUsed, uint256 playerCount, uint256 jackpot, uint256 timestamp
    );

    event AdLotterySecurityEvent(address indexed player, string eventType, uint256 timestamp);

    // Ad Lottery 전용 함수들
    function validateAdLotteryFee(uint256 fee) internal pure returns (bool) {
        require(fee <= AD_LOTTERY_FEE_MAX, "Fee too high");
        require(fee >= 0, "Fee cannot be negative");
        return true;
    }

    function calculateAdLotteryFee(uint256 amount, uint256 feePercentage) internal pure returns (uint256) {
        return (amount * feePercentage) / 100;
    }

    function validateAdTicketPurchase(uint256 ticketCount, uint256 playerCount, uint256 adTokenBalance)
        internal
        pure
        returns (bool)
    {
        require(ticketCount > 0, "Must buy at least 1 ticket");
        require(ticketCount <= AD_MAX_TICKETS, "Too many tickets");
        require(playerCount < AD_MAX_TICKETS, "Game is full");
        require(adTokenBalance >= (ticketCount * AD_TICKET_PRICE), "Insufficient AD tokens");
        return true;
    }

    function calculateAdTokensRequired(uint256 ticketCount) internal pure returns (uint256) {
        return ticketCount * AD_TICKET_PRICE;
    }

    function validatePurchaseCooldown(uint256 lastPurchaseTime, uint256 currentTime) internal pure returns (bool) {
        return currentTime >= lastPurchaseTime + PURCHASE_COOLDOWN;
    }

    function calculateAdLotteryPrize(uint256 jackpot) internal pure returns (uint256) {
        return jackpot > 0 ? jackpot : AD_LOTTERY_PRIZE;
    }

    function validateBlockDelay(uint256 blockDelay) internal pure returns (bool) {
        return blockDelay >= MIN_BLOCK_DELAY && blockDelay <= MAX_BLOCK_DELAY;
    }

    function calculatePerformanceMetrics(uint256 gasUsed, uint256 playerCount, uint256 jackpot)
        internal
        pure
        returns (uint256, uint256, uint256)
    {
        return (gasUsed, playerCount, jackpot);
    }

    function validateAdTokenTransfer(address from, uint256 amount) internal pure returns (bool) {
        require(from != address(0), "Invalid address");
        require(amount > 0, "Amount must be positive");
        return true;
    }

    function calculateAdLotteryStats(uint256 totalGames, uint256 totalPlayers, uint256 totalPrizes)
        internal
        pure
        returns (uint256, uint256, uint256)
    {
        return (totalGames, totalPlayers, totalPrizes);
    }

    function validateAdLotteryState(bool isActive, uint256 endTime) internal view returns (bool) {
        return isActive && LotteryUtils.isGameActive(endTime);
    }

    function calculateAdLotteryEndTime(uint256 startTime) internal pure returns (uint256) {
        return startTime + AD_GAME_DURATION;
    }

    function isAdLotteryEnded(uint256 endTime) internal view returns (bool) {
        return LotteryUtils.isGameEnded(endTime);
    }

    function calculateAdLotteryTimeRemaining(uint256 endTime) internal view returns (uint256) {
        return LotteryUtils.calculateTimeRemaining(endTime);
    }

    function validateAdLotteryWinner(address winner, uint256 playerCount) internal pure returns (bool) {
        return winner != address(0) && playerCount > 0;
    }

    function calculateAdLotteryWinnerIndex(uint256 playerCount, uint256 randomSeed) internal pure returns (uint256) {
        return LotteryUtils.calculateWinnerIndex(playerCount, randomSeed);
    }

    function packAdLotteryData(uint256 gameNumber, uint256 ticketCount, uint256 adTokensUsed, uint256 jackpot)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(gameNumber, ticketCount, adTokensUsed, jackpot));
    }

    function calculateAdLotteryGasOptimization(uint256 value) internal pure returns (uint256) {
        unchecked {
            return value + 1;
        }
    }
}
