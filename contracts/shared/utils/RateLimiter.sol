// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title RateLimiter
 * @dev 고급 속도 제한 시스템
 */
contract RateLimiter is Initializable, OwnableUpgradeable {
    // Rate limit struct
    struct RateLimit {
        uint256 maxRequests;
        uint256 timeWindow;
        uint256 currentRequests;
        uint256 windowStart;
        bool isActive;
    }

    // Rate limit mappings
    mapping(address => RateLimit) public userRateLimits;
    mapping(string => RateLimit) public functionRateLimits;
    mapping(address => mapping(string => RateLimit))
        public userFunctionRateLimits;

    // Global settings
    bool public rateLimitingEnabled;
    uint256 public defaultMaxRequests = 100;
    uint256 public defaultTimeWindow = 3600; // 1 hour

    // Events
    event RateLimitCreated(
        address indexed user,
        string indexed functionName,
        uint256 maxRequests,
        uint256 timeWindow,
        uint256 timestamp
    );
    event RateLimitUpdated(
        address indexed user,
        string indexed functionName,
        uint256 oldMax,
        uint256 newMax,
        uint256 timestamp
    );
    event RateLimitExceeded(
        address indexed user,
        string indexed functionName,
        uint256 timestamp
    );
    event RateLimitingToggled(bool enabled, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        rateLimitingEnabled = true;
    }

    /**
     * @dev 사용자별 속도 제한 설정
     */
    function setUserRateLimit(
        address user,
        uint256 maxRequests,
        uint256 timeWindow
    ) external onlyOwner {
        require(maxRequests > 0, "Max requests must be greater than 0");
        require(timeWindow > 0, "Time window must be greater than 0");

        userRateLimits[user] = RateLimit({
            maxRequests: maxRequests,
            timeWindow: timeWindow,
            currentRequests: 0,
            windowStart: block.timestamp,
            isActive: true
        });

        emit RateLimitCreated(
            user,
            "",
            maxRequests,
            timeWindow,
            block.timestamp
        );
    }

    /**
     * @dev 함수별 속도 제한 설정
     */
    function setFunctionRateLimit(
        string memory functionName,
        uint256 maxRequests,
        uint256 timeWindow
    ) external onlyOwner {
        require(maxRequests > 0, "Max requests must be greater than 0");
        require(timeWindow > 0, "Time window must be greater than 0");

        functionRateLimits[functionName] = RateLimit({
            maxRequests: maxRequests,
            timeWindow: timeWindow,
            currentRequests: 0,
            windowStart: block.timestamp,
            isActive: true
        });

        emit RateLimitCreated(
            address(0),
            functionName,
            maxRequests,
            timeWindow,
            block.timestamp
        );
    }

    /**
     * @dev 사용자-함수별 속도 제한 설정
     */
    function setUserFunctionRateLimit(
        address user,
        string memory functionName,
        uint256 maxRequests,
        uint256 timeWindow
    ) external onlyOwner {
        require(maxRequests > 0, "Max requests must be greater than 0");
        require(timeWindow > 0, "Time window must be greater than 0");

        userFunctionRateLimits[user][functionName] = RateLimit({
            maxRequests: maxRequests,
            timeWindow: timeWindow,
            currentRequests: 0,
            windowStart: block.timestamp,
            isActive: true
        });

        emit RateLimitCreated(
            user,
            functionName,
            maxRequests,
            timeWindow,
            block.timestamp
        );
    }

    /**
     * @dev 속도 제한 확인 및 업데이트
     */
    function checkRateLimit(
        address user,
        string memory functionName
    ) external returns (bool) {
        require(rateLimitingEnabled, "Rate limiting is disabled");

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

        // Check user-function-specific rate limit
        RateLimit storage userFunctionLimit = userFunctionRateLimits[user][
            functionName
        ];
        if (userFunctionLimit.isActive) {
            allowed = allowed && _checkAndUpdateRateLimit(userFunctionLimit);
        }

        if (!allowed) {
            emit RateLimitExceeded(user, functionName, block.timestamp);
        }

        return allowed;
    }

    /**
     * @dev 내부 속도 제한 확인 및 업데이트
     */
    function _checkAndUpdateRateLimit(
        RateLimit storage limit
    ) internal returns (bool) {
        // Check if window has expired
        if (block.timestamp >= limit.windowStart + limit.timeWindow) {
            limit.currentRequests = 1;
            limit.windowStart = block.timestamp;
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
     * @dev 속도 제한 비활성화
     */
    function disableUserRateLimit(address user) external onlyOwner {
        userRateLimits[user].isActive = false;
    }

    function disableFunctionRateLimit(
        string memory functionName
    ) external onlyOwner {
        functionRateLimits[functionName].isActive = false;
    }

    function disableUserFunctionRateLimit(
        address user,
        string memory functionName
    ) external onlyOwner {
        userFunctionRateLimits[user][functionName].isActive = false;
    }

    /**
     * @dev 속도 제한 활성화/비활성화
     */
    function toggleRateLimiting() external onlyOwner {
        rateLimitingEnabled = !rateLimitingEnabled;
        emit RateLimitingToggled(rateLimitingEnabled, block.timestamp);
    }

    /**
     * @dev 기본 설정 업데이트
     */
    function updateDefaultSettings(
        uint256 newMaxRequests,
        uint256 newTimeWindow
    ) external onlyOwner {
        require(newMaxRequests > 0, "Max requests must be greater than 0");
        require(newTimeWindow > 0, "Time window must be greater than 0");

        defaultMaxRequests = newMaxRequests;
        defaultTimeWindow = newTimeWindow;
    }

    /**
     * @dev 사용자 속도 제한 정보 조회
     */
    function getUserRateLimitInfo(
        address user
    )
        external
        view
        returns (
            bool isActive,
            uint256 currentRequests,
            uint256 maxRequests,
            uint256 timeWindow
        )
    {
        RateLimit storage userLimit = userRateLimits[user];
        return (
            userLimit.isActive,
            userLimit.currentRequests,
            userLimit.maxRequests,
            userLimit.timeWindow
        );
    }

    /**
     * @dev 함수 속도 제한 정보 조회
     */
    function getFunctionRateLimitInfo(
        string memory functionName
    )
        external
        view
        returns (
            bool isActive,
            uint256 currentRequests,
            uint256 maxRequests,
            uint256 timeWindow
        )
    {
        RateLimit storage functionLimit = functionRateLimits[functionName];
        return (
            functionLimit.isActive,
            functionLimit.currentRequests,
            functionLimit.maxRequests,
            functionLimit.timeWindow
        );
    }

    /**
     * @dev 사용자 함수 속도 제한 정보 조회
     */
    function getUserFunctionRateLimitInfo(
        address user,
        string memory functionName
    )
        external
        view
        returns (
            bool isActive,
            uint256 currentRequests,
            uint256 maxRequests,
            uint256 timeWindow
        )
    {
        RateLimit storage userFunctionLimit = userFunctionRateLimits[user][
            functionName
        ];
        return (
            userFunctionLimit.isActive,
            userFunctionLimit.currentRequests,
            userFunctionLimit.maxRequests,
            userFunctionLimit.timeWindow
        );
    }
}
