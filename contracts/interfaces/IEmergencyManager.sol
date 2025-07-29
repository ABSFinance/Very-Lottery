// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEmergencyManager {
    function emergencyPause() external;

    function emergencyResume() external;

    function registerContract(address contractAddress) external;

    function unregisterContract(address contractAddress) external;

    function isEmergencyPaused() external view returns (bool);

    function getAllContracts() external view returns (address[] memory);
}
