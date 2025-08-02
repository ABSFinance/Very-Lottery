// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAdToken {
    // Events
    event AdWatched(address indexed viewer, uint256 reward, uint256 timestamp);
    event RewardUpdated(uint256 newReward, uint256 timestamp);
    event EmergencyPaused(address indexed by, uint256 timestamp);
    event EmergencyResumed(address indexed by, uint256 timestamp);
    event MaxDailyRewardUpdated(uint256 oldMax, uint256 newMax, uint256 timestamp);

    // ERC20 functions
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // ERC20Burnable functions
    function burn(uint256 amount) external;

    // AdToken specific functions
    function watchAd(address viewer) external;

    function setAdReward(uint256 newReward) external;

    function setMaxDailyReward(uint256 newMax) external;

    function emergencyPause() external;

    function emergencyResume() external;

    // View functions
    function adReward() external view returns (uint256);

    function maxRewardPerDay() external view returns (uint256);

    function emergencyPaused() external view returns (bool);

    function lastAdWatchTime(address viewer) external view returns (uint256);

    function totalAdsWatched(address viewer) external view returns (uint256);

    function totalRewardsEarned(address viewer) external view returns (uint256);

    function dailyRewards(address viewer) external view returns (uint256);

    function lastRewardReset(address viewer) external view returns (uint256);

    function getAdStats(address viewer)
        external
        view
        returns (
            uint256 lastWatch,
            uint256 totalWatched,
            uint256 nextAvailableTime,
            uint256 totalRewards,
            uint256 dailyRewardUsed,
            uint256 dailyRewardLimit
        );

    // Access control
    function owner() external view returns (address);
}
