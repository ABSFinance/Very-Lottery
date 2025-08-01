// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Cryptolotto Referral System
 * @dev 단순화된 리퍼럴 시스템 - 티켓 구매 시에만 리퍼럴 주소를 파라미터로 받음
 * @dev 파트너 등록 시스템 없이 즉시 리퍼럴 보상 지급
 */
contract CryptolottoReferral {
    /**
     * @dev 리퍼럴 보상 지급 이벤트
     * @param referrer 리퍼러 주소
     * @param player 플레이어 주소
     * @param amount 보상 금액
     * @param timestamp 시간
     */
    event ReferralRewardPaid(
        address indexed referrer,
        address indexed player,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev 리퍼럴 통계 업데이트 이벤트
     * @param referrer 리퍼러 주소
     * @param totalReferrals 총 리퍼럴 수
     * @param totalRewards 총 보상 금액
     * @param timestamp 시간
     */
    event ReferralStatsUpdated(
        address indexed referrer,
        uint256 totalReferrals,
        uint256 totalRewards,
        uint256 timestamp
    );

    /**
     * @dev 리퍼럴 보상 비율 (기본값: 2%)
     */
    uint256 public referralRewardPercent = 2; // 2%

    /**
     * @dev 리퍼럴 통계 구조체
     */
    struct ReferralStats {
        uint256 totalReferrals; // 총 리퍼럴 수
        uint256 totalRewards; // 총 보상 금액
        uint256 lastRewardTime; // 마지막 보상 시간
    }

    /**
     * @dev 리퍼럴 통계 매핑
     */
    mapping(address => ReferralStats) public referralStats;

    /**
     * @dev 소유자 주소
     */
    address public owner;

    /**
     * @dev 소유자 변경 이벤트
     */
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /**
     * @dev 보상 비율 변경 이벤트
     */
    event ReferralRewardPercentUpdated(
        uint256 oldPercent,
        uint256 newPercent,
        uint256 timestamp
    );

    /**
     * @dev 생성자
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev 소유자만 실행 가능한 수정자
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev 소유자 변경
     * @param newOwner 새로운 소유자 주소
     */
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnerChanged(oldOwner, newOwner);
    }

    /**
     * @dev 리퍼럴 보상 비율 변경
     * @param newPercent 새로운 보상 비율 (0-100)
     */
    function setReferralRewardPercent(uint256 newPercent) external onlyOwner {
        require(newPercent <= 20, "Reward percent cannot exceed 20%");
        uint256 oldPercent = referralRewardPercent;
        referralRewardPercent = newPercent;
        emit ReferralRewardPercentUpdated(
            oldPercent,
            newPercent,
            block.timestamp
        );
    }

    /**
     * @dev 리퍼럴 보상 처리 (티켓 구매 시 호출)
     * @param referrer 리퍼러 주소
     * @param ticketAmount 티켓 구매 금액
     * @return 보상 금액
     */
    function processReferralReward(
        address referrer,
        uint256 ticketAmount
    ) external payable returns (uint256) {
        // 리퍼러가 유효한 주소인지 확인
        require(referrer != address(0), "Invalid referrer address");
        require(referrer != msg.sender, "Cannot refer yourself");
        require(ticketAmount > 0, "Invalid ticket amount");

        // 보상 금액 계산
        uint256 rewardAmount = (ticketAmount * referralRewardPercent) / 100;

        // 보상이 0보다 큰 경우에만 처리
        if (rewardAmount > 0) {
            // 리퍼러에게 보상 지급
            (bool success, ) = payable(referrer).call{value: rewardAmount}("");
            require(success, "Referral reward transfer failed");

            // 리퍼러 통계 업데이트
            ReferralStats storage stats = referralStats[referrer];
            stats.totalReferrals++;
            stats.totalRewards += rewardAmount;
            stats.lastRewardTime = block.timestamp;

            // 이벤트 발생
            emit ReferralRewardPaid(
                referrer,
                msg.sender,
                rewardAmount,
                block.timestamp
            );
            emit ReferralStatsUpdated(
                referrer,
                stats.totalReferrals,
                stats.totalRewards,
                block.timestamp
            );
        }

        return rewardAmount;
    }

    /**
     * @dev 리퍼러 통계 조회
     * @param referrer 리퍼러 주소
     * @return totalReferrals 총 리퍼럴 수
     * @return totalRewards 총 보상 금액
     * @return lastRewardTime 마지막 보상 시간
     */
    function getReferralStats(
        address referrer
    )
        external
        view
        returns (
            uint256 totalReferrals,
            uint256 totalRewards,
            uint256 lastRewardTime
        )
    {
        ReferralStats storage stats = referralStats[referrer];
        return (stats.totalReferrals, stats.totalRewards, stats.lastRewardTime);
    }

    /**
     * @dev 리퍼럴 보상 비율 조회
     * @return 현재 리퍼럴 보상 비율
     */
    function getReferralRewardPercent() external view returns (uint256) {
        return referralRewardPercent;
    }

    /**
     * @dev 컨트랙트에 전송된 ETH 인출 (소유자만)
     */
    function withdrawContractBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev 컨트랙트 잔액 조회
     * @return 컨트랙트 잔액
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
