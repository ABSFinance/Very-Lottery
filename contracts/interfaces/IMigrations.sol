// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMigrations {
    // Events
    event MigrationCompleted(uint256 fromVersion, uint256 toVersion);
    event MigrationStarted(uint256 fromVersion, uint256 toVersion);

    // Core functions
    function migrate(uint256 targetVersion) external;

    function setCompleted(uint256 completed) external;

    function upgrade(address newAddress) external;

    // View functions
    function lastCompletedMigration() external view returns (uint256);

    function owner() external view returns (address);
}
