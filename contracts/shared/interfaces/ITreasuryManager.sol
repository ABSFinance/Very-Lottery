// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITreasuryManager {
    function createTreasury(string memory treasuryName, uint256 initialBalance) external;

    function depositFunds(string memory treasuryName, address user, uint256 amount) external;

    function withdrawFunds(string memory treasuryName, address user, uint256 amount) external;

    function getTreasuryInfo(string memory treasuryName)
        external
        view
        returns (
            uint256 totalBalance,
            uint256 reservedBalance,
            uint256 availableBalance,
            uint256 lastUpdate,
            bool isActive
        );

    function owner() external view returns (address);

    function addAuthorizedContract(address contractAddress) external;

    function removeAuthorizedContract(address contractAddress) external;

    function authorizedContracts(address contractAddress) external view returns (bool);
}
