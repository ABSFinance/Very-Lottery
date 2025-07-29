// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Ownable contract interface.
 */
interface IOwnable {
    function getOwner() external view returns (address);

    function isAllowed(address) external view returns (bool);
}
