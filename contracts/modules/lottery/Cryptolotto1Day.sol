// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IFundsDistributor} from "../../shared/interfaces/IFundsDistributor.sol";
import {ICryptolottoStatsAggregator} from "../../shared/interfaces/ICryptolottoStatsAggregator.sol";
import {ITreasuryManager} from "../../shared/interfaces/ITreasuryManager.sol";
import {ContractRegistry} from "../../shared/utils/ContractRegistry.sol";
import {GasOptimizer} from "../../shared/utils/GasOptimizer.sol";
import {StorageLayout} from "../../shared/storage/StorageLayout.sol";
import {StorageAccess} from "../../shared/storage/StorageAccess.sol";
import {StorageOptimizer} from "../../shared/storage/StorageOptimizer.sol";
import {BaseGame} from "./BaseGame.sol";

using GasOptimizer for address[];
using StorageOptimizer for address[];

/**
 * @title Cryptolotto1Day
 * @author Cryptolotto Team
 * @notice 1일 로또 게임 컨트랙트 - 새로운 중앙화된 스토리지 아키텍처 사용
 * @dev 1일 단위로 진행되는 로또 게임을 관리합니다
 */
contract Cryptolotto1Day is BaseGame {
    // 보안 강화를 위한 상수
    /**
     * @notice Minimum block delay time
     */
    uint256 public constant MIN_BLOCK_DELAY = 1;
    /**
     * @notice Maximum block delay time
     */
    uint256 public constant MAX_BLOCK_DELAY = 256;
    /**
     * @notice Purchase cooldown time
     */
    uint256 public constant PURCHASE_COOLDOWN = 30 seconds;
    /**
     * @notice Maximum tickets per transaction
     */
    uint256 public constant MAX_TICKETS_PER_TRANSACTION = 10;

    // 보안 강화를 위한 상태 변수
    /**
     * @notice Last purchase time per player
     */
    mapping(address => uint256) public lastPurchaseTime;
    /**
     * @notice Test mode flag
     */
    bool public testMode = false;

    // ============ EVENTS ============
    /**
     * @notice Emitted when referral error occurs
     * @param operation The operation that failed
     * @param reason The reason for failure
     * @param timestamp The timestamp when error occurred
     */
    event ReferralError(string operation, string reason, uint256 timestamp);
    /**
     * @notice Emitted when stats error occurs
     * @param operation The operation that failed
     * @param reason The reason for failure
     * @param timestamp The timestamp when error occurred
     */
    event StatsError(string operation, string reason, uint256 timestamp);
    /**
     * @notice Emitted when distributor error occurs
     * @param operation The operation that failed
     * @param reason The reason for failure
     * @param timestamp The timestamp when error occurred
     */
    event DistributorError(string operation, string reason, uint256 timestamp);
    /**
     * @notice Emitted when purchase cooldown is updated
     * @param newCooldown The new cooldown value
     * @param timestamp The timestamp when cooldown was updated
     */
    event PurchaseCooldownUpdated(uint256 newCooldown, uint256 timestamp);

    // ============ INITIALIZATION ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address, /* distributor */
        address, /* statsA */
        address, /* referralSystem */
        address, /* _treasuryManager */
        string memory /* _treasuryName */
    ) public initializer {
        require(owner != address(0), "Invalid owner address");

        __BaseGame_init(owner, address(0)); // registry will be set later

        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.ticketPrice = 0.01 ether;
        gameStorage.gameDuration = 1 days;
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
     * @dev Select winner (using centralized storage)
     */
    function _pickWinner() internal view override returns (address) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0 ? gameStorage.totalGames - 1 : 0;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];
        require(game.players.length > 0, "No players in game");

        uint256 randomIndex = enhancedRandomNumberSecure(0, game.players.length - 1, block.timestamp);
        return game.players[randomIndex];
    }

    /**
     * @dev Process winner payout
     */
    function _processWinnerPayout(address winner, uint256 amount) internal override {
        if (address(registry) == address(0)) {
            emit TreasuryOperationFailed("payout", block.timestamp);
            return;
        }

        try registry.getContract(treasuryName) returns (address treasuryAddress) {
            if (treasuryAddress != address(0)) {
                ITreasuryManager treasury = ITreasuryManager(treasuryAddress);
                treasury.withdrawFunds(treasuryName, winner, amount);
                emit WinnerPayout(winner, amount, block.timestamp);
            } else {
                emit ContractNotFound(treasuryName, block.timestamp);
            }
        } catch Error(string memory) /* reason */ {
            emit TreasuryOperationFailed("payout", block.timestamp);
        } catch {
            emit TreasuryOperationFailed("payout", block.timestamp);
        }
    }

    /**
     * @dev Process founder distribution
     */
    function _processFounderDistribution(uint256 amount) internal override {
        if (address(registry) == address(0)) {
            emit DistributorError("getContract", "Registry not initialized", block.timestamp);
            return;
        }

        try registry.getContract("FundsDistributor") returns (address distributorAddress) {
            if (distributorAddress == address(0)) {
                emit DistributorError("getContract", "Distributor contract not found", block.timestamp);
                return;
            }

            try IFundsDistributor(distributorAddress).withdrawAmount(amount) {
                // Successfully processed
            } catch Error(string memory reason) {
                emit DistributorError("withdrawAmount", reason, block.timestamp);
            } catch {
                emit DistributorError("withdrawAmount", "Unknown error", block.timestamp);
            }
        } catch Error(string memory reason) {
            emit DistributorError("getContract", reason, block.timestamp);
        } catch {
            emit DistributorError("getContract", "Unknown registry error", block.timestamp);
        }
    }

    /**
     * @dev Update game stats
     */
    function _updateGameStats(
        address winner,
        uint256,
        /* playerCount */
        uint256 amount,
        uint256 winnerIndex
    ) internal override {
        if (address(registry) == address(0)) {
            emit StatsError("getContract", "Registry not initialized", block.timestamp);
            return;
        }

        try registry.getContract("StatsAggregator") returns (address statsAddress) {
            if (statsAddress == address(0)) {
                emit StatsError("getContract", "Stats contract not found", block.timestamp);
                return;
            }

            uint256 gameNumber = getCurrentGameNumber();
            // uint256 startTime = getCurrentGameStartTime();
            // uint256 endTime = getCurrentGameEndTime();
            // uint256 jackpot = getCurrentGameJackpot();
            uint256 gamePlayerCount = getCurrentGamePlayerCount();
            // StorageLayout.GameState state = getCurrentGameState();

            try ICryptolottoStatsAggregator(statsAddress).newWinner(
                winner,
                gameNumber,
                gamePlayerCount,
                amount,
                1, // 1 day game type
                winnerIndex
            ) {
                // Successfully processed
            } catch Error(string memory reason) {
                emit StatsError("newWinner", reason, block.timestamp);
            } catch {
                emit StatsError("newWinner", "Unknown error", block.timestamp);
            }
        } catch Error(string memory reason) {
            emit StatsError("getContract", reason, block.timestamp);
        } catch {
            emit StatsError("getContract", "Unknown registry error", block.timestamp);
        }
    }

    /**
     * @dev Record game performance metrics
     * @notice Record metrics for tracking game performance
     */
    function _recordPerformanceMetrics(
        uint256 gameNumber,
        uint256 gasUsed,
        uint256,
        /* playerCount */
        uint256 jackpot
    ) internal override {
        emit GamePerformanceMetrics(gameNumber, gasUsed, jackpot, jackpot, block.timestamp);
    }

    /**
     * @dev Record security event
     * @param player The player address
     * @param eventType The event type
     */
    function _recordSecurityEvent(address player, string memory eventType) internal override {
        emit GameSecurityEvent(player, eventType, block.timestamp);
    }

    // ============ UTILITY FUNCTIONS ============

    /**
     * @dev Check if game time has expired
     */
    function isGameTimeExpired() public view returns (bool) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];
        return block.timestamp >= game.endTime;
    }

    /**
     * @dev Get game info
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

    // ============ EMERGENCY FUNCTIONS ============

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
