// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ITreasuryManager
 * @notice Interface for Treasury Manager contract
 */
interface ITreasuryManager {
    /**
     * @notice Deposit funds to specific treasury
     * @param treasuryName The treasury name
     * @param user The user address
     * @param amount The amount to deposit
     */
    function depositFunds(string memory treasuryName, address user, uint256 amount) external payable;

    /**
     * @notice Withdraw funds from treasury
     * @param treasuryName The treasury name
     * @param to The address to withdraw to
     * @param amount The amount to withdraw
     */
    function withdrawFunds(string memory treasuryName, address to, uint256 amount) external;

    /**
     * @notice Get treasury balance
     * @return The treasury balance
     */
    function getBalance() external view returns (uint256);

    function createTreasury(string memory treasuryName, uint256 initialBalance) external;

    function owner() external view returns (address);

    function addAuthorizedContract(address contractAddress) external;
}
