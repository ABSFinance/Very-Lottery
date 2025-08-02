// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IBaseGame
 * @dev 베이스 게임 인터페이스
 */
interface IBaseGame {
    // 게임 상태 열거형
    enum GameState {
        WAITING,
        ACTIVE,
        ENDED
    }

    // 게임 구조체
    struct Game {
        uint256 gameNumber;
        uint256 startTime;
        uint256 endTime;
        uint256 jackpot;
        uint256 playerCount;
        GameState state;
        address[] players;
    }

    // 이벤트들
    event GameStarted(uint256 indexed gameNumber, uint256 timestamp);
    event GameEnded(uint256 indexed gameNumber, uint256 timestamp);
    event TicketPurchased(address indexed player, uint256 indexed gameNumber, uint256 ticketCount, uint256 totalAmount);
    event WinnerSelected(address indexed winner, uint256 indexed gameNumber, uint256 jackpot, uint256 timestamp);
    event GameStateChanged(uint256 indexed gameNumber, GameState state, uint256 timestamp);
    event TicketPriceChanged(uint256 oldPrice, uint256 newPrice, uint256 timestamp);

    // 기본 게임 함수들
    function buyTicket(address partner) external payable;

    function buyTicket(address partner, uint256 ticketCount) external payable;

    function setTicketPrice(uint256 newTicketPrice) external;

    function toggleGame() external;

    function setMaxTicketsPerPlayer(uint256 maxTickets) external;

    function setFee(uint256 newFee) external;

    function setTreasuryManager(address newTreasuryManager) external;

    function setReferralInstance(address newReferralInstance) external;

    // 뷰 함수들
    function getCurrentGamePlayers() external view returns (address[] memory);

    function getCurrentGameInfo()
        external
        view
        returns (
            uint256 gameNumber,
            uint256 startTime,
            uint256 endTime,
            uint256 jackpot,
            uint256 playerCount,
            GameState state
        );

    function isGameTimeExpired() external view returns (bool);

    function getRemainingGameTime() external view returns (uint256);

    function canStartNewGame() external view returns (bool);

    // 상태 변수들
    function isActive() external view returns (bool);

    function ticketPrice() external view returns (uint256);

    function fee() external view returns (uint256);

    function maxTicketsPerPlayer() external view returns (uint256);

    function currentGame() external view returns (Game memory);

    function nextGameStartTime() external view returns (uint256);

    function gameDuration() external view returns (uint256);

    function playerTicketCount(address player) external view returns (uint256);

    function gameHistory(uint256 gameNumber) external view returns (Game memory);

    function newPrice() external view returns (uint256);

    function toogleStatus() external view returns (bool);

    function treasuryManager() external view returns (address);

    function referralInstance() external view returns (address);
}
