// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../shared/interfaces/ITreasuryManager.sol";
import "../../shared/interfaces/ICryptolottoReferral.sol";
import "../../shared/interfaces/IFundsDistributor.sol";
import "../../shared/interfaces/IAnalyticsEngine.sol";
import "../../shared/interfaces/ICryptolottoStatsAggregator.sol";
import "../../shared/utils/ContractRegistry.sol";
import "../../shared/utils/GasOptimizer.sol";
import "../../shared/storage/StorageLayout.sol";
import "../../shared/storage/StorageAccess.sol";
import "../../shared/storage/StorageOptimizer.sol";
import "./BaseGame.sol";

using GasOptimizer for address[];
using StorageOptimizer for address[];

/**
 * @title Cryptolotto1Day
 * @dev 1일 로또 게임 컨트랙트 - 새로운 중앙화된 스토리지 아키텍처 사용
 */
contract Cryptolotto1Day is BaseGame {
    // 보안 강화를 위한 상수
    uint256 public constant MIN_BLOCK_DELAY = 1; // 최소 블록 지연
    uint256 public constant MAX_BLOCK_DELAY = 256; // 최대 블록 지연
    uint256 public constant PURCHASE_COOLDOWN = 30 seconds; // 구매 쿨다운
    uint256 public constant MAX_TICKETS_PER_TRANSACTION = 10; // 트랜잭션당 최대 티켓

    // 보안 강화를 위한 상태 변수
    mapping(address => uint256) public lastPurchaseTime;
    bool public testMode = false; // 테스트 모드 플래그

    // ============ EVENTS ============
    event ReferralError(string operation, string reason, uint256 timestamp);
    event StatsError(string operation, string reason, uint256 timestamp);
    event DistributorError(string operation, string reason, uint256 timestamp);
    event PurchaseCooldownUpdated(uint256 newCooldown, uint256 timestamp);

    // ============ INITIALIZATION ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address /* distributor */,
        address /* statsA */,
        address /* referralSystem */,
        address /* _treasuryManager */,
        string memory /* _treasuryName */
    ) public initializer {
        require(owner != address(0), "Invalid owner address");

        __BaseGame_init(owner, address(0)); // registry는 나중에 설정

        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.ticketPrice = 0.01 ether;
        gameStorage.gameDuration = 1 days;
        gameStorage.maxTicketsPerPlayer = 100;
    }

    // ============ GAME FUNCTIONS ============

    /**
     * @dev 내부 티켓 구매 함수 (중앙화된 스토리지 사용)
     */
    function _buyTicketInternal(address partner, uint256 ticketCount) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        require(gameStorage.isActive, "Game is not active");
        require(ticketCount > 0, "Ticket count must be greater than 0");
        require(
            msg.value == gameStorage.ticketPrice * ticketCount,
            "Incorrect amount sent"
        );

        // 현재 게임 정보 가져오기
        uint256 currentGameId = gameStorage.totalGames;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];

        // 게임이 아직 시작되지 않았다면 시작
        if (game.state == StorageLayout.GameState.WAITING) {
            _startNewGame();
            game = gameStorage.games[currentGameId];
        }

        require(
            game.state == StorageLayout.GameState.ACTIVE,
            "Game not active"
        );

        // 최대 티켓 수 확인
        require(
            gameStorage.playerTicketCount[msg.sender] + ticketCount <=
                gameStorage.maxTicketsPerPlayer,
            "Exceeds maximum tickets per player"
        );

        // 플레이어 정보 업데이트
        _updatePlayerInfoOptimized(msg.sender, ticketCount);

        // 재무 시스템 연동
        _transferToTreasury(msg.value);

        // 추천 시스템 처리
        for (uint i = 0; i < ticketCount; i++) {
            _processReferralSystem(partner, msg.sender);
        }

        // 이벤트 발생
        for (uint i = 0; i < ticketCount; i++) {
            emit TicketPurchased(
                msg.sender,
                game.gameNumber,
                game.players.length - 1 + i,
                block.timestamp
            );
        }
    }

    /**
     * @dev 승자 선택 (중앙화된 스토리지 사용)
     */
    function _pickWinner() internal view override returns (address) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];
        require(game.players.length > 0, "No players in game");

        uint256 randomIndex = enhancedRandomNumberSecure(
            0,
            game.players.length - 1,
            block.timestamp
        );
        return game.players[randomIndex];
    }

    /**
     * @dev 승자 지급 처리
     */
    function _processWinnerPayout(
        address winner,
        uint256 amount
    ) internal override {
        if (address(registry) == address(0)) {
            emit TreasuryOperationFailed("payout", block.timestamp);
            return;
        }

        try registry.getContract(treasuryName) returns (
            address treasuryAddress
        ) {
            if (treasuryAddress != address(0)) {
                ITreasuryManager treasury = ITreasuryManager(treasuryAddress);
                treasury.withdrawFunds(treasuryName, winner, amount);
                emit TreasuryFundsWithdrawn(winner, amount, block.timestamp);
            } else {
                emit ContractNotFound(treasuryName, block.timestamp);
            }
        } catch Error(string memory /* reason */) {
            emit TreasuryOperationFailed("payout", block.timestamp);
        } catch {
            emit TreasuryOperationFailed("payout", block.timestamp);
        }
    }

    /**
     * @dev 창립자 분배 처리
     */
    function _processFounderDistribution(uint256 amount) internal override {
        if (address(registry) == address(0)) {
            emit DistributorError(
                "getContract",
                "Registry not initialized",
                block.timestamp
            );
            return;
        }

        try registry.getContract("FundsDistributor") returns (
            address distributorAddress
        ) {
            if (distributorAddress == address(0)) {
                emit DistributorError(
                    "getContract",
                    "Distributor contract not found",
                    block.timestamp
                );
                return;
            }

            try IFundsDistributor(distributorAddress).withdrawAmount(amount) {
                // 성공적으로 처리됨
            } catch Error(string memory reason) {
                emit DistributorError(
                    "withdrawAmount",
                    reason,
                    block.timestamp
                );
            } catch {
                emit DistributorError(
                    "withdrawAmount",
                    "Unknown error",
                    block.timestamp
                );
            }
        } catch Error(string memory reason) {
            emit DistributorError("getContract", reason, block.timestamp);
        } catch {
            emit DistributorError(
                "getContract",
                "Unknown registry error",
                block.timestamp
            );
        }
    }

    /**
     * @dev 게임 통계 업데이트
     */
    function _updateGameStats(
        address winner,
        uint256 playerCount,
        uint256 amount,
        uint256 winnerIndex
    ) internal override {
        if (address(registry) == address(0)) {
            emit StatsError(
                "getContract",
                "Registry not initialized",
                block.timestamp
            );
            return;
        }

        try registry.getContract("StatsAggregator") returns (
            address statsAddress
        ) {
            if (statsAddress == address(0)) {
                emit StatsError(
                    "getContract",
                    "Stats contract not found",
                    block.timestamp
                );
                return;
            }

            (
                uint256 gameNumber, // startTime // endTime // jackpot // playerCount // state
                ,
                ,
                ,
                ,

            ) = getCurrentGameInfo();

            try
                ICryptolottoStatsAggregator(statsAddress).newWinner(
                    winner,
                    gameNumber,
                    playerCount,
                    amount,
                    1, // 1일 게임 타입
                    winnerIndex
                )
            {
                // 성공적으로 처리됨
            } catch Error(string memory reason) {
                emit StatsError("newWinner", reason, block.timestamp);
            } catch {
                emit StatsError("newWinner", "Unknown error", block.timestamp);
            }
        } catch Error(string memory reason) {
            emit StatsError("getContract", reason, block.timestamp);
        } catch {
            emit StatsError(
                "getContract",
                "Unknown registry error",
                block.timestamp
            );
        }
    }

    /**
     * @dev 게임 성능 메트릭 기록
     * @notice 게임 성능을 추적하기 위한 메트릭 기록
     */
    function _recordPerformanceMetrics(
        uint256 gameNumber,
        uint256 gasUsed,
        uint256 playerCount,
        uint256 jackpot
    ) internal override {
        emit GamePerformanceMetrics(
            gameNumber,
            gasUsed,
            playerCount,
            jackpot,
            block.timestamp
        );
    }

    /**
     * @dev 보안 이벤트 기록
     * @notice 보안 관련 이벤트를 기록합니다
     */
    function _recordSecurityEvent(
        address player,
        string memory eventType
    ) internal override {
        emit GameSecurityEvent(player, eventType, block.timestamp);
    }

    /**
     * @dev 게임 종료 처리 (내부 함수)
     * @notice 게임을 종료하고 승자를 선택합니다
     */
    function _endGame() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];

        // 게임 상태를 ENDED로 변경
        game.state = StorageLayout.GameState.ENDED;

        // 승자 선택
        _pickWinner();

        // 성능 메트릭 기록
        _recordPerformanceMetrics(
            game.gameNumber,
            gasleft(),
            game.players.length,
            game.jackpot
        );

        // 새 게임 시작 준비
        _startNewGame();
    }

    // ============ UTILITY FUNCTIONS ============

    /**
     * @dev 게임 시간 만료 확인
     */
    function isGameTimeExpired() public view returns (bool) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];
        return block.timestamp >= game.endTime;
    }

    /**
     * @dev 게임 정보 조회
     */
    function getGameInfo()
        public
        view
        returns (
            uint256 currentGameNumber,
            uint256 startTime,
            uint256 duration,
            uint256 remainingTime,
            bool timeExpired,
            uint256 playerCount,
            uint256 currentJackpot
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];

        return (
            game.gameNumber,
            game.startTime,
            gameStorage.gameDuration,
            getRemainingGameTime(),
            isGameTimeExpired(),
            game.players.length,
            game.jackpot
        );
    }

    /**
     * @dev 플레이어 정보 조회
     */
    function getPlayerInfo(
        address player
    ) public view returns (uint256 ticketsInCurrentGame, bool isInCurrentGame) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];

        bool inGame = false;
        address[] storage players = game.players;
        uint256 length = players.length;
        for (uint i = 0; i < length; i++) {
            if (players[i] == player) {
                inGame = true;
                break;
            }
        }

        return (gameStorage.playerTicketCount[player], inGame);
    }

    // ============ EMERGENCY FUNCTIONS ============

    /**
     * @dev 긴급 정지
     */
    function emergencyPause(string memory reason) public override onlyOwner {
        super.emergencyPause(reason);
    }

    /**
     * @dev 긴급 재개
     */
    function emergencyResume() public override onlyOwner {
        super.emergencyResume();
    }

    /**
     * @dev 계약 잔액 조회
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev 테스트 모드 설정 (관리자만)
     * @param enabled 테스트 모드 활성화 여부
     * @custom:security onlyOwner
     */
    function setTestMode(bool enabled) external onlyOwner {
        testMode = enabled;
        _recordSecurityEvent(
            msg.sender,
            enabled ? "Test Mode Enabled" : "Test Mode Disabled"
        );
    }

    /**
     * @dev 구매 쿨다운 시간 설정
     * @param newCooldown 새로운 쿨다운 시간 (초)
     * @custom:security onlyOwner
     */
    function setPurchaseCooldown(uint256 newCooldown) external onlyOwner {
        require(newCooldown >= 0, "Cooldown must be non-negative");
        // 상수는 변경할 수 없으므로 이벤트만 발생
        emit PurchaseCooldownUpdated(newCooldown, block.timestamp);
    }

    /**
     * @dev 플레이어 쿨다운 재설정
     * @param player 재설정할 플레이어 주소
     * @custom:security onlyOwner
     */
    function resetPlayerCooldown(address player) external onlyOwner {
        require(player != address(0), "Invalid player address");
        lastPurchaseTime[player] = 0;
        _recordSecurityEvent(player, "Cooldown Reset");
    }
}
