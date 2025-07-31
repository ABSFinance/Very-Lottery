// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ContractRegistry
 * @dev 중앙화된 컨트랙트 주소 관리 시스템
 */
contract ContractRegistry is Ownable {
    // Predefined contract names
    string public constant TREASURY_MANAGER = "TreasuryManager";
    string public constant EMERGENCY_MANAGER = "EmergencyManager";
    string public constant CONFIG_MANAGER = "ConfigManager";
    string public constant GOVERNANCE_MANAGER = "GovernanceManager";
    string public constant SYSTEM_MANAGER = "SystemManager";
    string public constant FUNDS_DISTRIBUTOR = "FundsDistributor";
    string public constant CRYPTOLOTTO_REFERRAL = "CryptolottoReferral";
    string public constant ANALYTICS_ENGINE = "AnalyticsEngine";
    string public constant STATS_AGGREGATOR = "StatsAggregator";
    string public constant MONITORING_SYSTEM = "MonitoringSystem";
    string public constant EVENT_LOGGER = "EventLogger";
    string public constant CRYPTOLOTTO_TOKEN = "CryptolottoToken";
    string public constant AD_TOKEN = "AdToken";
    string public constant GAME_FACTORY = "GameFactory";
    string public constant TOKEN_REGISTRY = "TokenRegistry";
    string public constant CIRCUIT_BREAKER = "CircuitBreaker";
    string public constant RATE_LIMITER = "RateLimiter";
    string public constant SECURITY_UTILS = "SecurityUtils";
    string public constant ONE_DAY_IMPLEMENTATION = "OneDayImplementation";
    string public constant SEVEN_DAYS_IMPLEMENTATION =
        "SevenDaysImplementation";

    // Contract name to address mapping
    mapping(string => address) public contracts;
    mapping(address => string) public contractNames;

    // Batch registration support
    struct ContractInfo {
        string name;
        address contractAddress;
    }

    // Events
    event ContractRegistered(
        string indexed name,
        address indexed contractAddress
    );
    event ContractUpdated(
        string indexed name,
        address indexed oldAddress,
        address indexed newAddress
    );
    event ContractRemoved(string indexed name, address indexed contractAddress);
    event BatchContractsRegistered(string[] names, address[] addresses);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Register a new contract
     */
    function registerContract(
        string memory name,
        address contractAddress
    ) external onlyOwner {
        require(contractAddress != address(0), "Invalid contract address");
        require(bytes(name).length > 0, "Invalid contract name");
        require(contracts[name] == address(0), "Contract already registered");

        contracts[name] = contractAddress;
        contractNames[contractAddress] = name;

        emit ContractRegistered(name, contractAddress);
    }

    /**
     * @dev Register multiple contracts at once
     */
    function registerBatchContracts(
        string[] memory names,
        address[] memory addresses
    ) external onlyOwner {
        require(names.length == addresses.length, "Array length mismatch");
        require(names.length > 0, "Empty arrays");

        for (uint256 i = 0; i < names.length; i++) {
            require(addresses[i] != address(0), "Invalid contract address");
            require(bytes(names[i]).length > 0, "Invalid contract name");
            require(
                contracts[names[i]] == address(0),
                "Contract already registered"
            );

            contracts[names[i]] = addresses[i];
            contractNames[addresses[i]] = names[i];
        }

        emit BatchContractsRegistered(names, addresses);
    }

    /**
     * @dev Update an existing contract address
     */
    function updateContract(
        string memory name,
        address newAddress
    ) external onlyOwner {
        require(newAddress != address(0), "Invalid contract address");
        require(contracts[name] != address(0), "Contract not registered");

        address oldAddress = contracts[name];
        contracts[name] = newAddress;
        contractNames[oldAddress] = "";
        contractNames[newAddress] = name;

        emit ContractUpdated(name, oldAddress, newAddress);
    }

    /**
     * @dev Remove a contract registration
     */
    function removeContract(string memory name) external onlyOwner {
        address contractAddress = contracts[name];
        require(contractAddress != address(0), "Contract not registered");

        delete contracts[name];
        delete contractNames[contractAddress];

        emit ContractRemoved(name, contractAddress);
    }

    /**
     * @dev Get contract address by name
     */
    function getContract(string memory name) external view returns (address) {
        address contractAddress = contracts[name];
        require(contractAddress != address(0), "Contract not found");
        return contractAddress;
    }

    /**
     * @dev Get multiple contract addresses
     */
    function getContracts(
        string[] memory names
    ) external view returns (address[] memory) {
        address[] memory addresses = new address[](names.length);
        for (uint256 i = 0; i < names.length; i++) {
            addresses[i] = contracts[names[i]];
        }
        return addresses;
    }

    /**
     * @dev Check if contract is registered
     */
    function isRegistered(string memory name) external view returns (bool) {
        return contracts[name] != address(0);
    }

    /**
     * @dev Get contract name by address
     */
    function getContractName(
        address contractAddress
    ) external view returns (string memory) {
        return contractNames[contractAddress];
    }

    /**
     * @dev Get all registered contract names
     */
    function getAllContractNames() external view returns (string[] memory) {
        // This is a simplified implementation
        // In production, you'd want to maintain a separate array of names
        string[] memory names = new string[](20);
        uint256 count = 0;

        // Check predefined names
        if (contracts[TREASURY_MANAGER] != address(0)) {
            names[count] = TREASURY_MANAGER;
            count++;
        }
        if (contracts[EMERGENCY_MANAGER] != address(0)) {
            names[count] = EMERGENCY_MANAGER;
            count++;
        }
        // Add more checks for other predefined names...

        // Resize array to actual count
        string[] memory result = new string[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = names[i];
        }

        return result;
    }

    /**
     * @dev Get contract count
     */
    function getContractCount() external view returns (uint256) {
        uint256 count = 0;
        if (contracts[TREASURY_MANAGER] != address(0)) count++;
        if (contracts[EMERGENCY_MANAGER] != address(0)) count++;
        if (contracts[CONFIG_MANAGER] != address(0)) count++;
        if (contracts[GOVERNANCE_MANAGER] != address(0)) count++;
        if (contracts[SYSTEM_MANAGER] != address(0)) count++;
        if (contracts[FUNDS_DISTRIBUTOR] != address(0)) count++;
        if (contracts[CRYPTOLOTTO_REFERRAL] != address(0)) count++;
        if (contracts[ANALYTICS_ENGINE] != address(0)) count++;
        if (contracts[STATS_AGGREGATOR] != address(0)) count++;
        if (contracts[MONITORING_SYSTEM] != address(0)) count++;
        if (contracts[EVENT_LOGGER] != address(0)) count++;
        if (contracts[CRYPTOLOTTO_TOKEN] != address(0)) count++;
        if (contracts[AD_TOKEN] != address(0)) count++;
        if (contracts[GAME_FACTORY] != address(0)) count++;
        if (contracts[TOKEN_REGISTRY] != address(0)) count++;
        if (contracts[CIRCUIT_BREAKER] != address(0)) count++;
        if (contracts[RATE_LIMITER] != address(0)) count++;
        if (contracts[SECURITY_UTILS] != address(0)) count++;
        if (contracts[ONE_DAY_IMPLEMENTATION] != address(0)) count++;
        if (contracts[SEVEN_DAYS_IMPLEMENTATION] != address(0)) count++;

        return count;
    }
}
