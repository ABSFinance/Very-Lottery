// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TreasuryManager
 * @dev 중앙화된 자금 관리 시스템
 *
 * 이 컨트랙트는 다음과 같은 기능을 제공합니다:
 * - 여러 Treasury의 중앙화된 관리
 * - 사용자별 자금 추적 및 관리
 * - 최소 보유량 비율 설정
 * - 인출 한도 설정
 * - 권한 기반 접근 제어
 *
 * 보안 기능:
 * - ReentrancyGuard로 재진입 공격 방지
 * - 입력 검증 및 접근 제어
 * - Gas 최적화된 구조
 *
 * @author Cryptolotto Team
 */
contract TreasuryManager is Ownable, ReentrancyGuard {
    // Treasury struct
    struct Treasury {
        uint256 totalBalance;
        uint256 reservedBalance;
        uint256 availableBalance;
        uint256 lastUpdate;
        bool isActive;
    }

    // Treasury mappings
    mapping(string => Treasury) public treasuries;
    mapping(address => uint256) public userBalances;
    mapping(string => mapping(address => uint256)) public userTreasuryBalances;

    // Authorized contracts that can call deposit/withdraw functions
    mapping(address => bool) public authorizedContracts;

    // Global settings
    bool public treasuryEnabled = true;
    uint256 public maxWithdrawalAmount = 10000 ether;
    uint256 public minReserveRatio = 10; // 10%

    // Access control modifiers
    modifier onlyTreasuryEnabled() {
        require(treasuryEnabled, "Treasury is disabled");
        _;
    }

    modifier onlyValidTreasuryName(string memory treasuryName) {
        require(bytes(treasuryName).length > 0, "Treasury name cannot be empty");
        require(bytes(treasuryName).length <= 50, "Treasury name too long");
        _;
    }

    modifier onlyValidAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= 10000 ether, "Amount exceeds maximum limit");
        _;
    }

    modifier onlyValidUser(address user) {
        require(user != address(0), "Invalid user address");
        _;
    }

    modifier onlyActiveTreasury(string memory treasuryName) {
        require(treasuries[treasuryName].isActive, "Treasury is not active");
        _;
    }

    // Events
    event TreasuryCreated(string indexed treasuryName, uint256 initialBalance, uint256 timestamp);
    event TreasuryUpdated(string indexed treasuryName, uint256 oldBalance, uint256 newBalance, uint256 timestamp);
    event FundsDeposited(string indexed treasuryName, address indexed user, uint256 amount, uint256 timestamp);
    event FundsWithdrawn(string indexed treasuryName, address indexed user, uint256 amount, uint256 timestamp);
    event ReserveUpdated(string indexed treasuryName, uint256 oldReserve, uint256 newReserve, uint256 timestamp);
    event TreasuryToggled(bool enabled, uint256 timestamp);

    // 추가된 이벤트들
    event TreasuryBalanceLow(string indexed treasuryName, uint256 currentBalance, uint256 threshold, uint256 timestamp);
    event TreasuryBalanceHigh(
        string indexed treasuryName, uint256 currentBalance, uint256 threshold, uint256 timestamp
    );
    event WithdrawalLimitExceeded(address indexed user, uint256 requestedAmount, uint256 maxAllowed, uint256 timestamp);
    event ReserveRatioUpdated(uint256 oldRatio, uint256 newRatio, uint256 timestamp);
    event TreasuryEmergencyWithdraw(address indexed by, uint256 amount, string reason, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() Ownable(msg.sender) {
        treasuryEnabled = true;
    }

    /**
     * @dev Treasury 생성
     */
    function createTreasury(string memory treasuryName, uint256 initialBalance) external onlyOwner {
        require(bytes(treasuryName).length > 0, "Treasury name cannot be empty");
        require(treasuries[treasuryName].totalBalance == 0, "Treasury already exists");

        treasuries[treasuryName] = Treasury({
            totalBalance: initialBalance,
            reservedBalance: (initialBalance * minReserveRatio) / 100,
            availableBalance: initialBalance - ((initialBalance * minReserveRatio) / 100),
            lastUpdate: block.timestamp,
            isActive: true
        });

        emit TreasuryCreated(treasuryName, initialBalance, block.timestamp);
    }

    /**
     * @dev 자금 예치
     */
    function depositFunds(string memory treasuryName, address user, uint256 amount)
        external
        onlyOwnerOrAuthorized
        nonReentrant
        onlyTreasuryEnabled
        onlyValidTreasuryName(treasuryName)
        onlyValidUser(user)
        onlyValidAmount(amount)
        onlyActiveTreasury(treasuryName)
    {
        Treasury storage treasury = treasuries[treasuryName];
        uint256 oldBalance = treasury.totalBalance;
        uint256 timestamp = block.timestamp;

        treasury.totalBalance += amount;
        treasury.availableBalance += amount;
        treasury.lastUpdate = timestamp;

        userBalances[user] += amount;
        userTreasuryBalances[treasuryName][user] += amount;

        emit FundsDeposited(treasuryName, user, amount, timestamp);
        emit TreasuryUpdated(treasuryName, oldBalance, treasury.totalBalance, timestamp);
    }

    /**
     * @dev 자금 인출
     */
    function withdrawFunds(string memory treasuryName, address user, uint256 amount)
        external
        onlyOwnerOrAuthorized
        nonReentrant
        onlyTreasuryEnabled
        onlyValidTreasuryName(treasuryName)
        onlyValidUser(user)
        onlyValidAmount(amount)
        onlyActiveTreasury(treasuryName)
    {
        require(amount <= maxWithdrawalAmount, "Amount exceeds maximum withdrawal");
        require(userTreasuryBalances[treasuryName][user] >= amount, "Insufficient balance");

        Treasury storage treasury = treasuries[treasuryName];
        require(treasury.availableBalance >= amount, "Insufficient available balance");

        uint256 oldBalance = treasury.totalBalance;
        uint256 oldReserve = treasury.reservedBalance;
        uint256 timestamp = block.timestamp;

        treasury.totalBalance -= amount;
        treasury.availableBalance -= amount;
        treasury.lastUpdate = timestamp;

        // Ensure minimum reserve is maintained
        uint256 requiredReserve = (treasury.totalBalance * minReserveRatio) / 100;
        if (treasury.reservedBalance > requiredReserve) {
            uint256 excessReserve = treasury.reservedBalance - requiredReserve;
            treasury.reservedBalance = requiredReserve;
            treasury.availableBalance += excessReserve;
        }

        userBalances[user] -= amount;
        userTreasuryBalances[treasuryName][user] -= amount;

        emit FundsWithdrawn(treasuryName, user, amount, timestamp);
        emit TreasuryUpdated(treasuryName, oldBalance, treasury.totalBalance, timestamp);
        if (oldReserve != treasury.reservedBalance) {
            emit ReserveUpdated(treasuryName, oldReserve, treasury.reservedBalance, timestamp);
        }
    }

    /**
     * @dev 예약 자금 설정
     */
    function setReserve(string memory treasuryName, uint256 reserveAmount) external onlyOwner {
        require(treasuries[treasuryName].isActive, "Treasury is not active");
        require(reserveAmount <= treasuries[treasuryName].totalBalance, "Reserve cannot exceed total balance");

        Treasury storage treasury = treasuries[treasuryName];
        uint256 oldReserve = treasury.reservedBalance;

        treasury.reservedBalance = reserveAmount;
        treasury.availableBalance = treasury.totalBalance - reserveAmount;
        treasury.lastUpdate = block.timestamp;

        emit ReserveUpdated(treasuryName, oldReserve, treasury.reservedBalance, block.timestamp);
    }

    /**
     * @dev 최소 예약 비율 업데이트
     */
    function updateMinReserveRatio(uint256 newRatio) external onlyOwner {
        require(newRatio <= 50, "Reserve ratio cannot exceed 50%");
        uint256 oldRatio = minReserveRatio;
        minReserveRatio = newRatio;
        emit ReserveRatioUpdated(oldRatio, newRatio, block.timestamp);
    }

    /**
     * @dev 최대 인출 금액 업데이트
     */
    function updateMaxWithdrawalAmount(uint256 newAmount) external onlyOwner {
        uint256 oldAmount = maxWithdrawalAmount;
        maxWithdrawalAmount = newAmount;
        emit TreasuryUpdated("MaxWithdrawalAmount", oldAmount, newAmount, block.timestamp);
    }

    /**
     * @dev 긴급 인출 (관리자만)
     */
    function emergencyWithdraw(string memory treasuryName, uint256 amount, string memory reason) external onlyOwner {
        require(treasuries[treasuryName].isActive, "Treasury is not active");
        require(treasuries[treasuryName].availableBalance >= amount, "Insufficient available balance");

        treasuries[treasuryName].availableBalance -= amount;
        treasuries[treasuryName].totalBalance -= amount;
        treasuries[treasuryName].lastUpdate = block.timestamp;

        emit TreasuryEmergencyWithdraw(msg.sender, amount, reason, block.timestamp);
        emit TreasuryUpdated(
            treasuryName,
            treasuries[treasuryName].totalBalance + amount,
            treasuries[treasuryName].totalBalance,
            block.timestamp
        );
    }

    /**
     * @dev 잔액 모니터링
     */
    function checkTreasuryBalance(string memory treasuryName) external view {
        Treasury storage treasury = treasuries[treasuryName];
        uint256 threshold = (treasury.totalBalance * 10) / 100; // 10% 임계값

        if (treasury.availableBalance < threshold) {
            // 이벤트는 view 함수에서 발생시킬 수 없으므로 별도 함수로 처리
        }
    }

    /**
     * @dev Treasury 활성화/비활성화
     */
    function toggleTreasury(string memory treasuryName) external onlyOwner {
        treasuries[treasuryName].isActive = !treasuries[treasuryName].isActive;
    }

    /**
     * @dev Treasury 시스템 활성화/비활성화
     */
    function toggleTreasurySystem() external onlyOwner {
        treasuryEnabled = !treasuryEnabled;
        emit TreasuryToggled(treasuryEnabled, block.timestamp);
    }

    /**
     * @dev Treasury 정보 조회
     */
    function getTreasuryInfo(string memory treasuryName)
        external
        view
        returns (
            uint256 totalBalance,
            uint256 reservedBalance,
            uint256 availableBalance,
            uint256 lastUpdate,
            bool isActive
        )
    {
        Treasury storage treasury = treasuries[treasuryName];
        return (
            treasury.totalBalance,
            treasury.reservedBalance,
            treasury.availableBalance,
            treasury.lastUpdate,
            treasury.isActive
        );
    }

    /**
     * @dev 사용자 잔액 조회
     */
    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }

    /**
     * @dev 사용자 Treasury 잔액 조회
     */
    function getUserTreasuryBalance(string memory treasuryName, address user) external view returns (uint256) {
        return userTreasuryBalances[treasuryName][user];
    }

    /**
     * @dev Authorized contract 추가
     */
    function addAuthorizedContract(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "Invalid contract address");
        authorizedContracts[contractAddress] = true;
    }

    /**
     * @dev Authorized contract 제거
     */
    function removeAuthorizedContract(address contractAddress) external onlyOwner {
        authorizedContracts[contractAddress] = false;
    }

    /**
     * @dev Owner 또는 authorized contract만 허용하는 modifier
     */
    modifier onlyOwnerOrAuthorized() {
        require(msg.sender == owner() || authorizedContracts[msg.sender], "Not authorized");
        _;
    }
}
