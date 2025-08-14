// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ContractRegistry
 * @author Cryptolotto Team
 * @notice Central registry for managing contract addresses
 * @dev Provides centralized contract address management and lookup functionality
 */
contract ContractRegistry is Ownable {
    // Custom Errors
    error ContractAlreadyRegistered();
    error ContractNotRegistered();
    error InvalidContractAddress();
    error InvalidContractName();
    error ArraysLengthMismatch();
    error EmptyNameArray();
    error EmptyAddressArray();

    // Contract type constants
    /**
     * @notice Treasury manager contract identifier
     */
    string public constant TREASURY_MANAGER = "TREASURY_MANAGER";
    /**
     * @notice Funds distributor contract identifier
     */
    string public constant FUNDS_DISTRIBUTOR = "FUNDS_DISTRIBUTOR";
    /**
     * @notice Cryptolotto referral contract identifier
     */
    string public constant CRYPTOLOTTO_REFERRAL = "CRYPTOLOTTO_REFERRAL";
    /**
     * @notice Stats aggregator contract identifier
     */
    string public constant STATS_AGGREGATOR = "STATS_AGGREGATOR";
    /**
     * @notice Analytics engine contract identifier
     */
    string public constant ANALYTICS_ENGINE = "ANALYTICS_ENGINE";
    /**
     * @notice Monitoring system contract identifier
     */
    string public constant MONITORING_SYSTEM = "MONITORING_SYSTEM";
    /**
     * @notice Emergency manager contract identifier
     */
    string public constant EMERGENCY_MANAGER = "EMERGENCY_MANAGER";
    /**
     * @notice Config manager contract identifier
     */
    string public constant CONFIG_MANAGER = "CONFIG_MANAGER";
    /**
     * @notice System manager contract identifier
     */
    string public constant SYSTEM_MANAGER = "SYSTEM_MANAGER";
    /**
     * @notice Event logger contract identifier
     */
    string public constant EVENT_LOGGER = "EVENT_LOGGER";
    /**
     * @notice Migrations contract identifier
     */
    string public constant MIGRATIONS = "MIGRATIONS";
    /**
     * @notice Game factory contract identifier
     */
    string public constant GAME_FACTORY = "GAME_FACTORY";

    // Storage
    /**
     * @notice Mapping of contract names to addresses
     */
    mapping(string => address) public contracts;
    /**
     * @notice Array of registered contract names
     */
    string[] public contractNames;

    // Events
    /**
     * @notice Emitted when a contract is registered
     * @param name Contract name
     * @param contractAddress Contract address
     */
    event ContractRegistered(string indexed name, address indexed contractAddress);
    /**
     * @notice Emitted when a contract is updated
     * @param name Contract name
     * @param oldAddress Previous contract address
     * @param newAddress New contract address
     */
    event ContractUpdated(string indexed name, address indexed oldAddress, address indexed newAddress);
    /**
     * @notice Emitted when a contract is removed
     * @param name Contract name
     * @param contractAddress Contract address
     */
    event ContractRemoved(string indexed name, address indexed contractAddress);
    /**
     * @notice Emitted when multiple contracts are registered
     * @param names Array of contract names
     * @param addresses Array of contract addresses
     */
    event BatchContractsRegistered(string[] indexed names, address[] indexed addresses);

    /**
     * @notice Constructor for the contract registry
     * @param owner Owner of the contract
     */
    constructor(address owner) Ownable() {}

    /**
     * @notice Register a single contract
     * @param name Contract name
     * @param contractAddress Contract address
     */
    function registerContract(string calldata name, address contractAddress) external onlyOwner {
        if (contractAddress == address(0)) revert InvalidContractAddress();
        if (bytes(name).length == 0) revert InvalidContractName();
        if (contracts[name] != address(0)) revert ContractAlreadyRegistered();

        contracts[name] = contractAddress;
        contractNames.push(name);
        emit ContractRegistered(name, contractAddress);
    }

    /**
     * @notice Register multiple contracts in batch
     * @param names Array of contract names
     * @param addresses Array of contract addresses
     */
    function registerBatchContracts(string[] calldata names, address[] calldata addresses) external onlyOwner {
        if (names.length == 0) revert EmptyNameArray();
        if (addresses.length == 0) revert EmptyAddressArray();
        if (names.length != addresses.length) revert ArraysLengthMismatch();

        for (uint256 i = 0; i < names.length; ++i) {
            // solhint-disable-line gas-increment-by-one
            if (addresses[i] == address(0)) revert InvalidContractAddress();
            if (bytes(names[i]).length == 0) revert InvalidContractName();
            if (contracts[names[i]] != address(0)) {
                revert ContractAlreadyRegistered();
            }

            contracts[names[i]] = addresses[i];
            contractNames.push(names[i]);
        }

        emit BatchContractsRegistered(names, addresses);
    }

    /**
     * @notice Update an existing contract address
     * @param name Contract name
     * @param newAddress New contract address
     */
    function updateContract(string calldata name, address newAddress) external onlyOwner {
        if (newAddress == address(0)) revert InvalidContractAddress();
        if (contracts[name] == address(0)) revert ContractNotRegistered();

        address oldAddress = contracts[name];
        contracts[name] = newAddress;
        emit ContractUpdated(name, oldAddress, newAddress);
    }

    /**
     * @notice Remove a contract from registry
     * @param name Contract name
     */
    function removeContract(string calldata name) external onlyOwner {
        if (contracts[name] == address(0)) revert ContractNotRegistered();

        address contractAddress = contracts[name];
        delete contracts[name];
        emit ContractRemoved(name, contractAddress);
    }

    /**
     * @notice Get contract address by name
     * @param name Contract name
     * @return Contract address
     */
    function getContract(string calldata name) external view returns (address) {
        if (contracts[name] == address(0)) revert ContractNotRegistered();
        return contracts[name];
    }

    /**
     * @notice Get multiple contract addresses
     * @param names Array of contract names
     * @return Array of contract addresses
     */
    function getContracts(string[] calldata names) external view returns (address[] memory) {
        address[] memory addresses = new address[](names.length);
        for (uint256 i = 0; i < names.length; ++i) {
            // solhint-disable-line gas-increment-by-one
            addresses[i] = contracts[names[i]];
        }
        return addresses;
    }

    /**
     * @notice Check if a contract is registered
     * @param name Contract name
     * @return Whether contract is registered
     */
    function isRegistered(string calldata name) external view returns (bool) {
        return contracts[name] != address(0);
    }

    /**
     * @notice Get contract name by address
     * @param contractAddress Contract address
     * @return Contract name
     */
    function getContractName(address contractAddress) external view returns (string memory) {
        for (uint256 i = 0; i < contractNames.length; ++i) {
            // solhint-disable-line gas-increment-by-one
            if (contracts[contractNames[i]] == contractAddress) {
                return contractNames[i];
            }
        }
        return "";
    }

    /**
     * @notice Get all registered contract names
     * @return Array of contract names
     */
    function getAllContractNames() external view returns (string[] memory) {
        string[] memory names = new string[](contractNames.length);
        uint256 count = 0;

        for (uint256 i = 0; i < contractNames.length; ++i) {
            // solhint-disable-line gas-increment-by-one
            if (contracts[contractNames[i]] != address(0)) {
                names[count] = contractNames[i];
                ++count; // solhint-disable-line gas-increment-by-one
            }
        }

        // Resize array to actual count
        string[] memory result = new string[](count);
        for (uint256 i = 0; i < count; ++i) {
            // solhint-disable-line gas-increment-by-one
            result[i] = names[i];
        }

        return result;
    }

    /**
     * @notice Get contract count by type
     * @return treasuryManagerCount Treasury manager contracts
     * @return fundsDistributorCount Funds distributor contracts
     * @return referralCount Referral contracts
     * @return statsAggregatorCount Stats aggregator contracts
     * @return analyticsEngineCount Analytics engine contracts
     * @return monitoringSystemCount Monitoring system contracts
     * @return emergencyManagerCount Emergency manager contracts
     * @return configManagerCount Config manager contracts
     * @return systemManagerCount System manager contracts
     * @return eventLoggerCount Event logger contracts
     * @return migrationsCount Migrations contracts
     * @return gameFactoryCount Game factory contracts
     */
    function getContractCount()
        external
        view
        returns (
            uint256 treasuryManagerCount,
            uint256 fundsDistributorCount,
            uint256 referralCount,
            uint256 statsAggregatorCount,
            uint256 analyticsEngineCount,
            uint256 monitoringSystemCount,
            uint256 emergencyManagerCount,
            uint256 configManagerCount,
            uint256 systemManagerCount,
            uint256 eventLoggerCount,
            uint256 migrationsCount,
            uint256 gameFactoryCount
        )
    {
        for (uint256 i = 0; i < contractNames.length; ++i) {
            // solhint-disable-line gas-increment-by-one
            if (contracts[contractNames[i]] != address(0)) {
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(TREASURY_MANAGER))) ++treasuryManagerCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(FUNDS_DISTRIBUTOR))) ++fundsDistributorCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(CRYPTOLOTTO_REFERRAL))) ++referralCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(STATS_AGGREGATOR))) ++statsAggregatorCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(ANALYTICS_ENGINE))) ++analyticsEngineCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(MONITORING_SYSTEM))) ++monitoringSystemCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(EMERGENCY_MANAGER))) ++emergencyManagerCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(CONFIG_MANAGER))) ++configManagerCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(SYSTEM_MANAGER))) ++systemManagerCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(EVENT_LOGGER))) ++eventLoggerCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(MIGRATIONS))) ++migrationsCount; // solhint-disable-line gas-increment-by-one
                if (keccak256(bytes(contractNames[i])) == keccak256(bytes(GAME_FACTORY))) ++gameFactoryCount; // solhint-disable-line gas-increment-by-one
            }
        }
    }
}
