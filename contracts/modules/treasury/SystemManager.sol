// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../shared/interfaces/IEmergencyManager.sol";
import "../../shared/interfaces/IConfigManager.sol";
import "../../shared/interfaces/ITokenRegistry.sol";
import "../../shared/interfaces/ISecurityUtils.sol";
import "../../shared/interfaces/IMonitoringSystem.sol";
import "../../shared/interfaces/IEventLogger.sol";
import "../../shared/interfaces/IAnalyticsEngine.sol";
import "../../shared/interfaces/IRateLimiter.sol";
import "../../shared/interfaces/ICircuitBreaker.sol";
import "../../shared/interfaces/ITreasuryManager.sol";
import "../../shared/interfaces/IGovernanceManager.sol";

/**
 * @title SystemManager
 * @dev 전체 시스템을 통합 관리하는 컨트랙트
 */
contract SystemManager is Initializable, OwnableUpgradeable {
    // Core system contracts
    IEmergencyManager public emergencyManager;
    IConfigManager public configManager;
    ITokenRegistry public tokenRegistry;
    ISecurityUtils public securityUtils;
    IMonitoringSystem public monitoringSystem;
    IEventLogger public eventLogger;
    IAnalyticsEngine public analyticsEngine;
    IRateLimiter public rateLimiter;
    ICircuitBreaker public circuitBreaker;
    ITreasuryManager public treasuryManager;
    IGovernanceManager public governanceManager;

    // System state
    bool public systemActive;
    uint256 public lastSystemCheck;

    // Events
    event SystemInitialized(
        address indexed emergencyManager,
        address indexed configManager,
        address indexed tokenRegistry,
        address securityUtils,
        address monitoringSystem,
        address eventLogger,
        address analyticsEngine,
        address rateLimiter,
        address circuitBreaker,
        address treasuryManager,
        address governanceManager,
        uint256 timestamp
    );
    event SystemActivated(uint256 timestamp);
    event SystemDeactivated(uint256 timestamp);
    event SystemCheckPerformed(uint256 timestamp, bool isHealthy);
    event ContractAddressUpdated(
        string contractName,
        address oldAddress,
        address newAddress
    );
    event SecurityAlertTriggered(
        address indexed user,
        string reason,
        uint256 timestamp
    );
    event AnalyticsUpdated(
        address indexed user,
        uint256 volume,
        uint256 timestamp
    );
    event RateLimitExceeded(
        address indexed user,
        string indexed functionName,
        uint256 timestamp
    );
    event CircuitBreakerTriggered(
        string indexed circuitName,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address _emergencyManager,
        address _configManager,
        address _tokenRegistry,
        address _securityUtils,
        address _monitoringSystem,
        address _eventLogger,
        address _analyticsEngine,
        address _rateLimiter,
        address _circuitBreaker,
        address _treasuryManager,
        address _governanceManager
    ) public initializer {
        __Ownable_init(owner);

        require(
            _emergencyManager != address(0),
            "Invalid emergency manager address"
        );
        require(_configManager != address(0), "Invalid config manager address");
        require(_tokenRegistry != address(0), "Invalid token registry address");
        require(_securityUtils != address(0), "Invalid security utils address");
        require(
            _monitoringSystem != address(0),
            "Invalid monitoring system address"
        );
        require(_eventLogger != address(0), "Invalid event logger address");
        require(
            _analyticsEngine != address(0),
            "Invalid analytics engine address"
        );
        require(_rateLimiter != address(0), "Invalid rate limiter address");
        require(
            _circuitBreaker != address(0),
            "Invalid circuit breaker address"
        );
        require(
            _treasuryManager != address(0),
            "Invalid treasury manager address"
        );
        require(
            _governanceManager != address(0),
            "Invalid governance manager address"
        );

        emergencyManager = IEmergencyManager(_emergencyManager);
        configManager = IConfigManager(_configManager);
        tokenRegistry = ITokenRegistry(_tokenRegistry);
        securityUtils = ISecurityUtils(_securityUtils);
        monitoringSystem = IMonitoringSystem(_monitoringSystem);
        eventLogger = IEventLogger(_eventLogger);
        analyticsEngine = IAnalyticsEngine(_analyticsEngine);
        rateLimiter = IRateLimiter(_rateLimiter);
        circuitBreaker = ICircuitBreaker(_circuitBreaker);
        treasuryManager = ITreasuryManager(_treasuryManager);
        governanceManager = IGovernanceManager(_governanceManager);

        systemActive = true;
        lastSystemCheck = block.timestamp;

        emit SystemInitialized(
            _emergencyManager,
            _configManager,
            _tokenRegistry,
            _securityUtils,
            _monitoringSystem,
            _eventLogger,
            _analyticsEngine,
            _rateLimiter,
            _circuitBreaker,
            _treasuryManager,
            _governanceManager,
            block.timestamp
        );
    }

    /**
     * @dev 시스템 활성화
     */
    function activateSystem() external onlyOwner {
        systemActive = true;
        emit SystemActivated(block.timestamp);
    }

    /**
     * @dev 시스템 비활성화
     */
    function deactivateSystem() external onlyOwner {
        systemActive = false;
        emit SystemDeactivated(block.timestamp);
    }

    /**
     * @dev 시스템 상태 확인
     */
    function performSystemCheck() external onlyOwner returns (bool) {
        bool isHealthy = true;

        // Check emergency manager
        try emergencyManager.isEmergencyPaused() returns (bool isPaused) {
            if (isPaused) {
                isHealthy = false;
            }
        } catch {
            isHealthy = false;
        }

        // Check config manager
        try configManager.getSystemParam("minTicketPrice") returns (uint) {
            // Config manager is responsive
        } catch {
            isHealthy = false;
        }

        // Check token registry
        try tokenRegistry.getActiveTokenCount() returns (uint256) {
            // Token registry is responsive
        } catch {
            isHealthy = false;
        }

        // Check monitoring system
        try monitoringSystem.performHealthCheck() returns (
            bool monitoringHealthy
        ) {
            if (!monitoringHealthy) {
                isHealthy = false;
            }
        } catch {
            isHealthy = false;
        }

        // Check analytics engine
        try analyticsEngine.getAnalyticsStats() returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256
        ) {
            // Analytics engine is responsive
        } catch {
            isHealthy = false;
        }

        // Check rate limiter
        try rateLimiter.getRateLimitInfo(address(0), "") returns (
            bool,
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256,
            uint256
        ) {
            // Rate limiter is responsive
        } catch {
            isHealthy = false;
        }

        // Check circuit breaker
        try circuitBreaker.getCircuitInfo("") returns (
            ICircuitBreaker.CircuitState,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        ) {
            // Circuit breaker is responsive
        } catch {
            isHealthy = false;
        }

        lastSystemCheck = block.timestamp;
        emit SystemCheckPerformed(block.timestamp, isHealthy);

        return isHealthy;
    }

    /**
     * @dev 긴급 정지
     */
    function emergencyPause() external onlyOwner {
        emergencyManager.emergencyPause();
    }

    /**
     * @dev 긴급 정지 해제
     */
    function emergencyResume() external onlyOwner {
        emergencyManager.emergencyResume();
    }

    /**
     * @dev 게임 설정 업데이트
     */
    function updateGameConfig(
        uint8 gameType,
        uint ticketPrice,
        uint gameDuration,
        uint8 fee,
        uint maxTicketsPerPlayer
    ) external onlyOwner {
        configManager.updateGameConfig(
            gameType,
            ticketPrice,
            gameDuration,
            fee,
            maxTicketsPerPlayer
        );
    }

    /**
     * @dev 토큰 등록
     */
    function registerToken(
        address tokenAddress,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply
    ) external onlyOwner {
        tokenRegistry.registerToken(
            tokenAddress,
            name,
            symbol,
            decimals,
            totalSupply
        );
    }

    /**
     * @dev 보안 관련 함수들
     */
    function blacklistAddress(address target) external onlyOwner {
        securityUtils.blacklistAddress(target);
    }

    function whitelistAddress(address target) external onlyOwner {
        securityUtils.whitelistAddress(target);
    }

    function updateRateLimits(
        uint256 newMinInterval,
        uint256 newMaxInteractions
    ) external onlyOwner {
        securityUtils.updateRateLimits(newMinInterval, newMaxInteractions);
    }

    /**
     * @dev 고급 보안 관련 함수들
     */
    function setUserRateLimit(
        address user,
        uint256 maxRequests,
        uint256 timeWindow
    ) external onlyOwner {
        rateLimiter.setUserRateLimit(user, maxRequests, timeWindow);
    }

    function setFunctionRateLimit(
        string memory functionName,
        uint256 maxRequests,
        uint256 timeWindow
    ) external onlyOwner {
        rateLimiter.setFunctionRateLimit(functionName, maxRequests, timeWindow);
    }

    function createCircuit(
        string memory circuitName,
        uint256 threshold,
        uint256 timeout
    ) external onlyOwner {
        circuitBreaker.createCircuit(circuitName, threshold, timeout);
    }

    function recordCircuitFailure(
        string memory circuitName
    ) external onlyOwner {
        circuitBreaker.recordFailure(circuitName);
        emit CircuitBreakerTriggered(circuitName, block.timestamp);
    }

    function recordCircuitSuccess(
        string memory circuitName
    ) external onlyOwner {
        circuitBreaker.recordSuccess(circuitName);
    }

    /**
     * @dev 모니터링 관련 함수들
     */
    function updateSystemMetrics(
        uint256 transactions,
        uint256 volume,
        uint256 users
    ) external onlyOwner {
        monitoringSystem.updateMetrics(transactions, volume, users);
    }

    function createAlert(
        string memory message,
        uint256 severity
    ) external onlyOwner {
        monitoringSystem.createAlert(message, severity);
    }

    function resolveAlert(uint256 alertId) external onlyOwner {
        monitoringSystem.resolveAlert(alertId);
    }

    /**
     * @dev 로깅 관련 함수들
     */
    function logEvent(
        string memory eventType,
        string memory message,
        address indexedAddress,
        bytes memory data
    ) external onlyOwner {
        eventLogger.logEvent(eventType, message, indexedAddress, data);
    }

    function toggleLogging() external onlyOwner {
        eventLogger.toggleLogging();
    }

    /**
     * @dev 분석 관련 함수들
     */
    function updateUserAnalytics(
        address user,
        uint256 transactions,
        uint256 volume,
        uint256 gamesPlayed,
        uint256 winnings,
        uint256 referralEarnings
    ) external onlyOwner {
        analyticsEngine.updateUserAnalytics(
            user,
            transactions,
            volume,
            gamesPlayed,
            winnings,
            referralEarnings
        );
        emit AnalyticsUpdated(user, volume, block.timestamp);
    }

    function updateGameAnalytics(
        uint8 gameType,
        uint256 totalGames,
        uint256 totalPlayers,
        uint256 totalVolume,
        uint256 averageTicketPrice,
        uint256 totalWinnings
    ) external onlyOwner {
        analyticsEngine.updateGameAnalytics(
            gameType,
            totalGames,
            totalPlayers,
            totalVolume,
            averageTicketPrice,
            totalWinnings
        );
    }

    function updateSystemAnalytics(
        uint256 totalUsers,
        uint256 totalVolume,
        uint256 totalTransactions,
        uint256 activeGames,
        uint256 totalWinnings,
        uint256 systemFees
    ) external onlyOwner {
        analyticsEngine.updateSystemAnalytics(
            totalUsers,
            totalVolume,
            totalTransactions,
            activeGames,
            totalWinnings,
            systemFees
        );
    }

    /**
     * @dev 시스템 통계 조회
     */
    function getSystemStats()
        external
        view
        returns (
            bool isSystemActive,
            bool isEmergencyPaused,
            uint256 lastCheck,
            uint256 activeTokenCount,
            uint256 totalContracts,
            bool isSecurityHealthy,
            bool isMonitoringHealthy,
            bool isAnalyticsHealthy,
            bool isRateLimiterHealthy,
            bool isCircuitBreakerHealthy
        )
    {
        bool securityHealthy = true;
        bool monitoringHealthy = true;
        bool analyticsHealthy = true;
        bool rateLimiterHealthy = true;
        bool circuitBreakerHealthy = true;

        try securityUtils.getUserStats(address(0)) returns (
            bool,
            uint256,
            uint256,
            bool
        ) {
            // Security utils is responsive
        } catch {
            securityHealthy = false;
        }

        try monitoringSystem.getSystemStats() returns (
            IMonitoringSystem.SystemMetrics memory,
            uint256,
            uint256,
            uint256
        ) {
            // Monitoring system is responsive
        } catch {
            monitoringHealthy = false;
        }

        try analyticsEngine.getAnalyticsStats() returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256
        ) {
            // Analytics engine is responsive
        } catch {
            analyticsHealthy = false;
        }

        try rateLimiter.getRateLimitInfo(address(0), "") returns (
            bool,
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256,
            uint256
        ) {
            // Rate limiter is responsive
        } catch {
            rateLimiterHealthy = false;
        }

        try circuitBreaker.getCircuitInfo("") returns (
            ICircuitBreaker.CircuitState,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        ) {
            // Circuit breaker is responsive
        } catch {
            circuitBreakerHealthy = false;
        }

        return (
            systemActive,
            emergencyManager.isEmergencyPaused(),
            lastSystemCheck,
            tokenRegistry.getActiveTokenCount(),
            emergencyManager.getAllContracts().length,
            securityHealthy,
            monitoringHealthy,
            analyticsHealthy,
            rateLimiterHealthy,
            circuitBreakerHealthy
        );
    }

    /**
     * @dev 보안 알림 트리거
     */
    function triggerSecurityAlert(
        address user,
        string memory reason
    ) external onlyOwner {
        securityUtils.detectSuspiciousActivity(user, reason);
        emit SecurityAlertTriggered(user, reason, block.timestamp);
    }

    /**
     * @dev 시스템 상태 확인 수정자
     */
    modifier whenSystemActive() {
        require(systemActive, "System is not active");
        _;
    }

    /**
     * @dev 긴급 정지 확인 수정자
     */
    modifier whenNotEmergencyPaused() {
        require(
            !emergencyManager.isEmergencyPaused(),
            "System is in emergency pause"
        );
        _;
    }

    /**
     * @dev 보안 확인 수정자
     */
    modifier whenNotBlacklisted(address user) {
        require(!securityUtils.isBlacklisted(user), "User is blacklisted");
        _;
    }

    /**
     * @dev 속도 제한 확인 수정자
     */
    modifier rateLimited(address user, string memory functionName) {
        require(
            rateLimiter.checkRateLimit(user, functionName),
            "Rate limit exceeded"
        );
        _;
    }

    /**
     * @dev 서킷 브레이커 확인 수정자
     */
    modifier circuitBreakerCheck(string memory circuitName) {
        require(
            circuitBreaker.checkCircuit(circuitName),
            "Circuit breaker is open"
        );
        _;
    }
}
