// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICryptolottoToken {
    // Events
    event DividendsPeriodStarted(
        uint256 period,
        uint256 totalDividends,
        uint256 timestamp
    );
    event EmergencyPaused(address indexed by, uint256 timestamp);
    event EmergencyResumed(address indexed by, uint256 timestamp);

    // ERC20 functions
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    // CryptolottoToken specific functions
    function startDividendsPeriod() external;

    function reward() external view returns (uint);

    function withdrawReward() external returns (uint);

    function emergencyPause() external;

    function emergencyResume() external;

    // View functions
    function weiToDistribute() external view returns (uint256);

    function totalDividends() external view returns (uint256);

    function period() external view returns (uint256);

    function lastPeriodStarDate() external view returns (uint256);

    function emergencyPaused() external view returns (bool);

    function holders(
        address user
    )
        external
        view
        returns (
            uint balance,
            uint balanceUpdateTime,
            uint rewardWithdrawTime,
            uint totalRewardsClaimed
        );

    // Access control
    function owner() external view returns (address);
}
