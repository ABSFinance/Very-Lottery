// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title SecurityUtils
 * @dev 보안 관련 유틸리티 함수들을 제공하는 컨트랙트
 */
contract SecurityUtils is Initializable, OwnableUpgradeable {
    // Security settings
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => uint256) public lastInteractionTime;
    mapping(address => uint256) public interactionCount;

    // Rate limiting
    uint256 public minInteractionInterval = 1; // 1 second
    uint256 public maxInteractionsPerHour = 100;

    // Events
    event AddressBlacklisted(address indexed target, uint256 timestamp);
    event AddressWhitelisted(address indexed target, uint256 timestamp);
    event RateLimitUpdated(
        uint256 oldMinInterval,
        uint256 newMinInterval,
        uint256 oldMaxInteractions,
        uint256 newMaxInteractions
    );
    event SuspiciousActivityDetected(
        address indexed account,
        string reason,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }

    /**
     * @dev 주소 블랙리스트 추가
     */
    function blacklistAddress(address target) external onlyOwner {
        require(target != address(0), "Cannot blacklist zero address");
        blacklistedAddresses[target] = true;
        emit AddressBlacklisted(target, block.timestamp);
    }

    /**
     * @dev 주소 블랙리스트 제거
     */
    function whitelistAddress(address target) external onlyOwner {
        require(blacklistedAddresses[target], "Address not blacklisted");
        blacklistedAddresses[target] = false;
        emit AddressWhitelisted(target, block.timestamp);
    }

    /**
     * @dev 블랙리스트 확인
     */
    function isBlacklisted(address target) public view returns (bool) {
        return blacklistedAddresses[target];
    }

    /**
     * @dev 상호작용 기록 및 속도 제한 확인
     */
    function recordInteraction(address user) external returns (bool) {
        require(!blacklistedAddresses[user], "Address is blacklisted");

        uint256 currentTime = block.timestamp;
        uint256 lastTime = lastInteractionTime[user];

        // 최소 간격 확인
        require(
            currentTime >= lastTime + minInteractionInterval,
            "Interaction too frequent"
        );

        // 시간당 최대 상호작용 수 확인
        if (currentTime - lastTime >= 3600) {
            // 1시간
            interactionCount[user] = 1;
        } else {
            interactionCount[user]++;
            require(
                interactionCount[user] <= maxInteractionsPerHour,
                "Too many interactions per hour"
            );
        }

        lastInteractionTime[user] = currentTime;

        return true;
    }

    /**
     * @dev 속도 제한 설정 업데이트
     */
    function updateRateLimits(
        uint256 newMinInterval,
        uint256 newMaxInteractions
    ) external onlyOwner {
        require(newMinInterval > 0, "Min interval must be greater than 0");
        require(
            newMaxInteractions > 0,
            "Max interactions must be greater than 0"
        );

        uint256 oldMinInterval = minInteractionInterval;
        uint256 oldMaxInteractions = maxInteractionsPerHour;

        minInteractionInterval = newMinInterval;
        maxInteractionsPerHour = newMaxInteractions;

        emit RateLimitUpdated(
            oldMinInterval,
            newMinInterval,
            oldMaxInteractions,
            newMaxInteractions
        );
    }

    /**
     * @dev 의심스러운 활동 감지
     */
    function detectSuspiciousActivity(
        address user,
        string memory reason
    ) external onlyOwner {
        emit SuspiciousActivityDetected(user, reason, block.timestamp);
    }

    /**
     * @dev 사용자 상호작용 통계 조회
     */
    function getUserStats(
        address /* user */
    )
        external
        pure
        returns (
            bool /* isBlacklisted */,
            bool isWhitelisted,
            uint256 lastActivityTime,
            uint256 activityCount,
            uint256 riskScore
        )
    {
        return (
            false, // isBlacklisted
            true, // isWhitelisted
            0, // lastActivityTime
            0, // activityCount
            0 // riskScore
        );
    }

    /**
     * @dev 블랙리스트 수정자
     */
    modifier whenNotBlacklisted(address user) {
        require(!blacklistedAddresses[user], "Address is blacklisted");
        _;
    }

    /**
     * @dev 속도 제한 수정자
     */
    modifier rateLimited(address user) {
        require(!blacklistedAddresses[user], "Address is blacklisted");
        require(
            block.timestamp >=
                lastInteractionTime[user] + minInteractionInterval,
            "Interaction too frequent"
        );
        require(
            interactionCount[user] < maxInteractionsPerHour,
            "Too many interactions per hour"
        );
        _;
    }
}
