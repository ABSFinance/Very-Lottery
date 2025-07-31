// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AdToken
 * @dev 광고 로또용 AD 토큰
 * @dev 사용자가 광고를 시청하거나 특정 활동을 통해 AD 토큰을 획득할 수 있습니다.
 */
contract AdToken is ERC20, Ownable {
    /**
     * @dev 광고 시청 보상 (기본값: 1 AD)
     */
    uint256 public adReward = 1 * (10 ** 18);

    /**
     * @dev 광고 시청 기록
     */
    mapping(address => uint256) public lastAdWatchTime;
    mapping(address => uint256) public totalAdsWatched;
    mapping(address => uint256) public totalRewardsEarned;

    /**
     * @dev 보안 설정
     */
    bool public emergencyPaused;
    uint256 public maxRewardPerDay = 10 * (10 ** 18); // 10 AD per day
    mapping(address => uint256) public dailyRewards;
    mapping(address => uint256) public lastRewardReset;

    /**
     * @dev 광고 시청 이벤트
     */
    event AdWatched(address indexed viewer, uint256 reward, uint256 timestamp);
    event RewardUpdated(uint256 newReward, uint256 timestamp);
    event EmergencyPaused(address indexed by, uint256 timestamp);
    event EmergencyResumed(address indexed by, uint256 timestamp);
    event MaxDailyRewardUpdated(
        uint256 oldMax,
        uint256 newMax,
        uint256 timestamp
    );

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("AdToken", "AD") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * (10 ** 18));
    }

    /**
     * @dev 긴급 정지
     */
    function emergencyPause() external onlyOwner {
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender, block.timestamp);
    }

    /**
     * @dev 긴급 정지 해제
     */
    function emergencyResume() external onlyOwner {
        emergencyPaused = false;
        emit EmergencyResumed(msg.sender, block.timestamp);
    }

    /**
     * @dev 일일 보상 한도 업데이트
     */
    function setMaxDailyReward(uint256 newMax) external onlyOwner {
        require(newMax > 0, "Max daily reward must be greater than 0");
        uint256 oldMax = maxRewardPerDay;
        maxRewardPerDay = newMax;
        emit MaxDailyRewardUpdated(oldMax, newMax, block.timestamp);
    }

    /**
     * @dev 광고 시청 후 토큰 보상 지급
     * @param viewer 광고 시청자 주소
     */
    function watchAd(address viewer) external {
        require(!emergencyPaused, "Contract is emergency paused");
        require(viewer != address(0), "Invalid viewer address");
        require(
            balanceOf(msg.sender) >= adReward,
            "Insufficient tokens for reward"
        );

        // 최소 1시간 간격으로 광고 시청 가능
        require(
            block.timestamp >= lastAdWatchTime[viewer] + 3600,
            "Must wait 1 hour between ads"
        );

        // 일일 보상 한도 확인
        _resetDailyRewardIfNeeded(viewer);
        require(
            dailyRewards[viewer] + adReward <= maxRewardPerDay,
            "Daily reward limit exceeded"
        );

        // 토큰 전송
        _transfer(msg.sender, viewer, adReward);

        // 기록 업데이트
        lastAdWatchTime[viewer] = block.timestamp;
        totalAdsWatched[viewer] += 1;
        totalRewardsEarned[viewer] += adReward;
        dailyRewards[viewer] += adReward;

        emit AdWatched(viewer, adReward, block.timestamp);
    }

    /**
     * @dev 일일 보상 리셋 (필요시)
     */
    function _resetDailyRewardIfNeeded(address user) internal {
        if (block.timestamp >= lastRewardReset[user] + 86400) {
            // 24 hours
            dailyRewards[user] = 0;
            lastRewardReset[user] = block.timestamp;
        }
    }

    /**
     * @dev 광고 시청 보상 금액 변경 (관리자만)
     */
    function setAdReward(uint256 newReward) external onlyOwner {
        require(newReward > 0, "Reward must be greater than 0");
        adReward = newReward;
        emit RewardUpdated(newReward, block.timestamp);
    }

    /**
     * @dev 사용자의 광고 시청 정보 조회
     */
    function getAdStats(
        address viewer
    )
        public
        view
        returns (
            uint256 lastWatch,
            uint256 totalWatched,
            uint256 nextAvailableTime,
            uint256 totalRewards,
            uint256 dailyRewardUsed,
            uint256 dailyRewardLimit
        )
    {
        return (
            lastAdWatchTime[viewer],
            totalAdsWatched[viewer],
            lastAdWatchTime[viewer] + 3600,
            totalRewardsEarned[viewer],
            dailyRewards[viewer],
            maxRewardPerDay
        );
    }

    /**
     * @dev 광고 시청 가능 여부 확인
     */
    function canWatchAd(address viewer) public view returns (bool) {
        if (emergencyPaused) return false;
        if (block.timestamp < lastAdWatchTime[viewer] + 3600) return false;

        // 일일 한도 확인
        uint256 currentDailyReward = dailyRewards[viewer];
        if (block.timestamp >= lastRewardReset[viewer] + 86400) {
            currentDailyReward = 0;
        }

        return currentDailyReward + adReward <= maxRewardPerDay;
    }

    /**
     * @dev 컨트랙트 통계 조회
     */
    function getContractStats()
        external
        view
        returns (
            uint256 totalSupply,
            uint256 currentBalance,
            uint256 adReward,
            uint256 maxDailyReward,
            bool isEmergencyPaused
        )
    {
        return (
            ERC20.totalSupply(),
            address(this).balance,
            adReward,
            maxRewardPerDay,
            emergencyPaused
        );
    }
}
