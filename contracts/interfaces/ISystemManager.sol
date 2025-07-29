// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemManager {
    // Events
    event ManagerRegistered(string managerType, address managerAddress);
    event ManagerUpdated(
        string managerType,
        address oldAddress,
        address newAddress
    );
    event SystemPaused(address indexed by);
    event SystemResumed(address indexed by);

    // Core functions
    function registerManager(
        string memory managerType,
        address managerAddress
    ) external;

    function getManager(
        string memory managerType
    ) external view returns (address);

    function updateManager(
        string memory managerType,
        address newAddress
    ) external;

    function pauseSystem() external;

    function resumeSystem() external;

    function isSystemPaused() external view returns (bool);

    // Manager-specific functions
    function getEmergencyManager() external view returns (address);

    function getConfigManager() external view returns (address);

    function getGovernanceManager() external view returns (address);

    function getTreasuryManager() external view returns (address);

    // Access control
    function owner() external view returns (address);
}
