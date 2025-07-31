// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IConfigManager {
    struct GameConfig {
        uint ticketPrice;
        uint gameDuration;
        uint8 fee;
        uint maxTicketsPerPlayer;
        bool isActive;
    }

    function updateGameConfig(
        uint8 gameType,
        uint ticketPrice,
        uint gameDuration,
        uint8 fee,
        uint maxTicketsPerPlayer
    ) external;

    function setGameActive(uint8 gameType, bool isActive) external;

    function updateSystemParam(string memory param, uint value) external;

    function updateContractAddress(
        string memory contractName,
        address newAddress
    ) external;

    function getGameConfig(
        uint8 gameType
    ) external view returns (GameConfig memory);

    function getSystemParam(string memory param) external view returns (uint);

    function getContractAddress(
        string memory contractName
    ) external view returns (address);
}
