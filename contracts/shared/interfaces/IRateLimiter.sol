// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRateLimiter {
    struct RateLimit {
        uint256 maxRequests;
        uint256 timeWindow;
        uint256 currentRequests;
        uint256 windowStart;
        bool isActive;
    }

    function setUserRateLimit(address user, uint256 maxRequests, uint256 timeWindow) external;

    function setFunctionRateLimit(string memory functionName, uint256 maxRequests, uint256 timeWindow) external;

    function setUserFunctionRateLimit(address user, string memory functionName, uint256 maxRequests, uint256 timeWindow)
        external;

    function checkRateLimit(address user, string memory functionName) external returns (bool);

    function disableUserRateLimit(address user) external;

    function disableFunctionRateLimit(string memory functionName) external;

    function disableUserFunctionRateLimit(address user, string memory functionName) external;

    function toggleRateLimiting() external;

    function updateDefaultSettings(uint256 newMaxRequests, uint256 newTimeWindow) external;

    function getRateLimitInfo(address user, string memory functionName)
        external
        view
        returns (
            bool userLimitActive,
            uint256 userCurrentRequests,
            uint256 userMaxRequests,
            uint256 userTimeWindow,
            bool functionLimitActive,
            uint256 functionCurrentRequests,
            uint256 functionMaxRequests,
            uint256 functionTimeWindow,
            bool userFunctionLimitActive,
            uint256 userFunctionCurrentRequests,
            uint256 userFunctionMaxRequests,
            uint256 userFunctionTimeWindow
        );
}
