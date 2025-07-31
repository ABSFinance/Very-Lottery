// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title StorageLayout
 * @dev 중앙화된 스토리지 레이아웃 정의
 * 모든 컨트랙트의 스토리지를 통합 관리
 */
contract StorageLayout {
    // ============ GAME STORAGE ============
    struct GameStorage {
        // 게임 상태
        mapping(uint256 => Game) games;
        mapping(address => uint256) playerTicketCount;
        address[] allPlayers;
        // 게임 설정
        uint256 ticketPrice;
        uint256 gameDuration;
        uint256 maxTicketsPerPlayer;
        bool isActive;
        // 게임 통계
        uint256 totalGames;
        uint256 totalJackpot;
        uint256 totalPlayers;
    }

    struct Game {
        uint256 gameNumber;
        uint256 startTime;
        uint256 endTime;
        uint256 jackpot;
        uint256 playerCount;
        address[] players;
        GameState state;
    }

    enum GameState {
        WAITING,
        ACTIVE,
        ENDED
    }

    // ============ TREASURY STORAGE ============
    struct TreasuryStorage {
        // 재무 데이터
        mapping(string => Treasury) treasuries;
        mapping(address => uint256) userBalances;
        mapping(string => mapping(address => uint256)) userTreasuryBalances;
        // 권한 관리
        mapping(address => bool) authorizedContracts;
        mapping(address => bool) authorizedUsers;
        // 재무 통계
        uint256 totalDeposits;
        uint256 totalWithdrawals;
        uint256 totalFees;
    }

    struct Treasury {
        uint256 totalBalance;
        uint256 reservedBalance;
        uint256 availableBalance;
        uint256 lastUpdate;
        bool isActive;
        string name;
    }

    // ============ ANALYTICS STORAGE ============
    struct AnalyticsStorage {
        // 사용자 분석
        mapping(address => UserAnalytics) userAnalytics;
        mapping(uint8 => GameAnalytics) gameAnalytics;
        // 시스템 통계
        mapping(uint256 => uint256) dailyVolume;
        mapping(uint256 => uint256) dailyTransactions;
        mapping(uint256 => uint256) dailyUsers;
        // 승자 데이터
        mapping(address => uint256) winnerCount;
        mapping(uint256 => address) gameWinners;
        mapping(address => uint256) totalWinnings;
        mapping(address => uint256) playerScores;
        address[] allPlayers;
    }

    struct UserAnalytics {
        uint256 totalGames;
        uint256 totalWins;
        uint256 totalAmount;
        uint256 lastActivity;
        uint256 averageBet;
    }

    struct GameAnalytics {
        uint256 totalGames;
        uint256 totalPlayers;
        uint256 totalJackpot;
        uint256 averagePlayers;
        uint256 averageJackpot;
    }

    // ============ REFERRAL STORAGE ============
    struct ReferralStorage {
        // 추천 시스템
        mapping(address => address) referrals;
        mapping(address => uint8) partners;
        mapping(address => bool) allowedGames;
        mapping(address => address) salesPartners;
        mapping(address => mapping(address => uint8)) salesPartner;
        // 추천 통계
        mapping(address => uint256) referralCount;
        mapping(address => uint256) referralEarnings;
        uint256 totalReferrals;
    }

    // ============ SECURITY STORAGE ============
    struct SecurityStorage {
        // 보안 설정
        mapping(address => bool) blacklistedAddresses;
        mapping(address => uint256) lastInteractionTime;
        mapping(address => uint256) interactionCount;
        // 긴급 관리
        bool isEmergencyPaused;
        mapping(address => bool) emergencyAuthorized;
        // 속도 제한
        mapping(address => RateLimit) userRateLimits;
        mapping(string => RateLimit) functionRateLimits;
    }

    struct RateLimit {
        uint256 lastReset;
        uint256 currentCount;
        uint256 maxCount;
        uint256 resetInterval;
    }

    // ============ CONFIGURATION STORAGE ============
    struct ConfigStorage {
        // 시스템 설정
        mapping(uint8 => GameConfig) gameConfigs;
        mapping(string => uint256) systemParams;
        mapping(string => address) contractAddresses;
        // 거버넌스
        mapping(uint256 => Proposal) proposals;
        mapping(address => uint256) votingPower;
        mapping(address => bool) isGovernor;
        uint256 proposalCount;
    }

    struct GameConfig {
        uint256 ticketPrice;
        uint256 gameDuration;
        uint256 maxTicketsPerPlayer;
        uint256 feePercentage;
        bool isActive;
    }

    struct Proposal {
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        address proposer;
    }

    // ============ STORAGE SLOTS ============
    // 각 스토리지 영역을 위한 고유 슬롯
    bytes32 public constant GAME_STORAGE_SLOT = keccak256("game.storage");
    bytes32 public constant TREASURY_STORAGE_SLOT =
        keccak256("treasury.storage");
    bytes32 public constant ANALYTICS_STORAGE_SLOT =
        keccak256("analytics.storage");
    bytes32 public constant REFERRAL_STORAGE_SLOT =
        keccak256("referral.storage");
    bytes32 public constant SECURITY_STORAGE_SLOT =
        keccak256("security.storage");
    bytes32 public constant CONFIG_STORAGE_SLOT = keccak256("config.storage");
}
