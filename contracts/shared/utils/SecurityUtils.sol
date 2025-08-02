// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
 * @title SecurityUtils
 * @author Cryptolotto Team
 * @notice Security utility functions contract
 * @dev Provides security-related utility functions and blacklist management
 */
contract SecurityUtils is Initializable, OwnableUpgradeable {
    // Custom Errors
    error CannotBlacklistZeroAddress();
    error AddressNotBlacklisted();
    error AddressIsBlacklisted();
    error InteractionTooFrequent();
    error TooManyInteractionsPerHour();
    error InvalidRateLimitParameters();

    // Security settings
    /** @notice Mapping of blacklisted addresses */
    mapping(address => bool) public blacklistedAddresses;
    /** @notice Mapping of last interaction times */
    mapping(address => uint256) public lastInteractionTime;
    /** @notice Mapping of interaction counts */
    mapping(address => uint256) public interactionCount;

    // Rate limiting
    /** @notice Minimum interval between interactions in seconds */
    uint256 public minInteractionInterval = 1; // 1 second
    /** @notice Maximum interactions per hour */
    uint256 public maxInteractionsPerHour = 100;

    /**
     * @notice Emitted when an address is blacklisted
     * @param target The blacklisted address
     * @param timestamp When the address was blacklisted
     */
    event AddressBlacklisted(address indexed target, uint256 timestamp);

    /**
     * @notice Emitted when an address is whitelisted
     * @param target The whitelisted address
     * @param timestamp When the address was whitelisted
     */
    event AddressWhitelisted(address indexed target, uint256 timestamp);

    /**
     * @notice Emitted when rate limits are updated
     * @param oldMinInterval Previous minimum interval
     * @param newMinInterval New minimum interval
     * @param oldMaxInteractions Previous maximum interactions
     * @param newMaxInteractions New maximum interactions
     */
    event RateLimitUpdated(
        uint256 oldMinInterval,
        uint256 newMinInterval,
        uint256 oldMaxInteractions,
        uint256 newMaxInteractions
    );

    /**
     * @notice Emitted when suspicious activity is detected
     * @param account The account with suspicious activity
     * @param reason The reason for suspicion
     * @param timestamp When the activity was detected
     */
    event SuspiciousActivityDetected(
        address indexed account,
        string reason,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the security utils contract
     * @param owner The owner of the contract
     */
    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }

    /**
     * @notice Add an address to the blacklist
     * @param target The address to blacklist
     */
    function blacklistAddress(address target) external onlyOwner {
        if (target == address(0)) {
            revert CannotBlacklistZeroAddress();
        }
        blacklistedAddresses[target] = true;
        emit AddressBlacklisted(target, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Remove an address from the blacklist
     * @param target The address to whitelist
     */
    function whitelistAddress(address target) external onlyOwner {
        if (!blacklistedAddresses[target]) {
            revert AddressNotBlacklisted();
        }
        blacklistedAddresses[target] = false;
        emit AddressWhitelisted(target, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Check if an address is blacklisted
     * @param target The address to check
     * @return True if the address is blacklisted
     */
    function isBlacklisted(address target) public view returns (bool) {
        return blacklistedAddresses[target];
    }

    /**
     * @notice Record interaction and check rate limits
     * @param user The user address
     * @return True if the interaction is allowed
     */
    function recordInteraction(address user) external returns (bool) {
        if (blacklistedAddresses[user]) {
            revert AddressIsBlacklisted();
        }

        uint256 currentTime = block.timestamp; // solhint-disable-line not-rely-on-time
        uint256 lastTime = lastInteractionTime[user];

        _checkMinimumInterval(currentTime, lastTime);
        _updateInteractionCount(user, currentTime, lastTime);
        lastInteractionTime[user] = currentTime;

        return true;
    }

    /**
     * @notice Check minimum interval between interactions
     * @param currentTime Current timestamp
     * @param lastTime Last interaction timestamp
     */
    function _checkMinimumInterval(
        uint256 currentTime,
        uint256 lastTime
    ) internal view {
        if (currentTime < lastTime + minInteractionInterval) {
            revert InteractionTooFrequent();
        }
    }

    /**
     * @notice Update interaction count for a user
     * @param user The user address
     * @param currentTime Current timestamp
     * @param lastTime Last interaction timestamp
     */
    function _updateInteractionCount(
        address user,
        uint256 currentTime,
        uint256 lastTime
    ) internal {
        if (currentTime - lastTime >= 3600) {
            // 1시간
            interactionCount[user] = 1;
        } else {
            ++interactionCount[user];
            if (interactionCount[user] > maxInteractionsPerHour) {
                revert TooManyInteractionsPerHour();
            }
        }
    }

    /**
     * @notice Update rate limit settings
     * @param newMinInterval New minimum interval in seconds
     * @param newMaxInteractions New maximum interactions per hour
     */
    function updateRateLimits(
        uint256 newMinInterval,
        uint256 newMaxInteractions
    ) external onlyOwner {
        if (newMinInterval == 0) {
            revert InvalidRateLimitParameters();
        }
        if (newMaxInteractions == 0) {
            revert InvalidRateLimitParameters();
        }

        uint256 oldMinInterval = minInteractionInterval;
        uint256 oldMaxInteractions = maxInteractionsPerHour;

        minInteractionInterval = newMinInterval;
        maxInteractionsPerHour = newMaxInteractions;

        emit RateLimitUpdated(
            oldMinInterval,
            newMinInterval,
            oldMaxInteractions,
            newMaxInteractions
        );
    }

    /**
     * @notice Detect suspicious activity
     * @param user The user address
     * @param reason The reason for suspicion
     */
    function detectSuspiciousActivity(
        address user,
        string calldata reason
    ) external {
        emit SuspiciousActivityDetected(user, reason, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Get user statistics
     * @param user The user address
     * @return userIsBlacklisted Whether the user is blacklisted
     * @return lastInteraction Last interaction timestamp
     * @return userInteractionCount Current interaction count
     * @return minInterval Minimum interval setting
     * @return maxInteractions Maximum interactions setting
     */
    function getUserStats(
        address user
    )
        external
        view
        returns (
            bool userIsBlacklisted,
            uint256 lastInteraction,
            uint256 userInteractionCount,
            uint256 minInterval,
            uint256 maxInteractions
        )
    {
        return (
            blacklistedAddresses[user],
            lastInteractionTime[user],
            interactionCount[user],
            minInteractionInterval,
            maxInteractionsPerHour
        );
    }

    /**
     * @notice Check if a user can interact
     * @param user The user address
     * @return True if the user can interact
     */
    function canInteract(address user) external view returns (bool) {
        if (blacklistedAddresses[user]) {
            return false;
        }

        uint256 currentTime = block.timestamp;
        uint256 lastTime = lastInteractionTime[user];

        if (currentTime < lastTime + minInteractionInterval) {
            return false;
        }

        if (currentTime - lastTime < 3600) {
            if (interactionCount[user] >= maxInteractionsPerHour) {
                return false;
            }
        }

        return true;
    }
}
