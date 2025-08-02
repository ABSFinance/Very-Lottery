// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AdToken
 * @author Cryptolotto Team
 * @notice Utility token for advertising rewards and lottery participation
 * @dev ERC20 utility token used for ad watching rewards and lottery ticket purchases
 */
contract AdToken is ERC20, ERC20Burnable, Ownable {
    // Custom Errors
    error MaxDailyRewardTooLow();
    error ContractEmergencyPaused();
    error InvalidViewerAddress();
    error CannotWatchForContract();
    error InsufficientTokensForReward();
    error MustWaitBetweenAds();
    error DailyRewardLimitExceeded();
    error RewardTooLow();
    error OnlyAuthorizedBurner();
    error InvalidBurnerAddress();
    error InvalidBurnAmount();
    error InsufficientBalanceForBurn();
    error TransferNotAllowed();

    // 광고 보상 관련 변수
    /**
     * @notice Amount of utility tokens given for watching an ad
     */
    uint256 public adReward = 1 * 10 ** 18; // 1 utility token
    /**
     * @notice Mapping of user addresses to their last ad watch time
     */
    mapping(address => uint256) public lastAdWatchTime;
    /**
     * @notice Mapping of user addresses to their total ads watched
     */
    mapping(address => uint256) public totalAdsWatched;
    /**
     * @notice Mapping of user addresses to their total rewards earned
     */
    mapping(address => uint256) public totalRewardsEarned;

    // 긴급 정지 관련 변수
    /**
     * @notice Whether the contract is emergency paused
     */
    bool public emergencyPaused;
    /**
     * @notice Maximum daily reward limit in utility tokens
     */
    uint256 public maxRewardPerDay = 100 * 10 ** 18; // 100 utility tokens
    /**
     * @notice Mapping of user addresses to their daily rewards
     */
    mapping(address => uint256) public dailyRewards;
    /**
     * @notice Mapping of user addresses to their last reward reset time
     */
    mapping(address => uint256) public lastRewardReset;

    // 통계 추적 변수
    /**
     * @notice Total number of transfers
     */
    uint256 public totalTransfersCount;
    /**
     * @notice Total number of burns
     */
    uint256 public totalBurnsCount;
    /**
     * @notice Total number of ads watched
     */
    uint256 public totalAdsWatchedCount;
    /**
     * @notice Total rewards earned
     */
    uint256 public totalRewardsEarnedAmount;
    /**
     * @notice Total number of holders
     */
    uint256 public totalHoldersCount;
    /**
     * @notice Mapping to track if address is a holder
     */
    mapping(address => bool) public isHolder;

    // 이벤트
    /**
     * @notice Emitted when an ad is watched
     * @param viewer The address of the viewer
     * @param reward Amount of utility tokens rewarded
     * @param timestamp Timestamp when ad was watched
     */
    event AdWatched(address indexed viewer, uint256 indexed reward, uint256 indexed timestamp);
    /**
     * @notice Emitted when reward amount is updated
     * @param newReward New reward amount in utility tokens
     * @param timestamp Timestamp when reward was updated
     */
    event RewardUpdated(uint256 indexed newReward, uint256 indexed timestamp);
    /**
     * @notice Emitted when contract is emergency paused
     * @param by Address that paused the contract
     * @param timestamp Timestamp when contract was paused
     */
    event EmergencyPaused(address indexed by, uint256 indexed timestamp);
    /**
     * @notice Emitted when contract is emergency resumed
     * @param by Address that resumed the contract
     * @param timestamp Timestamp when contract was resumed
     */
    event EmergencyResumed(address indexed by, uint256 indexed timestamp);
    /**
     * @notice Emitted when max daily reward is updated
     * @param oldMax Previous max daily reward in utility tokens
     * @param newMax New max daily reward in utility tokens
     * @param timestamp Timestamp when max daily reward was updated
     */
    event MaxDailyRewardUpdated(uint256 indexed oldMax, uint256 indexed newMax, uint256 indexed timestamp);

    /**
     * @notice Constructor for the AdToken utility token contract
     * @param initialSupply Initial utility token supply
     */
    constructor(uint256 initialSupply) ERC20("AdToken", "ADT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);

        // 초기 holder 설정
        isHolder[msg.sender] = true;
        totalHoldersCount = 1;
    }

    /**
     * @notice Emergency pause the utility token contract
     */
    function emergencyPause() external onlyOwner {
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Emergency resume the utility token contract
     */
    function emergencyResume() external onlyOwner {
        emergencyPaused = false;
        emit EmergencyResumed(msg.sender, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Set maximum daily reward in utility tokens
     * @param newMax New maximum daily reward amount in utility tokens
     */
    function setMaxDailyReward(uint256 newMax) external onlyOwner {
        if (newMax == 0) revert MaxDailyRewardTooLow();
        uint256 oldMax = maxRewardPerDay;
        maxRewardPerDay = newMax;
        emit MaxDailyRewardUpdated(oldMax, newMax, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Watch an ad and receive utility tokens
     * @param viewer Address of the viewer
     */
    function watchAd(address viewer) external {
        if (emergencyPaused) revert ContractEmergencyPaused();
        if (viewer == address(0)) revert InvalidViewerAddress();
        if (viewer == address(this)) revert CannotWatchForContract();
        if (balanceOf(msg.sender) < adReward) {
            revert InsufficientTokensForReward();
        }

        // 최소 1시간 간격으로 광고 시청 가능
        if (block.timestamp < lastAdWatchTime[viewer] + 3600 + 1) {
            revert MustWaitBetweenAds();
        } // solhint-disable-line not-rely-on-time

        // 일일 보상 한도 확인
        _resetDailyRewardIfNeeded(viewer);
        if (dailyRewards[viewer] + adReward > maxRewardPerDay) {
            revert DailyRewardLimitExceeded();
        }

        // 유틸리티 토큰 전송
        _transfer(msg.sender, viewer, adReward);

        // 기록 업데이트
        lastAdWatchTime[viewer] = block.timestamp; // solhint-disable-line not-rely-on-time
        ++totalAdsWatched[viewer]; // solhint-disable-line gas-increment-by-one
        totalRewardsEarned[viewer] += adReward;
        dailyRewards[viewer] += adReward;

        // 전체 통계 업데이트
        ++totalAdsWatchedCount; // solhint-disable-line gas-increment-by-one
        totalRewardsEarnedAmount += adReward;

        emit AdWatched(viewer, adReward, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Reset daily reward if needed
     * @param user The user address
     */
    function _resetDailyRewardIfNeeded(address user) internal {
        uint256 lastReset = lastRewardReset[user];
        uint256 currentDay = block.timestamp / 86400; // 24시간을 하루로 계산 // solhint-disable-line not-rely-on-time

        if (lastReset < currentDay) {
            dailyRewards[user] = 0;
            lastRewardReset[user] = currentDay;
        }
    }

    /**
     * @notice Set ad reward amount in utility tokens
     * @param newReward New reward amount in utility tokens
     */
    function setAdReward(uint256 newReward) external onlyOwner {
        if (newReward == 0) revert RewardTooLow();
        adReward = newReward;
        emit RewardUpdated(newReward, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Get user statistics for utility token usage
     * @param user The user address
     * @return lastWatch Last watch timestamp
     * @return totalWatched Total ads watched
     * @return totalEarned Total utility tokens earned
     * @return dailyReward Daily reward amount in utility tokens
     * @return lastReset Last reset timestamp
     * @return canWatchNow Whether user can watch now
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
        uint256 timeSinceLastWatch = block.timestamp - lastAdWatchTime[user]; // solhint-disable-line not-rely-on-time
        canWatchNow = timeSinceLastWatch > 3600 - 1;

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
     * @notice Get contract statistics
     * @return totalSupplyAmount Total token supply
     * @return totalHolders Total holders
     * @return totalTransfers Total transfers
     * @return totalBurns Total burns
     * @return adsWatchedCount Total ads watched
     * @return rewardsEarnedAmount Total rewards earned
     */
    function getContractStats()
        external
        view
        returns (
            uint256 totalSupplyAmount,
            uint256 totalHolders,
            uint256 totalTransfers,
            uint256 totalBurns,
            uint256 adsWatchedCount,
            uint256 rewardsEarnedAmount
        )
    {
        totalSupplyAmount = totalSupply();
        totalHolders = totalHoldersCount;
        totalTransfers = totalTransfersCount;
        totalBurns = totalBurnsCount;
        adsWatchedCount = totalAdsWatchedCount;
        rewardsEarnedAmount = totalRewardsEarnedAmount;
    }

    /**
     * @notice Emergency token withdrawal
     * @param to Address to withdraw to
     */
    function emergencyWithdraw(address to) external onlyOwner {
        if (emergencyPaused) revert ContractEmergencyPaused();
        if (to == address(0)) revert InvalidBurnerAddress();
        if (to == address(this)) revert TransferNotAllowed();

        uint256 balance = balanceOf(address(this));
        if (balance > 0) {
            _transfer(address(this), to, balance);
        }
    }

    /**
     * @notice Burn tokens for Ad Lottery
     * @param from Address to burn from
     * @param amount Amount to burn
     */
    function burnForLottery(address from, uint256 amount) external {
        if (msg.sender != owner() && !isAuthorizedBurner(msg.sender)) {
            revert OnlyAuthorizedBurner();
        }
        if (from == address(0)) revert InvalidBurnerAddress();
        if (from == address(this)) revert TransferNotAllowed();
        if (amount == 0) revert InvalidBurnAmount();
        if (balanceOf(from) < amount) revert InsufficientBalanceForBurn();

        _burn(from, amount);
        ++totalBurnsCount; // solhint-disable-line gas-increment-by-one

        // Holder 수 업데이트 (잔액이 0이 되면 holder에서 제거)
        if (balanceOf(from) == 0 && isHolder[from]) {
            isHolder[from] = false;
            --totalHoldersCount; // solhint-disable-line gas-increment-by-one
        }
    }

    /**
     * @notice Check if address is authorized burner
     * @param burner Address to check
     * @return bool Whether the address is authorized
     */
    function isAuthorizedBurner(address burner) public view returns (bool) {
        // 실제 구현에서는 승인된 소각자 목록을 확인
        return burner == owner();
    }

    /**
     * @notice Validate before token transfer (compatible with ERC20Burnable)
     * @param from Sender address
     * @param to Recipient address
     */
    function _beforeTokenTransfer(address from, address to, uint256 /* amount */ ) internal virtual {
        // 긴급 정지 확인
        if (emergencyPaused) revert TransferNotAllowed();
        if (from == address(0) && to == address(0)) revert TransferNotAllowed();
    }

    /**
     * @notice Override transfer to add utility token specific logic
     * @param to Recipient address
     * @param amount Amount of utility tokens to transfer
     * @return bool Success status
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if (emergencyPaused) revert TransferNotAllowed();

        // Holder 수 업데이트
        if (!isHolder[to] && amount > 0) {
            isHolder[to] = true;
            ++totalHoldersCount; // solhint-disable-line gas-increment-by-one
        }

        bool success = super.transfer(to, amount);
        if (success) {
            ++totalTransfersCount; // solhint-disable-line gas-increment-by-one
        }
        return success;
    }

    /**
     * @notice Override transferFrom to add utility token specific logic
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount of utility tokens to transfer
     * @return bool Success status
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (emergencyPaused) revert TransferNotAllowed();

        // Holder 수 업데이트
        if (!isHolder[to] && amount > 0) {
            isHolder[to] = true;
            ++totalHoldersCount; // solhint-disable-line gas-increment-by-one
        }

        bool success = super.transferFrom(from, to, amount);
        if (success) {
            ++totalTransfersCount; // solhint-disable-line gas-increment-by-one
        }
        return success;
    }

    /**
     * @notice Burn utility tokens from authorized burner
     * @param burner Address authorized to burn utility tokens
     * @param amount Amount of utility tokens to burn
     */
    function burnFromAuthorized(address burner, uint256 amount) external onlyOwner {
        if (burner == address(0)) revert InvalidBurnerAddress();
        if (amount == 0) revert InvalidBurnAmount();
        if (balanceOf(burner) < amount) revert InsufficientBalanceForBurn();

        _burn(burner, amount);
        ++totalBurnsCount; // solhint-disable-line gas-increment-by-one

        // Holder 수 업데이트 (잔액이 0이 되면 holder에서 제거)
        if (balanceOf(burner) == 0 && isHolder[burner]) {
            isHolder[burner] = false;
            --totalHoldersCount; // solhint-disable-line gas-increment-by-one
        }
    }
}
