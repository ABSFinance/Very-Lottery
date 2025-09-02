// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseGame.sol";
import "../../shared/storage/StorageLayout.sol";
import "../../shared/utils/ContractRegistry.sol";
import "../../shared/interfaces/IFundsDistributor.sol";
import "../../shared/interfaces/ICryptolottoStatsAggregator.sol";

using GasOptimizer for address[];
using StorageOptimizer for address[];

/**
 * @title Cryptolotto7Days
 * @dev 7일 로또 게임 컨트랙트 - 새로운 중앙화된 스토리지 아키텍처 사용
 */
contract Cryptolotto7Days is BaseGame {
    // ============ STATE VARIABLES ============
    mapping(address => uint256) public lastPurchaseTime;
    bool public testMode = false;
    uint256 public constant PURCHASE_COOLDOWN = 30 seconds;
    uint256 public constant MAX_TICKETS_PER_TRANSACTION = 10;

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
        gameStorage.gameDuration = 7 days;
        gameStorage.maxTicketsPerPlayer = 100;
    }

    // ============ OVERRIDE FUNCTIONS ============

    // Remove duplicate functions - they are now inherited from BaseGame
    // getPlayerInfo() - inherited from BaseGame
    // getGameConfig() - inherited from BaseGame
    // resetPlayerCooldown() - inherited from BaseGame
    // setTestMode() - inherited from BaseGame
    // setPurchaseCooldown() - inherited from BaseGame
    // setRegistry() - inherited from BaseGame
    // _endGame() - inherited from BaseGame
    // _buyTicketInternal() - inherited from BaseGame

    // ============ GAME FUNCTIONS ============

    /**
     * @dev 승자 선택 (중앙화된 스토리지 사용)
     */
    function _pickWinner(
        uint256 gameId
    ) internal view override returns (address) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = gameStorage.games[gameId];
        require(game.players.length > 0, "No players in game");

        // If there's only one player, they automatically win
        if (game.players.length == 1) {
            return game.players[0];
        }

        uint256 randomIndex = enhancedRandomNumberSecure(
            0,
            game.players.length - 1,
            block.timestamp
        );
        return game.players[randomIndex];
    }

    /**
     * @dev 향상된 랜덤 생성 함수 (보안 강화)
     * @notice 시간 기반 공격 방지를 위한 추가 엔트로피 소스 사용
     */
    function enhancedRandomNumberSecure(
        uint256 min,
        uint256 max,
        uint256 seed
    ) internal view override returns (uint256) {
        require(max > min, "Invalid range");
        require(max - min <= type(uint256).max - 1, "Range too large");

        // 여러 엔트로피 소스 결합
        bytes32 hash = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                block.number,
                blockhash(block.number - 1),
                blockhash(block.number - 2),
                seed,
                msg.sender,
                gasleft()
            )
        );

        // 안전한 모듈로 연산
        uint256 range = max - min + 1;
        uint256 randomValue = uint256(hash) % range;
        return min + randomValue;
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

        try registry.getContract("TreasuryManager") returns (
            address treasuryAddress
        ) {
            if (treasuryAddress == address(0)) {
                emit TreasuryOperationFailed("payout", block.timestamp);
                return;
            }

            // Process winner payout
            if (winner != address(0) && amount > 0) {
                try
                    ITreasuryManager(treasuryAddress).withdrawFunds(
                        treasuryName,
                        winner,
                        amount
                    )
                {
                    emit WinnerPayout(winner, amount, block.timestamp);
                } catch {
                    emit TreasuryTransferFailed(
                        address(this),
                        amount,
                        "Withdrawal failed",
                        block.timestamp
                    );
                }
            }
        } catch Error(string memory) /* reason */ {
            emit RegistryError(
                "getContract",
                "TreasuryManager",
                block.timestamp
            );
        } catch {
            emit RegistryError(
                "getContract",
                "TreasuryManager",
                block.timestamp
            );
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
            } catch Error(string memory) /* reason */ {
                emit DistributorError(
                    "withdrawAmount",
                    "Unknown error",
                    block.timestamp
                );
            } catch {
                emit DistributorError(
                    "withdrawAmount",
                    "Unknown error",
                    block.timestamp
                );
            }
        } catch Error(string memory) /* reason */ {
            emit DistributorError(
                "getContract",
                "Unknown registry error",
                block.timestamp
            );
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
        uint256,
        /* playerCount */
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

            uint256 gameNumber = getCurrentGameNumber();
            // uint256 startTime = getCurrentGameStartTime();
            // uint256 endTime = getCurrentGameEndTime();
            // uint256 jackpot = getCurrentGameJackpot();
            uint256 gamePlayerCount = getCurrentGamePlayerCount();
            // StorageLayout.GameState state = getCurrentGameState();

            try
                ICryptolottoStatsAggregator(statsAddress).newWinner(
                    winner,
                    gameNumber,
                    gamePlayerCount,
                    amount,
                    7, // 7일 게임 타입
                    winnerIndex
                )
            {
                // 성공적으로 처리됨
            } catch Error(string memory) /* reason */ {
                emit StatsError("newWinner", "Unknown error", block.timestamp);
            } catch {
                emit StatsError("newWinner", "Unknown error", block.timestamp);
            }
        } catch Error(string memory) /* reason */ {
            emit StatsError(
                "getContract",
                "Unknown registry error",
                block.timestamp
            );
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

    // ============ UTILITY FUNCTIONS ============

    /**
     * @dev 게임 시간 만료 확인
     */
    function isGameTimeExpired() public view returns (bool) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
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
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
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
     * @notice Emergency pause the contract
     * @param reason The reason for pausing
     */
    function emergencyPause(string memory reason) public override onlyOwner {
        super.emergencyPause(reason);
    }

    /**
     * @notice Emergency resume the contract
     */
    function emergencyResume() public override onlyOwner {
        super.emergencyResume();
    }
}
