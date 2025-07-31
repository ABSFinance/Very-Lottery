// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CryptolottoToken
 * @dev Cryptolotto 플랫폼의 기본 토큰
 *
 * 이 토큰은 다음과 같은 기능을 제공합니다:
 * - 로또 게임 보상 토큰
 * - 스테이킹 및 배당금 시스템
 * - 긴급 정지 기능
 *
 * @author Cryptolotto Team
 */
contract CryptolottoToken is ERC20, Ownable {
    /**
     * @dev Token holder struct.
     */
    struct TokenHolder {
        uint balance;
        uint balanceUpdateTime;
        uint rewardWithdrawTime;
        uint totalRewardsClaimed;
    }

    /**
     * @dev Store token holder balances updates time.
     */
    mapping(address => TokenHolder) holders;

    /**
     * @dev Amount of not distributed wei on this dividends period.
     */
    uint256 public weiToDistribute;

    /**
     * @dev Amount of wei that will be distributed on this dividends period.
     */
    uint256 public totalDividends;

    /**
     * @dev Dividends period.
     */
    uint256 public period = 2592000;

    /**
     * @dev Store last period start date in timestamp.
     */
    uint256 public lastPeriodStarDate;

    /**
     * @dev Emergency pause flag
     */
    bool public emergencyPaused;

    // Events
    event DividendsPeriodStarted(
        uint256 period,
        uint256 totalDividends,
        uint256 timestamp
    );
    event RewardClaimed(
        address indexed holder,
        uint256 amount,
        uint256 timestamp
    );
    event EmergencyPaused(address indexed by, uint256 timestamp);
    event EmergencyResumed(address indexed by, uint256 timestamp);
    event PeriodUpdated(
        uint256 oldPeriod,
        uint256 newPeriod,
        uint256 timestamp
    );

    /**
     * @dev Checks tokens balance.
     */
    modifier tokenHolder() {
        require(balanceOf(msg.sender) > 0, "Must be a token holder");
        _;
    }

    /**
     * @dev Emergency pause modifier
     */
    modifier whenNotEmergencyPaused() {
        require(!emergencyPaused, "Contract is emergency paused");
        _;
    }

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("Cryptolotto", "CRY") Ownable(msg.sender) {
        _mint(msg.sender, 100000 * (10 ** 18));
        lastPeriodStarDate = block.timestamp - period;
    }

    /**
     * @dev Starts dividends period and allow withdraw dividends.
     */
    function startDividendsPeriod() public whenNotEmergencyPaused {
        require(
            lastPeriodStarDate + period < block.timestamp,
            "Period not ended yet"
        );
        weiToDistribute += address(this).balance - weiToDistribute;
        totalDividends = weiToDistribute;
        lastPeriodStarDate += period;
        emit DividendsPeriodStarted(period, totalDividends, block.timestamp);
    }

    /**
     * @dev Transfer coins.
     *
     * @param receiver The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(
        address receiver,
        uint256 amount
    ) public override returns (bool) {
        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(receiver);

        return super.transfer(receiver, amount);
    }

    /**
     * @dev Transfer coins.
     *
     * @param from Address from which will be withdrawn tokens.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        beforeBalanceChanges(from);
        beforeBalanceChanges(to);

        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Fix last balance updates with gas optimization.
     */
    function beforeBalanceChanges(address _who) internal {
        TokenHolder storage holder = holders[_who];
        if (holder.balanceUpdateTime <= lastPeriodStarDate) {
            holder.balanceUpdateTime = block.timestamp;
            holder.balance = balanceOf(_who);
        }
    }

    /**
     * @dev Calculate token holder reward.
     */
    function reward() public view returns (uint) {
        TokenHolder storage holder = holders[msg.sender];

        if (holder.rewardWithdrawTime >= lastPeriodStarDate) {
            return 0;
        }

        uint256 balance;
        if (holder.balanceUpdateTime <= lastPeriodStarDate) {
            balance = balanceOf(msg.sender);
        } else {
            balance = holder.balance;
        }

        return (totalDividends * balance) / totalSupply();
    }

    /**
     * @dev Allow withdraw reward.
     */
    function withdrawReward() public whenNotEmergencyPaused returns (uint) {
        uint value = reward();
        if (value == 0) {
            return 0;
        }

        (bool success, ) = payable(msg.sender).call{value: value}("");
        if (!success) {
            return 0;
        }

        TokenHolder storage holder = holders[msg.sender];
        holder.totalRewardsClaimed += value;

        if (balanceOf(msg.sender) == 0) {
            // garbage collector
            delete holders[msg.sender];
        } else {
            holder.rewardWithdrawTime = block.timestamp;
        }

        weiToDistribute -= value;
        emit RewardClaimed(msg.sender, value, block.timestamp);

        return value;
    }

    /**
     * @dev Get holder info.
     */
    function getHolderInfo(
        address _who
    )
        public
        view
        returns (
            uint balance,
            uint balanceUpdateTime,
            uint rewardWithdrawTime,
            uint totalRewardsClaimed
        )
    {
        TokenHolder storage holder = holders[_who];
        return (
            holder.balance,
            holder.balanceUpdateTime,
            holder.rewardWithdrawTime,
            holder.totalRewardsClaimed
        );
    }

    /**
     * @dev Emergency pause
     */
    function emergencyPause() external onlyOwner {
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender, block.timestamp);
    }

    /**
     * @dev Emergency resume
     */
    function emergencyResume() external onlyOwner {
        emergencyPaused = false;
        emit EmergencyResumed(msg.sender, block.timestamp);
    }

    /**
     * @dev Update dividend period
     */
    function updatePeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Period must be greater than 0");
        uint256 oldPeriod = period;
        period = newPeriod;
        emit PeriodUpdated(oldPeriod, newPeriod, block.timestamp);
    }

    /**
     * @dev Get contract statistics
     */
    function getContractStats()
        external
        view
        returns (
            uint256 totalSupply,
            uint256 currentBalance,
            uint256 weiToDistribute,
            uint256 totalDividends,
            uint256 period,
            uint256 lastPeriodStartDate,
            bool isEmergencyPaused
        )
    {
        return (
            ERC20.totalSupply(),
            address(this).balance,
            weiToDistribute,
            totalDividends,
            period,
            lastPeriodStarDate,
            emergencyPaused
        );
    }

    fallback() external payable {}

    receive() external payable {}
}
