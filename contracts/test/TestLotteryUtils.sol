// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../shared/libraries/LotteryUtils.sol";
import "forge-std/Test.sol";

contract TestLotteryUtils is Test {
    using LotteryUtils for *;

    // 현실적인 테스트 범위 설정 (매우 보수적으로)
    uint256 constant MAX_REALISTIC_TICKET_PRICE = 1 ether; // 1 ETH
    uint256 constant MAX_REALISTIC_PLAYER_COUNT = 1000; // 1,000명
    uint256 constant MAX_REALISTIC_TICKET_COUNT = 50; // 50장

    function testCalculateJackpot(uint256 ticketPrice, uint256 playerCount) external pure returns (uint256) {
        // Fuzz 테스트 범위를 명시적으로 제한
        ticketPrice = bound(ticketPrice, 0.001 ether, MAX_REALISTIC_TICKET_PRICE);
        playerCount = bound(playerCount, 1, MAX_REALISTIC_PLAYER_COUNT);

        return LotteryUtils.calculateJackpot(ticketPrice, playerCount);
    }

    function testCalculateTicketIndex(uint256 playerCount) external pure returns (uint256) {
        // Fuzz 테스트 범위를 명시적으로 제한
        playerCount = bound(playerCount, 1, MAX_REALISTIC_PLAYER_COUNT);

        return LotteryUtils.calculateTicketIndex(playerCount);
    }

    function testValidateTicketPrice(uint256 ticketPrice) external pure returns (bool) {
        // Fuzz 테스트 범위를 명시적으로 제한
        ticketPrice = bound(ticketPrice, 0.001 ether, MAX_REALISTIC_TICKET_PRICE);

        return LotteryUtils.validateTicketPrice(ticketPrice);
    }

    function testValidateTicketCount(uint256 ticketCount) external pure returns (bool) {
        // Fuzz 테스트 범위를 명시적으로 제한
        ticketCount = bound(ticketCount, 1, MAX_REALISTIC_TICKET_COUNT);

        return LotteryUtils.validateTicketCount(ticketCount);
    }
}
