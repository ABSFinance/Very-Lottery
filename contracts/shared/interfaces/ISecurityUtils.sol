// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISecurityUtils {
    function blacklistAddress(address target) external;

    function whitelistAddress(address target) external;

    function isBlacklisted(address target) external view returns (bool);

    function recordInteraction(address user) external returns (bool);

    function updateRateLimits(uint256 newMinInterval, uint256 newMaxInteractions) external;

    function detectSuspiciousActivity(address user, string memory reason) external;

    function getUserStats(address user)
        external
        view
        returns (bool isBlacklisted, uint256 lastInteraction, uint256 interactionCount, bool canInteract);
}
