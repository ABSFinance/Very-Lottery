// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../shared/libraries/LotteryUtils.sol";

contract TestLotteryUtils {
    using LotteryUtils for *;

    function testCalculateJackpot(
        uint256 ticketPrice,
        uint256 playerCount
    ) external pure returns (uint256) {
        return LotteryUtils.calculateJackpot(ticketPrice, playerCount);
    }

    function testCalculateTicketIndex(
        uint256 playerCount
    ) external pure returns (uint256) {
        return LotteryUtils.calculateTicketIndex(playerCount);
    }

    function testValidateTicketPrice(
        uint256 ticketPrice
    ) external pure returns (bool) {
        return LotteryUtils.validateTicketPrice(ticketPrice);
    }

    function testValidateTicketCount(
        uint256 ticketCount
    ) external pure returns (bool) {
        return LotteryUtils.validateTicketCount(ticketCount);
    }
}
