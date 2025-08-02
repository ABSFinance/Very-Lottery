// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameFactory {
    // Events
    event GameCreated(address indexed gameAddress, string gameType, uint256 timestamp);
    event GameTemplateRegistered(string gameType, address templateAddress);
    event GameTemplateUpdated(string gameType, address oldTemplate, address newTemplate);

    // Core functions
    function createGame(string memory gameType, bytes memory initData) external returns (address);

    function registerGameTemplate(string memory gameType, address templateAddress) external;

    function getGameTemplate(string memory gameType) external view returns (address);

    function updateGameTemplate(string memory gameType, address newTemplate) external;

    // Game management
    function getAllGames() external view returns (address[] memory);

    function getGamesByType(string memory gameType) external view returns (address[] memory);

    function getGameCount() external view returns (uint256);

    function getGameCountByType(string memory gameType) external view returns (uint256);

    // Access control
    function owner() external view returns (address);
}
