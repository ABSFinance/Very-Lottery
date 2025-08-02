// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFundsDistributor {
    function withdrawFunds() external;

    function withdrawAmount(uint256 amount) external;

    function changeOwner(address newOwner) external;

    function pause() external;

    function unpause() external;

    function getBalance() external view returns (uint256);
}
