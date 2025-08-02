// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
 * @title RateLimiter
 * @author Cryptolotto Team
 * @notice Advanced rate limiting system
 * @dev Provides rate limiting functionality for users and functions
 */
contract RateLimiter is Initializable, OwnableUpgradeable {
    // Custom Errors
    error InvalidMaxRequests();
    error InvalidTimeWindow();
    error RateLimitExceeded();

    /**
     * @notice Rate limit structure
     * @param maxRequests Maximum number of requests allowed
     * @param timeWindow Time window for the rate limit
     * @param currentRequests Current number of requests in the window
     * @param windowStart Start time of the current window
     * @param isActive Whether the rate limit is active
     */
    struct RateLimit {
        uint256 maxRequests;
        uint256 timeWindow;
        uint256 currentRequests;
        uint256 windowStart;
        bool isActive;
    }

    // Rate limit mappings
    /**
     * @notice User-specific rate limits
     */
    mapping(address => RateLimit) public userRateLimits;
    /**
     * @notice Function-specific rate limits
     */
    mapping(string => RateLimit) public functionRateLimits;
    /**
     * @notice User-function specific rate limits
     */
    mapping(address => mapping(string => RateLimit)) public userFunctionRateLimits;

    // Global settings
    /**
     * @notice Whether rate limiting is enabled globally
     */
    bool public rateLimitingEnabled;
    /**
     * @notice Default maximum requests
     */
    uint256 public defaultMaxRequests = 100;
    /**
     * @notice Default time window in seconds
     */
    uint256 public defaultTimeWindow = 3600; // 1 hour

    /**
     * @notice Emitted when a rate limit is created
     * @param user The user address
     * @param functionName The function name
     * @param maxRequests Maximum requests allowed
     * @param timeWindow Time window for the limit
     * @param timestamp When the limit was created
     */
    event RateLimitCreated(
        address indexed user, string indexed functionName, uint256 maxRequests, uint256 timeWindow, uint256 timestamp
    );

    /**
     * @notice Emitted when a rate limit is updated
     * @param user The user address
     * @param functionName The function name
     * @param oldMax Previous maximum requests
     * @param newMax New maximum requests
     * @param timestamp When the limit was updated
     */
    event RateLimitUpdated(
        address indexed user, string indexed functionName, uint256 oldMax, uint256 newMax, uint256 timestamp
    );

    /**
     * @notice Emitted when a rate limit is exceeded
     * @param user The user address
     * @param functionName The function name
     * @param timestamp When the limit was exceeded
     */
    event RateLimitExceededEvent(address indexed user, string indexed functionName, uint256 timestamp);

    /**
     * @notice Emitted when rate limiting is toggled
     * @param enabled Whether rate limiting is enabled
     * @param timestamp When the setting was changed
     */
    event RateLimitingToggled(bool enabled, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the rate limiter contract
     * @param owner The owner of the contract
     */
    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        rateLimitingEnabled = true;
    }

    /**
     * @notice Set user-specific rate limit
     * @param user The user address
     * @param maxRequests Maximum requests allowed
     * @param timeWindow Time window in seconds
     */
    function setUserRateLimit(address user, uint256 maxRequests, uint256 timeWindow) external onlyOwner {
        _validateRateLimitParams(maxRequests, timeWindow);
        _createUserRateLimit(user, maxRequests, timeWindow);
        _emitRateLimitCreated(user, "", maxRequests, timeWindow);
    }

    /**
     * @notice Validate rate limit parameters
     * @param maxRequests Maximum requests to validate
     * @param timeWindow Time window to validate
     */
    function _validateRateLimitParams(uint256 maxRequests, uint256 timeWindow) internal pure {
        if (maxRequests == 0) {
            revert InvalidMaxRequests();
        }
        if (timeWindow == 0) {
            revert InvalidTimeWindow();
        }
    }

    /**
     * @notice Create user rate limit
     * @param user The user address
     * @param maxRequests Maximum requests allowed
     * @param timeWindow Time window in seconds
     */
    function _createUserRateLimit(address user, uint256 maxRequests, uint256 timeWindow) internal {
        userRateLimits[user] = RateLimit({
            maxRequests: maxRequests,
            timeWindow: timeWindow,
            currentRequests: 0,
            windowStart: block.timestamp, // solhint-disable-line not-rely-on-time
            isActive: true
        });
    }

    /**
     * @notice Emit rate limit created event
     * @param user The user address
     * @param functionName The function name
     * @param maxRequests Maximum requests allowed
     * @param timeWindow Time window in seconds
     */
    function _emitRateLimitCreated(address user, string memory functionName, uint256 maxRequests, uint256 timeWindow)
        internal
    {
        emit RateLimitCreated(user, functionName, maxRequests, timeWindow, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Set function-specific rate limit
     * @param functionName The function name
     * @param maxRequests Maximum requests allowed
     * @param timeWindow Time window in seconds
     */
    function setFunctionRateLimit(string calldata functionName, uint256 maxRequests, uint256 timeWindow)
        external
        onlyOwner
    {
        if (maxRequests == 0) {
            revert InvalidMaxRequests();
        }
        if (timeWindow == 0) {
            revert InvalidTimeWindow();
        }

        functionRateLimits[functionName] = RateLimit({
            maxRequests: maxRequests,
            timeWindow: timeWindow,
            currentRequests: 0,
            windowStart: block.timestamp,
            isActive: true
        });

        _emitRateLimitCreated(address(0), functionName, maxRequests, timeWindow);
    }

    /**
     * @notice Set user-function specific rate limit
     * @param user The user address
     * @param functionName The function name
     * @param maxRequests Maximum requests allowed
     * @param timeWindow Time window in seconds
     */
    function setUserFunctionRateLimit(
        address user,
        string calldata functionName,
        uint256 maxRequests,
        uint256 timeWindow
    ) external onlyOwner {
        if (maxRequests == 0) {
            revert InvalidMaxRequests();
        }
        if (timeWindow == 0) {
            revert InvalidTimeWindow();
        }

        userFunctionRateLimits[user][functionName] = RateLimit({
            maxRequests: maxRequests,
            timeWindow: timeWindow,
            currentRequests: 0,
            windowStart: block.timestamp,
            isActive: true
        });

        _emitRateLimitCreated(user, functionName, maxRequests, timeWindow);
    }

    /**
     * @notice Check and update rate limit
     * @param user The user address
     * @param functionName The function name
     * @return bool True if the request is allowed, false otherwise
     */
    function checkRateLimit(address user, string calldata functionName) external returns (bool) {
        if (!rateLimitingEnabled) {
            return true; // Allow if rate limiting is disabled
        }

        bool allowed = true;

        // Check user-specific rate limit
        RateLimit storage userLimit = userRateLimits[user];
        if (userLimit.isActive) {
            allowed = allowed && _checkAndUpdateRateLimit(userLimit);
        }

        // Check function-specific rate limit
        RateLimit storage functionLimit = functionRateLimits[functionName];
        if (functionLimit.isActive) {
            allowed = allowed && _checkAndUpdateRateLimit(functionLimit);
        }

        // Check user-function specific rate limit
        RateLimit storage userFunctionLimit = userFunctionRateLimits[user][functionName];
        if (userFunctionLimit.isActive) {
            allowed = allowed && _checkAndUpdateRateLimit(userFunctionLimit);
        }

        if (!allowed) {
            emit RateLimitExceededEvent(user, functionName, block.timestamp); // solhint-disable-line not-rely-on-time
            revert RateLimitExceeded();
        }

        return allowed;
    }

    /**
     * @notice Internal function to check and update rate limit
     * @param limit The rate limit to check and update
     * @return bool True if the request is allowed, false otherwise
     */
    function _checkAndUpdateRateLimit(RateLimit storage limit) internal returns (bool) {
        // Check if window has expired
        if (block.timestamp >= limit.windowStart + limit.timeWindow) {
            // solhint-disable-line not-rely-on-time
            limit.currentRequests = 1;
            limit.windowStart = block.timestamp; // solhint-disable-line not-rely-on-time
            return true;
        }

        // Check if limit exceeded
        if (limit.currentRequests >= limit.maxRequests) {
            return false;
        }

        // Increment request count
        limit.currentRequests++;
        return true;
    }

    /**
     * @notice Disable user-specific rate limit
     * @param user The user address
     */
    function disableUserRateLimit(address user) external onlyOwner {
        userRateLimits[user].isActive = false;
    }

    /**
     * @notice Disable function-specific rate limit
     * @param functionName The function name
     */
    function disableFunctionRateLimit(string calldata functionName) external onlyOwner {
        functionRateLimits[functionName].isActive = false;
    }

    /**
     * @notice Disable user-function specific rate limit
     * @param user The user address
     * @param functionName The function name
     */
    function disableUserFunctionRateLimit(address user, string calldata functionName) external onlyOwner {
        userFunctionRateLimits[user][functionName].isActive = false;
    }

    /**
     * @notice Toggle rate limiting on/off
     */
    function toggleRateLimiting() external onlyOwner {
        rateLimitingEnabled = !rateLimitingEnabled;
        emit RateLimitingToggled(rateLimitingEnabled, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Update default settings
     * @param newMaxRequests New default maximum requests
     * @param newTimeWindow New default time window in seconds
     */
    function updateDefaultSettings(uint256 newMaxRequests, uint256 newTimeWindow) external onlyOwner {
        if (newMaxRequests == 0) {
            revert InvalidMaxRequests();
        }
        if (newTimeWindow == 0) {
            revert InvalidTimeWindow();
        }

        defaultMaxRequests = newMaxRequests;
        defaultTimeWindow = newTimeWindow;
    }

    /**
     * @notice Get user rate limit information
     * @param user The user address
     * @return isActive Whether the rate limit is active
     * @return currentRequests Current number of requests in the window
     * @return maxRequests Maximum requests allowed
     * @return timeWindow Time window in seconds
     */
    function getUserRateLimitInfo(address user)
        external
        view
        returns (bool isActive, uint256 currentRequests, uint256 maxRequests, uint256 timeWindow)
    {
        RateLimit storage userLimit = userRateLimits[user];
        return (userLimit.isActive, userLimit.currentRequests, userLimit.maxRequests, userLimit.timeWindow);
    }

    /**
     * @notice Get function rate limit information
     * @param functionName The function name
     * @return isActive Whether the rate limit is active
     * @return currentRequests Current number of requests in the window
     * @return maxRequests Maximum requests allowed
     * @return timeWindow Time window in seconds
     */
    function getFunctionRateLimitInfo(string calldata functionName)
        external
        view
        returns (bool isActive, uint256 currentRequests, uint256 maxRequests, uint256 timeWindow)
    {
        RateLimit storage functionLimit = functionRateLimits[functionName];
        return
            (functionLimit.isActive, functionLimit.currentRequests, functionLimit.maxRequests, functionLimit.timeWindow);
    }

    /**
     * @notice Get user-function specific rate limit information
     * @param user The user address
     * @param functionName The function name
     * @return isActive Whether the rate limit is active
     * @return currentRequests Current number of requests in the window
     * @return maxRequests Maximum requests allowed
     * @return timeWindow Time window in seconds
     */
    function getUserFunctionRateLimitInfo(address user, string calldata functionName)
        external
        view
        returns (bool isActive, uint256 currentRequests, uint256 maxRequests, uint256 timeWindow)
    {
        RateLimit storage userFunctionLimit = userFunctionRateLimits[user][functionName];
        return (
            userFunctionLimit.isActive,
            userFunctionLimit.currentRequests,
            userFunctionLimit.maxRequests,
            userFunctionLimit.timeWindow
        );
    }
}
