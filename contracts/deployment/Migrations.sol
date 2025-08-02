// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title Migrations
 * @author Cryptolotto Team
 * @notice Contract for managing contract migrations and upgrades
 * @dev This contract tracks migration progress and manages upgradeable contracts
 */
contract Migrations is Ownable {
    // Custom Errors
    error NotAuthorized();
    error InvalidMigrationNumber();
    error InvalidContractAddress();
    error ContractAlreadyRegistered();

    /**
     * @notice Last completed migration number
     */
    uint256 public lastCompletedMigration;
    /**
     * @notice Mapping of migration numbers to contract addresses
     */
    mapping(uint256 => address) public migrationContracts;
    /**
     * @notice Mapping of contract addresses to migration status
     */
    mapping(address => bool) public isMigrationContract;

    /**
     * @notice Emitted when a migration is completed
     * @param migrationNumber The number of the completed migration
     * @param contractAddress The address of the migrated contract
     * @param timestamp The timestamp when the migration was completed
     */
    event MigrationCompleted(
        uint256 indexed migrationNumber, address indexed contractAddress, uint256 indexed timestamp
    );

    /**
     * @notice Emitted when a migration contract is registered
     * @param contractAddress The address of the registered contract
     * @param migrationNumber The number of the migration
     * @param timestamp The timestamp when the contract was registered
     */
    event MigrationContractRegistered(
        address indexed contractAddress, uint256 indexed migrationNumber, uint256 indexed timestamp
    );

    /**
     * @notice Constructor initializes the migration contract
     */
    constructor() Ownable(msg.sender) {
        lastCompletedMigration = 0;
    }

    /**
     * @notice Modifier to restrict access to owner only
     */
    modifier restricted() {
        if (msg.sender != owner()) {
            revert NotAuthorized();
        }
        _;
    }

    /**
     * @notice Set the completed migration number
     * @param completed The migration number to mark as completed
     */
    function setCompleted(uint256 completed) public restricted {
        if (completed < lastCompletedMigration + 1) {
            revert InvalidMigrationNumber();
        }
        lastCompletedMigration = completed;
        emit MigrationCompleted(completed, address(0), block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Upgrade to a new migration contract
     * @param newAddress The address of the new migration contract
     */
    function upgrade(address newAddress) public restricted {
        if (newAddress == address(0)) {
            revert InvalidContractAddress();
        }
        if (isMigrationContract[newAddress]) {
            revert ContractAlreadyRegistered();
        }

        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(lastCompletedMigration);

        // Register the new migration contract
        uint256 nextMigration = lastCompletedMigration + 1;
        migrationContracts[nextMigration] = newAddress;
        isMigrationContract[newAddress] = true;

        emit MigrationContractRegistered(newAddress, nextMigration, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Get migration contract by number
     * @param migrationNumber The migration number to look up
     * @return The address of the migration contract
     */
    function getMigrationContract(uint256 migrationNumber) external view returns (address) {
        return migrationContracts[migrationNumber];
    }

    /**
     * @notice Check if address is a migration contract
     * @param contractAddress The address to check
     * @return True if the address is a registered migration contract
     */
    function isMigrationContractAddress(address contractAddress) external view returns (bool) {
        return isMigrationContract[contractAddress];
    }

    /**
     * @notice Get migration statistics
     * @return lastCompleted The last completed migration number
     * @return totalMigrations The total number of migrations
     * @return hasActiveMigration Whether there is an active migration
     */
    function getMigrationStats()
        external
        view
        returns (uint256 lastCompleted, uint256 totalMigrations, bool hasActiveMigration)
    {
        return (lastCompletedMigration, lastCompletedMigration, lastCompletedMigration != 0);
    }
}
