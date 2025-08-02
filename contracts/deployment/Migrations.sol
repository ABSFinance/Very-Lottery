// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Migrations is Ownable {
    uint256 public last_completed_migration;
    mapping(uint256 => address) public migrationContracts;
    mapping(address => bool) public isMigrationContract;

    // Events
    event MigrationCompleted(uint256 indexed migrationNumber, address indexed contractAddress, uint256 timestamp);
    event MigrationContractRegistered(
        address indexed contractAddress, uint256 indexed migrationNumber, uint256 timestamp
    );

    constructor() Ownable(msg.sender) {
        last_completed_migration = 0;
    }

    modifier restricted() {
        require(msg.sender == owner(), "Not authorized");
        _;
    }

    function setCompleted(uint256 completed) public restricted {
        require(completed > last_completed_migration, "Migration number must be greater than last completed");
        last_completed_migration = completed;
        emit MigrationCompleted(completed, address(0), block.timestamp);
    }

    function upgrade(address new_address) public restricted {
        require(new_address != address(0), "Invalid contract address");
        require(!isMigrationContract[new_address], "Contract already registered as migration");

        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);

        // Register the new migration contract
        uint256 nextMigration = last_completed_migration + 1;
        migrationContracts[nextMigration] = new_address;
        isMigrationContract[new_address] = true;

        emit MigrationContractRegistered(new_address, nextMigration, block.timestamp);
    }

    /**
     * @dev Get migration contract by number
     */
    function getMigrationContract(uint256 migrationNumber) external view returns (address) {
        return migrationContracts[migrationNumber];
    }

    /**
     * @dev Check if address is a migration contract
     */
    function isMigrationContractAddress(address contractAddress) external view returns (bool) {
        return isMigrationContract[contractAddress];
    }

    /**
     * @dev Get migration statistics
     */
    function getMigrationStats()
        external
        view
        returns (uint256 lastCompleted, uint256 totalMigrations, bool hasActiveMigration)
    {
        return (last_completed_migration, last_completed_migration, last_completed_migration > 0);
    }
}
