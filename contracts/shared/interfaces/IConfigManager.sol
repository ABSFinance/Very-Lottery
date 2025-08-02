// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IConfigManager {
    struct GameConfig {
        uint256 ticketPrice;
        uint256 gameDuration;
        uint8 fee;
        uint256 maxTicketsPerPlayer;
        bool isActive;
    }

    function updateGameConfig(
        uint8 gameType,
        uint256 ticketPrice,
        uint256 gameDuration,
        uint8 fee,
        uint256 maxTicketsPerPlayer
    ) external;

    function setGameActive(uint8 gameType, bool isActive) external;

    function updateSystemParam(string memory param, uint256 value) external;

    function updateContractAddress(string memory contractName, address newAddress) external;

    function getGameConfig(uint8 gameType) external view returns (GameConfig memory);

    function getSystemParam(string memory param) external view returns (uint256);

    function getContractAddress(string memory contractName) external view returns (address);
}
