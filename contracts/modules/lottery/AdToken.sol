// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AdToken
 * @dev 광고 로또용 AD 토큰
 * @dev 사용자가 광고를 시청하거나 특정 활동을 통해 AD 토큰을 획득할 수 있습니다.
 * @dev Ad Lottery 티켓 구매 시 소각되는 유틸리티 토큰입니다.
 */
contract AdToken is ERC20, ERC20Burnable, Ownable {
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
    event MaxDailyRewardUpdated(uint256 oldMax, uint256 newMax, uint256 timestamp);

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
        require(viewer != address(this), "Cannot watch ad for contract");
        require(balanceOf(msg.sender) >= adReward, "Insufficient tokens for reward");

        // 최소 1시간 간격으로 광고 시청 가능
        require(block.timestamp >= lastAdWatchTime[viewer] + 3600, "Must wait 1 hour between ads");

        // 일일 보상 한도 확인
        _resetDailyRewardIfNeeded(viewer);
        require(dailyRewards[viewer] + adReward <= maxRewardPerDay, "Daily reward limit exceeded");

        // 토큰 전송
        _transfer(msg.sender, viewer, adReward);

        // 기록 업데이트
        lastAdWatchTime[viewer] = block.timestamp;
        totalAdsWatched[viewer]++;
        totalRewardsEarned[viewer] += adReward;
        dailyRewards[viewer] += adReward;

        emit AdWatched(viewer, adReward, block.timestamp);
    }

    /**
     * @dev 일일 보상 리셋 확인
     */
    function _resetDailyRewardIfNeeded(address user) internal {
        uint256 lastReset = lastRewardReset[user];
        uint256 currentDay = block.timestamp / 86400; // 24시간을 하루로 계산

        if (lastReset < currentDay) {
            dailyRewards[user] = 0;
            lastRewardReset[user] = currentDay;
        }
    }

    /**
     * @dev 광고 보상 금액 업데이트
     */
    function setAdReward(uint256 newReward) external onlyOwner {
        require(newReward > 0, "Reward must be greater than 0");
        adReward = newReward;
        emit RewardUpdated(newReward, block.timestamp);
    }

    /**
     * @dev 사용자 통계 조회
     */
    function getUserStats(address user)
        external
        view
        returns (
            uint256 lastWatch,
            uint256 totalWatched,
            uint256 totalEarned,
            uint256 dailyReward,
            uint256 lastReset,
            bool canWatchNow
        )
    {
        uint256 timeSinceLastWatch = block.timestamp - lastAdWatchTime[user];
        canWatchNow = timeSinceLastWatch >= 3600;

        return (
            lastAdWatchTime[user],
            totalAdsWatched[user],
            totalRewardsEarned[user],
            dailyRewards[user],
            lastRewardReset[user],
            canWatchNow
        );
    }

    /**
     * @dev 컨트랙트 통계 조회
     */
    function getContractStats()
        external
        view
        returns (
            uint256 totalSupplyAmount,
            uint256 adRewardAmount,
            uint256 maxDailyReward,
            bool isEmergencyPaused,
            uint256 totalHolders
        )
    {
        return (
            ERC20.totalSupply(),
            adReward,
            maxRewardPerDay,
            emergencyPaused,
            0 // 실제 구현에서는 holder 수를 계산해야 함
        );
    }

    /**
     * @dev 긴급 상황에서 토큰 인출
     */
    function emergencyWithdraw(address to) external onlyOwner {
        require(emergencyPaused, "Contract must be paused for emergency withdrawal");
        require(to != address(0), "Invalid recipient address");
        require(to != address(this), "Cannot withdraw to self");

        uint256 balance = balanceOf(address(this));
        if (balance > 0) {
            _transfer(address(this), to, balance);
        }
    }

    /**
     * @dev 토큰 소각 (Ad Lottery용)
     */
    function burnForLottery(address from, uint256 amount) external {
        require(msg.sender == owner() || isAuthorizedBurner(msg.sender), "Not authorized to burn");
        require(from != address(0), "Invalid from address");
        require(from != address(this), "Cannot burn from self");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(from) >= amount, "Insufficient balance to burn");

        _burn(from, amount);
    }

    /**
     * @dev 소각 권한 확인
     */
    function isAuthorizedBurner(address burner) public view returns (bool) {
        // 실제 구현에서는 승인된 소각자 목록을 확인
        return burner == owner();
    }

    /**
     * @dev 토큰 전송 전 검증 (ERC20Burnable과 호환)
     */
    function _beforeTokenTransfer(address from, address to, uint256 /* amount */ ) internal virtual {
        // 긴급 정지 확인
        require(!emergencyPaused, "Token transfers paused");
        require(from != address(0) || to != address(0), "Invalid transfer");
    }
}
