// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IOwnable} from "../../shared/interfaces/IOwnable.sol";
import {ContractRegistry} from "../../shared/utils/ContractRegistry.sol";
import {GasOptimizer} from "../../shared/utils/GasOptimizer.sol";
import {StorageLayout} from "../../shared/storage/StorageLayout.sol";
import {StorageAccess} from "../../shared/storage/StorageAccess.sol";
import {StorageOptimizer} from "../../shared/storage/StorageOptimizer.sol";
import {CryptolottoReferral} from "../../modules/treasury/CryptolottoReferral.sol";
import {ITreasuryManager} from "../../shared/interfaces/ITreasuryManager.sol";
import {LotteryUtils} from "../../shared/libraries/LotteryUtils.sol";
import {LotteryHelper} from "../../shared/utils/LotteryHelper.sol";

using GasOptimizer for address[];
using StorageOptimizer for address[];

/**
 * @title BaseGame
 * @author Cryptolotto Team
 * @notice 모든 게임 컨트랙트의 기본 클래스
 * @dev 새로운 중앙화된 스토리지 아키텍처 사용
 */
abstract contract BaseGame is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    StorageAccess
{
    // ============ STORAGE VARIABLES (중앙화된 스토리지 사용) ============

    // 기존 개별 스토리지 변수들을 제거하고 중앙화된 스토리지 사용
    // mapping(address => uint256) public playerTicketCount; // 제거됨
    // Game currentGame; // 제거됨
    // uint256 ticketPrice; // 제거됨

    // Centralized storage access variables
    /**
     * @notice Contract registry for managing contract addresses
     */
    ContractRegistry public registry;
    /**
     * @notice Treasury name for fund management
     */
    string public treasuryName;
    /**
     * @notice Ownable contract instance
     */
    IOwnable public ownable;

    // Fee constants
    uint256 public constant TOTAL_FEE_PERCENT = 10;
    uint256 public constant REFERRAL_FEE_PERCENT = 3;
    uint256 public constant AD_LOTTERY_FEE_PERCENT = 4;
    uint256 public constant DEVELOPER_FEE_PERCENT = 3;

    // Library instance
    LotteryHelper public lotteryHelper;

    // ============ EVENTS ============
    // Events are now defined in LotteryUtils library
    /**
     * @notice Emitted when jackpot is distributed
     * @param winner The address of the winner
     * @param amount The amount distributed
     * @param gameNumber The game number
     * @param timestamp The timestamp when jackpot was distributed
     */
    event JackpotDistributed(
        address indexed winner,
        uint256 amount,
        uint256 indexed gameNumber,
        uint256 timestamp
    );
    /**
     * @notice Emitted when emergency pause is activated
     * @param by The address that triggered the pause
     * @param reason The reason for the pause
     * @param timestamp The timestamp when pause was activated
     */
    event EmergencyPaused(address indexed by, string reason, uint256 timestamp);
    /**
     * @notice Emitted when emergency pause is resumed
     * @param by The address that resumed the system
     * @param timestamp The timestamp when system was resumed
     */
    event EmergencyResumed(address indexed by, uint256 timestamp);
    /**
     * @notice Emitted when max tickets per player is updated
     * @param oldValue The old max tickets value
     * @param newValue The new max tickets value
     * @param timestamp The timestamp when the value was updated
     */
    event MaxTicketsPerPlayerUpdated(
        uint256 oldValue,
        uint256 newValue,
        uint256 timestamp
    );
    /**
     * @notice Emitted when game duration is updated
     * @param oldValue The old game duration value
     * @param newValue The new game duration value
     * @param timestamp The timestamp when the value was updated
     */
    event GameDurationUpdated(
        uint256 oldValue,
        uint256 newValue,
        uint256 timestamp
    );
    /**
     * @notice Emitted when fees are distributed
     * @param referralFee The referral fee amount
     * @param adLotteryFee The ad lottery fee amount
     * @param developerFee The developer fee amount
     * @param timestamp The timestamp when fees were distributed
     */
    event FeeDistributed(
        uint256 referralFee,
        uint256 adLotteryFee,
        uint256 developerFee,
        uint256 timestamp
    );
    /**
     * @notice Emitted when developer fee is sent
     * @param distributor The distributor address
     * @param amount The amount sent
     * @param timestamp The timestamp when fee was sent
     */
    event DeveloperFeeSent(
        address indexed distributor,
        uint256 amount,
        uint256 timestamp
    );
    /**
     * @notice Emitted when game performance metrics are recorded
     * @param gameNumber The game number
     * @param gasUsed The gas used
     * @param playerCount The number of players
     * @param jackpot The jackpot amount
     * @param timestamp The timestamp when metrics were recorded
     */
    event GamePerformanceMetrics(
        uint256 indexed gameNumber,
        uint256 gasUsed,
        uint256 playerCount,
        uint256 jackpot,
        uint256 timestamp
    );
    /**
     * @notice Emitted when a game security event occurs
     * @param player The player address
     * @param eventType The type of security event
     * @param timestamp The timestamp when the event occurred
     */
    event GameSecurityEvent(
        address indexed player,
        string eventType,
        uint256 timestamp
    );
    /**
     * @notice Emitted when ad lottery fee is collected
     * @param amount The amount collected
     * @param timestamp The timestamp when fee was collected
     */
    event AdLotteryFeeCollected(uint256 amount, uint256 timestamp);
    /**
     * @notice Emitted when ticket price is changed
     * @param oldPrice The old ticket price
     * @param newPrice The new ticket price
     * @param timestamp The timestamp when price was changed
     */
    event TicketPriceChanged(
        uint256 oldPrice,
        uint256 newPrice,
        uint256 timestamp
    );
    /**
     * @notice Emitted when game state is changed
     * @param gameNumber The game number
     * @param state The new game state
     * @param timestamp The timestamp when state was changed
     */
    event GameStateChanged(
        uint256 gameNumber,
        StorageLayout.GameState state,
        uint256 timestamp
    );
    /**
     * @notice Emitted when treasury funds are deposited
     * @param amount The amount deposited
     * @param timestamp The timestamp when funds were deposited
     */
    event TreasuryFundsDeposited(uint256 amount, uint256 timestamp);
    /**
     * @notice Emitted when treasury funds are withdrawn
     * @param winner The winner address
     * @param amount The amount withdrawn
     * @param timestamp The timestamp when funds were withdrawn
     */
    event TreasuryFundsWithdrawn(
        address winner,
        uint256 amount,
        uint256 timestamp
    );
    /**
     * @notice Emitted when treasury operation fails
     * @param operation The operation that failed
     * @param timestamp The timestamp when operation failed
     */
    event TreasuryOperationFailed(string operation, uint256 timestamp);
    /**
     * @notice Emitted when registry error occurs
     * @param operation The operation that failed
     * @param contractName The contract name
     * @param timestamp The timestamp when error occurred
     */
    event RegistryError(
        string operation,
        string contractName,
        uint256 timestamp
    );
    /**
     * @notice Emitted when a contract is not found
     * @param contractName The name of the contract that was not found
     * @param timestamp The timestamp when the error occurred
     */
    event ContractNotFound(string contractName, uint256 timestamp);
    /**
     * @notice Emitted when treasury transfer fails
     * @param from The address attempting the transfer
     * @param amount The amount that failed to transfer
     * @param reason The reason for the failure
     * @param timestamp The timestamp when the transfer failed
     */
    event TreasuryTransferFailed(
        address from,
        uint256 amount,
        string reason,
        uint256 timestamp
    );

    // ============ ABSTRACT FUNCTIONS ============
    /**
     * @notice Process referral system rewards (라이브러리 사용)
     * @param referrer The referrer address
     * @param player The player address
     */
    function _processReferralSystem(
        address referrer,
        address player
    ) internal virtual {
        // Simplified referral system - only pay rewards if referrer is a valid address
        if (LotteryUtils.validateReferrer(referrer, player)) {
            // Get referral contract address
            address referralContract = registry.getContract(
                "CryptolottoReferral"
            );
            if (referralContract != address(0)) {
                // Process referral reward (amount calculated in BaseGame)
                try
                    CryptolottoReferral(referralContract).processReferralReward{
                        value: 0
                    }(
                        referrer,
                        0 // Amount is processed in _processFeeDistribution
                    )
                {
                    // Successfully processed
                    // Empty block intentionally left for future implementation
                } catch {
                    // Ignore referral processing failure (game continues)
                    // Empty block intentionally left for error handling
                }
            }
        }
    }

    /**
     * @notice Process winner payout
     * @param winner The winner address
     * @param amount The payout amount
     */
    function _processWinnerPayout(
        address winner,
        uint256 amount
    ) internal virtual;

    /**
     * @notice Process founder distribution
     * @param amount The distribution amount
     */
    function _processFounderDistribution(uint256 amount) internal virtual;

    /**
     * @notice Update game statistics
     * @param winner The winner address
     * @param playerCount The number of players
     * @param amount The amount won
     * @param winnerIndex The winner index
     */
    function _updateGameStats(
        address winner,
        uint256 playerCount,
        uint256 amount,
        uint256 winnerIndex
    ) internal virtual;

    /**
     * @notice Start a new game
     */
    function _startNewGame() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 newGameId = gameStorage.totalGames;
        StorageLayout.Game storage newGame = gameStorage.games[newGameId];
        (
            newGame.gameNumber,
            newGame.startTime,
            newGame.endTime,
            newGame.state
        ) = _initializeNewGame(newGameId, gameStorage.gameDuration);

        // Reset jackpot for new game
        newGame.jackpot = 0;

        // FIX: Reset player ticket counts for clean state in new game
        // Reset ticket counts for all players from the previous game
        if (newGameId > 0) {
            _resetPlayerTicketCountsForGame(newGameId - 1);
        }

        gameStorage.totalGames++;
        _emitNewGameEvents(newGameId);
    }

    /**
     * @notice End current game
     */
    function _endCurrentGame(uint256 gameId) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage currentGame = gameStorage.games[gameId];

        // DEBUG: Log player count before ending game
        emit GameStateChanged(gameId, currentGame.state, block.timestamp);

        // SIMPLE FIX: Handle the case where there are no players
        if (currentGame.players.length == 0) {
            // No players, just end the game without picking a winner
            currentGame.state = StorageLayout.GameState.ENDED;
            _emitGameEndEvents(
                currentGame.gameNumber,
                currentGame.jackpot,
                currentGame.playerCount,
                address(0) // No winner
            );
            return;
        }

        // Normal game ending with players
        _updateGameState(gameId);
        address winner = _pickWinner(gameId);

        _emitGameEndEvents(
            currentGame.gameNumber,
            currentGame.jackpot,
            currentGame.playerCount,
            winner
        );
    }

    /**
     * @notice Process referral reward (using CryptolottoReferral)
     * @param referrer The referrer address
     * @param player The player address
     */
    function _processReferralReward(
        address referrer,
        address player
    ) internal virtual {
        if (_isValidReferrer(referrer, player)) {
            if (_isRegistryAvailable()) {
                _executeReferralReward(referrer);
            }
        }
    }

    /**
     * @notice Process ad lottery fee
     * @param amount The ad lottery fee amount
     */
    function _processAdLotteryFee(uint256 amount) internal virtual {
        if (amount > 0) {
            // Ad Lottery fee is sent to the treasury for later distribution
            if (_isRegistryAvailable()) {
                _executeAdLotteryFeeTransfer(amount);
                // Notify Ad Lottery contract about the new fee
                _notifyAdLotteryOfNewFee(amount);
            }
            emit AdLotteryFeeCollected(amount, block.timestamp);
        }
    }

    /**
     * @notice Process developer fee
     * @param amount The developer fee amount
     */
    function _processDeveloperFee(uint256 amount) internal virtual {
        if (amount > 0) {
            if (_isRegistryAvailable()) {
                _executeDeveloperFeeTransfer(amount);
            }
        }
    }

    // ============ INITIALIZATION ============
    /**
     * @notice Initialize BaseGame contract
     * @param owner The owner address
     * @param _registry The registry address
     */
    function __BaseGame_init(
        address owner,
        address _registry
    ) internal onlyInitializing {
        require(owner != address(0), "Invalid owner address");
        // Registry can be set later, so conditional validation
        if (_registry != address(0)) {
            registry = ContractRegistry(_registry);
        }

        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        // Set ownable to this contract (since it inherits OwnableUpgradeable)
        ownable = IOwnable(address(this));

        // Initialize centralized storage
        _initializeGameStorage();
    }

    /**
     * @dev Initialize centralized game storage
     */
    function _initializeGameStorage() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        if (gameStorage.ticketPrice == 0) {
            gameStorage.ticketPrice = 0.01 ether;
            gameStorage.gameDuration = 1 days;
            gameStorage.maxTicketsPerPlayer = 100;
            gameStorage.isActive = true;

            // Create initial game
            StorageLayout.Game storage initialGame = gameStorage.games[0];
            initialGame.gameNumber = 0;
            initialGame.startTime = 0;
            initialGame.endTime = 0;
            initialGame.jackpot = 0;
            initialGame.playerCount = 0;
            initialGame.state = StorageLayout.GameState.WAITING;
        }
    }

    // ============ GAME FUNCTIONS ============

    /**
     * @notice Buy tickets for the current game
     * @param referrer The referrer address
     * @param ticketCount The number of tickets to buy
     */
    function buyTicket(
        address referrer,
        uint256 ticketCount
    ) public payable nonReentrant {
        _requireGameActive(ticketCount);
        uint256 currentGameId = _getCurrentGameId(getGameStorage());

        // IMPROVED FLOW: Automatically handle expired games and start new ones
        currentGameId = _handleGameState(getGameStorage(), currentGameId);

        // After handling game state, ensure we have a valid active game
        _requireCurrentGameActive(currentGameId);
        _updatePlayerInfoOptimized(msg.sender, ticketCount, currentGameId);
        _transferToTreasury(msg.value);
        _processFeeDistributionInternal(msg.value, referrer);
        _emitTicketPurchasedEvents(
            getGameStorage().games[currentGameId].gameNumber,
            ticketCount
        );
    }

    /**
     * @notice Require game to be active
     * @param ticketCount The number of tickets
     */
    function _requireGameActive(uint256 ticketCount) internal view {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        require(gameStorage.isActive, "Game is not active");
        require(ticketCount > 0, "Ticket count must be greater than 0");
        require(
            msg.value == gameStorage.ticketPrice * ticketCount,
            "Wrong amount"
        );
    }

    /**
     * @notice Require current game to be active
     * @param currentGameId The current game ID
     */
    function _requireCurrentGameActive(uint256 currentGameId) internal view {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];
        require(
            currentGame.state == StorageLayout.GameState.ACTIVE,
            "Game not active"
        );
    }

    /**
     * @notice Get current game ID
     * @param gameStorage The game storage
     * @return The current game ID
     */
    function _getCurrentGameId(
        StorageLayout.GameStorage storage gameStorage
    ) internal view returns (uint256) {
        return gameStorage.totalGames > 0 ? gameStorage.totalGames - 1 : 0;
    }

    /**
     * @notice Handle game state transitions
     * @param gameStorage The game storage
     * @param currentGameId The current game ID
     * @return The updated game ID
     */
    function _handleGameState(
        StorageLayout.GameStorage storage gameStorage,
        uint256 currentGameId
    ) internal returns (uint256) {
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // FLOW: init -> buyTicket -> time expired -> checkAndEndGame -> new game began

        // Step 1: If game is WAITING, start a new game
        if (currentGame.state == StorageLayout.GameState.WAITING) {
            _startNewGame();
            return gameStorage.totalGames - 1;
        }

        // Step 2: If game is ACTIVE but time expired, end it and start new game
        if (
            currentGame.state == StorageLayout.GameState.ACTIVE &&
            block.timestamp >= currentGame.endTime
        ) {
            // End the expired game (checkAndEndGame)
            _endCurrentGame(currentGameId);
            // Start a new game (new game began)
            _startNewGame();
            return gameStorage.totalGames - 1;
        }

        // Step 3: Game is still active and not expired, continue with current game
        return currentGameId;
    }

    /**
     * @notice Emit ticket purchased events (라이브러리 이벤트 사용)
     * @param gameNumber The game number
     * @param ticketCount The number of tickets
     */
    function _emitTicketPurchasedEvents(
        uint256 gameNumber,
        uint256 ticketCount
    ) internal {
        for (uint256 i = 0; i < ticketCount; i++) {
            emit LotteryUtils.TicketPurchased(
                msg.sender,
                gameNumber,
                i,
                block.timestamp
            );
        }
    }

    function _processFeeDistributionInternal(
        uint256 ticketAmount,
        address referrer
    ) internal {
        _processFeeDistributionNew(ticketAmount, referrer);
    }

    /**
     * @dev Fee distribution processing (new implementation)
     * @param ticketAmount Ticket price
     * @param referrer Referrer address
     */
    function _processFeeDistributionNew(
        uint256 ticketAmount,
        address referrer
    ) internal {
        uint256 totalFee = _calculateTotalFee(ticketAmount);

        if (totalFee > 0) {
            (
                uint256 referralFee,
                uint256 adLotteryFee,
                uint256 developerFee
            ) = _calculateIndividualFees(ticketAmount);

            _processReferralFeeIfValid(referralFee, referrer);
            _processAdLotteryFeeIfValid(adLotteryFee);
            _processDeveloperFeeIfValid(developerFee);

            emit FeeDistributed(
                referralFee,
                adLotteryFee,
                developerFee,
                block.timestamp
            );
        }
    }

    /**
     * @dev Calculate total fee (라이브러리 사용)
     */
    function _calculateTotalFee(
        uint256 ticketAmount
    ) internal pure returns (uint256) {
        return
            LotteryUtils.calculateTreasuryFee(ticketAmount, TOTAL_FEE_PERCENT);
    }

    /**
     * @dev Calculate individual fees (라이브러리 사용)
     */
    function _calculateIndividualFees(
        uint256 ticketAmount
    )
        internal
        pure
        returns (
            uint256 referralFee,
            uint256 adLotteryFee,
            uint256 developerFee
        )
    {
        referralFee = LotteryUtils.calculateReferralBonus(
            ticketAmount,
            REFERRAL_FEE_PERCENT
        );
        adLotteryFee = LotteryUtils.calculateTreasuryFee(
            ticketAmount,
            AD_LOTTERY_FEE_PERCENT
        );
        developerFee = LotteryUtils.calculateDeveloperFee(
            ticketAmount,
            DEVELOPER_FEE_PERCENT
        );
    }

    /**
     * @dev 유효한 경우 리퍼럴 수수료 처리 (라이브러리 사용)
     */
    function _processReferralFeeIfValid(
        uint256 referralFee,
        address referrer
    ) internal {
        if (
            LotteryUtils.validateReferrer(referrer, msg.sender) &&
            referralFee > 0
        ) {
            _processReferralReward(referrer, msg.sender);
        }
    }

    /**
     * @dev 유효한 경우 Ad Lottery 수수료 처리
     */
    function _processAdLotteryFeeIfValid(uint256 adLotteryFee) internal {
        if (adLotteryFee > 0) {
            _processAdLotteryFee(adLotteryFee);
        }
    }

    /**
     * @dev 유효한 경우 개발자 수수료 처리
     */
    function _processDeveloperFeeIfValid(uint256 developerFee) internal {
        if (developerFee > 0) {
            _processDeveloperFee(developerFee);
        }
    }

    /**
     * @dev 추천 수수료 처리
     */
    function _processReferralFee(
        uint256 referralFee,
        address referrer
    ) internal {
        if (
            referralFee > 0 && referrer != address(0) && referrer != msg.sender
        ) {
            _processReferralReward(referrer, msg.sender);
        }
    }

    /**
     * @dev 광고 복권 수수료 처리
     */
    function _processAdLotteryFeeInternal(uint256 adLotteryFee) internal {
        if (adLotteryFee > 0) {
            _processAdLotteryFee(adLotteryFee);
        }
    }

    function _calculateFees(
        uint256 ticketAmount
    )
        internal
        pure
        returns (
            uint256 referralFee,
            uint256 adLotteryFee,
            uint256 developerFee
        )
    {
        referralFee = (ticketAmount * REFERRAL_FEE_PERCENT) / 100;
        adLotteryFee = (ticketAmount * AD_LOTTERY_FEE_PERCENT) / 100;
        developerFee = (ticketAmount * DEVELOPER_FEE_PERCENT) / 100;
    }

    /**
     * @dev 플레이어 정보 업데이트 (가스 최적화)
     * @notice O(1) 시간 복잡도로 플레이어 중복 체크를 수행합니다
     * @param player 플레이어 주소
     * @param ticketCount 티켓 수
     */
    function _updatePlayerInfoOptimized(
        address player,
        uint256 ticketCount,
        uint256 gameId
    ) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage currentGame = gameStorage.games[gameId];

        _updateTicketCount(gameStorage, player, ticketCount);
        _updatePlayerInfo(player, ticketCount, msg.value);
        _updatePlayerList(currentGame, gameStorage, player);
        currentGame.jackpot = _updateJackpot(
            currentGame.jackpot,
            ticketCount,
            gameStorage.ticketPrice
        );
    }

    /**
     * @dev 플레이어 정보 업데이트
     */
    function _updatePlayerInfo(
        address player,
        uint256 ticketCount,
        uint256 amount
    ) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.PlayerInfo storage playerInfo = gameStorage.playerInfo[
            player
        ];

        playerInfo.ticketCount += ticketCount;
        playerInfo.lastPurchaseTime = block.timestamp;
        playerInfo.totalSpent += amount;
    }

    /**
     * @dev 티켓 수 업데이트
     */
    function _updateTicketCount(
        StorageLayout.GameStorage storage gameStorage,
        address player,
        uint256 ticketCount
    ) internal {
        uint256 currentTicketCount = gameStorage.playerTicketCount[player];
        require(
            currentTicketCount + ticketCount >= currentTicketCount,
            "Ticket count overflow"
        );
        gameStorage.playerTicketCount[player] =
            currentTicketCount +
            ticketCount;
    }

    /**
     * @dev 플레이어 리스트 업데이트
     */
    function _updatePlayerList(
        StorageLayout.Game storage currentGame,
        StorageLayout.GameStorage storage gameStorage,
        address player
    ) internal {
        bool isNewPlayer = StorageOptimizer.addUniquePlayerOptimized(
            currentGame.players,
            currentGame.playerExists,
            player
        );

        if (isNewPlayer) {
            require(
                gameStorage.totalPlayers + 1 >= gameStorage.totalPlayers,
                "Total players overflow"
            );
            require(
                currentGame.playerCount + 1 >= currentGame.playerCount,
                "Player count overflow"
            );
            gameStorage.totalPlayers++;
            currentGame.playerCount += 1;
        }
    }

    /**
     * @dev 잭팟 업데이트 (라이브러리 사용)
     */
    function _updateJackpot(
        uint256 jackpot,
        uint256 ticketCount,
        uint256 ticketPrice
    ) internal pure returns (uint256) {
        uint256 totalValue = LotteryUtils.calculateTotalValue(
            ticketPrice,
            ticketCount
        );
        uint256 totalFee = LotteryUtils.calculateTreasuryFee(
            totalValue,
            TOTAL_FEE_PERCENT
        );
        uint256 jackpotIncrease = totalValue - totalFee; // 90% of total value after 10% fee deduction
        return jackpot + jackpotIncrease;
    }

    /**
     * @dev 새 게임 초기화 (라이브러리 사용)
     */
    function _initializeNewGame(
        uint256 newGameId,
        uint256 gameDuration
    )
        internal
        view
        returns (uint256, uint256, uint256, StorageLayout.GameState)
    {
        uint256 gameNumber = newGameId;
        uint256 startTime = block.timestamp;
        uint256 endTime = LotteryUtils.calculateGameEndTime(
            startTime,
            gameDuration
        );
        StorageLayout.GameState state = StorageLayout.GameState.ACTIVE;
        return (gameNumber, startTime, endTime, state);
    }

    /**
     * @dev 새 게임 이벤트 발생 (라이브러리 이벤트 사용)
     */
    function _emitNewGameEvents(uint256 newGameId) internal {
        emit GameStateChanged(
            newGameId,
            StorageLayout.GameState.ACTIVE,
            block.timestamp
        );

        // 라이브러리 이벤트 사용
        emit LotteryUtils.TicketPurchased(
            address(0),
            newGameId,
            999,
            block.timestamp
        );
    }

    /**
     * @dev 플레이어 티켓 수 초기화 (최적화된 버전)
     */
    function _resetPlayerTicketCounts() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        _resetPlayerTickets(gameStorage, currentGame.players);
    }

    function _resetPlayerTicketCountsForGame(uint256 gameId) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = gameStorage.games[gameId];

        _resetPlayerTickets(gameStorage, game.players);
    }

    /**
     * @dev 플레이어 티켓 초기화
     */
    function _resetPlayerTickets(
        StorageLayout.GameStorage storage gameStorage,
        address[] storage players
    ) internal {
        uint256 length = players.length;
        for (uint256 i = 0; i < length; i++) {
            address player = players[i];
            gameStorage.playerTicketCount[player] = 0;
            // Also reset player info for new game
            gameStorage.playerInfo[player].ticketCount = 0;
            gameStorage.playerInfo[player].totalSpent = 0;
            // Keep lastPurchaseTime as it's useful for tracking
        }
    }

    /**
     * @dev 게임 종료 확인 및 처리
     * @notice Public function to manually check and end expired games
     * Can be called by external automation services or manually
     */
    function checkAndEndGame() public {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        if (_shouldEndGame(currentGame)) {
            // End the expired game and start a new one
            _endCurrentGame(currentGameId);
            _startNewGame();
        }
    }

    /**
     * @dev 자동 게임 종료 (누구나 호출 가능)
     * @notice Same as checkAndEndGame but with different name for compatibility
     */
    function autoEndGame() public {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        if (_shouldEndGame(currentGame)) {
            // End the expired game and start a new one
            _endCurrentGame(currentGameId);
            _startNewGame();
        }
    }

    /**
     * @dev 게임 종료 조건 확인 (라이브러리 사용)
     */
    function _shouldEndGame(
        StorageLayout.Game storage currentGame
    ) internal view returns (bool) {
        return
            currentGame.state == StorageLayout.GameState.ACTIVE &&
            block.timestamp >= currentGame.endTime;
    }

    /**
     * @dev 게임 상태 업데이트
     */
    function _updateGameState(uint256 gameId) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage currentGame = gameStorage.games[gameId];

        // DEBUG: Log game state update
        emit GameStateChanged(gameId, currentGame.state, block.timestamp);

        currentGame.state = StorageLayout.GameState.ENDED;
    }

    /**
     * @dev 게임 종료 이벤트 발생 (라이브러리 이벤트 사용)
     */
    function _emitGameEndEvents(
        uint256 gameNumber,
        uint256 jackpot,
        uint256 playerCount,
        address winner
    ) internal {
        // 라이브러리 이벤트 사용
        emit LotteryUtils.WinnerSelected(
            winner,
            gameNumber,
            jackpot,
            block.timestamp
        );

        emit LotteryUtils.GameEnded(
            gameNumber,
            playerCount,
            jackpot,
            block.timestamp
        );

        emit GameStateChanged(
            gameNumber,
            StorageLayout.GameState.ENDED,
            block.timestamp
        );
    }

    /**
     * @dev 승자 선정 (기본 구현)
     */
    function _pickWinner(uint256 gameId) internal virtual returns (address) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage currentGame = gameStorage.games[gameId];

        // DEBUG: Log player count in _pickWinner
        emit GameStateChanged(gameId, currentGame.state, block.timestamp);

        // FIX: Enhanced safety check for corrupted game states
        if (currentGame.players.length == 0) {
            return address(0);
        }

        // FIX: Ensure we always get a winner when there are players
        // The game must have a winner
        return _selectRandomWinner(currentGame.players);
    }

    /**
     * @dev 랜덤 승자 선택 (라이브러리 사용)
     */
    function _selectRandomWinner(
        address[] storage players
    ) internal view returns (address) {
        // FIX: Add comprehensive safety checks to prevent "Invalid range" errors
        require(players.length > 0, "No players in game");
        require(players.length <= type(uint256).max, "Player count too large");

        // If there's only one player, they automatically win
        if (players.length == 1) {
            return players[0];
        }

        // For multiple players, select randomly
        // FIX: Ensure we have at least 2 players before calling enhancedRandomNumberSecure
        require(
            players.length >= 2,
            "Need at least 2 players for random selection"
        );

        uint256 randomIndex = enhancedRandomNumberSecure(
            0,
            players.length - 1,
            block.timestamp
        );

        // FIX: Use direct array access instead of complex calculation
        return players[randomIndex];
    }

    /**
     * @dev 보안 강화된 랜덤 생성
     * @notice 다중 엔트로피 소스를 사용한 보안 강화
     */
    function enhancedRandomNumberSecure(
        uint256 min,
        uint256 max,
        uint256 seed
    ) internal view virtual returns (uint256) {
        require(max > min, "Invalid range");
        require(max - min <= type(uint256).max, "Range too large");

        // 다중 엔트로피 소스 사용
        uint256 entropy = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    block.number,
                    blockhash(block.number - 1),
                    msg.sender,
                    seed,
                    gasleft()
                )
            )
        );

        // 안전한 모듈로 연산
        return min + (entropy % (max - min + 1));
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
    ) internal virtual {
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
    ) internal virtual {
        emit GameSecurityEvent(player, eventType, block.timestamp);
    }

    // ============ TREASURY FUNCTIONS ============

    /**
     * @dev 재무 시스템으로 자금 이체 (개선된 에러 처리)
     */
    function _transferToTreasury(uint256 amount) internal virtual {
        if (amount > 0) {
            if (_isRegistryAvailable()) {
                _processTreasuryTransfer(amount);
            }
        }
    }

    /**
     * @dev Registry 사용 가능 여부 확인
     */
    function _isRegistryAvailable() internal view returns (bool) {
        return address(registry) != address(0);
    }

    /**
     * @dev Treasury 전송 처리
     */
    function _processTreasuryTransfer(uint256 amount) internal {
        try registry.getContract(treasuryName) returns (
            address treasuryAddress
        ) {
            if (treasuryAddress != address(0)) {
                _executeTreasuryDeposit(treasuryAddress, amount);
            }
        } catch {
            // registry에서 컨트랙트를 찾을 수 없는 경우 무시
        }
    }

    /**
     * @notice Execute treasury deposit
     * @param treasuryAddress The treasury address
     * @param amount The amount to deposit
     */
    function _executeTreasuryDeposit(
        address treasuryAddress,
        uint256 amount
    ) internal {
        if (treasuryAddress != address(0) && amount > 0) {
            try
                ITreasuryManager(treasuryAddress).depositFunds(
                    treasuryName,
                    address(this),
                    amount
                )
            {
                emit TreasuryFundsDeposited(amount, block.timestamp);
            } catch Error(string memory reason) {
                emit TreasuryTransferFailed(
                    address(this),
                    amount,
                    reason,
                    block.timestamp
                );
            } catch {
                emit TreasuryTransferFailed(
                    address(this),
                    amount,
                    "Unknown error",
                    block.timestamp
                );
            }
        }
    }

    /**
     * @dev 참조자 유효성 검사
     */
    function _isValidReferrer(
        address referrer,
        address player
    ) internal pure returns (bool) {
        return referrer != address(0) && referrer != player;
    }

    /**
     * @dev 참조자 보상 실행
     */
    function _executeReferralReward(address referrer) internal {
        if (_isRegistryAvailable()) {
            // Calculate referral fee for this transaction
            uint256 referralFee = (msg.value * REFERRAL_FEE_PERCENT) / 100;

            if (referralFee > 0) {
                try
                    CryptolottoReferral(
                        registry.getContract("CryptolottoReferral")
                    ).processReferralReward{value: referralFee}(
                        referrer,
                        referralFee
                    )
                {
                    // Successfully processed referral reward
                } catch {
                    // If referral processing fails, send the fee to treasury as fallback
                    _executeReferralFeeToTreasury(referralFee);
                }
            }
        }
    }

    /**
     * @dev Ad Lottery 수수료 전송
     */
    function _executeAdLotteryFeeTransfer(uint256 amount) internal {
        if (_isRegistryAvailable()) {
            try registry.getContract("CryptolottoAd") returns (
                address adLotteryAddress
            ) {
                if (adLotteryAddress != address(0)) {
                    // Get Ad Lottery treasury name dynamically
                    string memory adLotteryTreasuryName = this
                        .getAdLotteryTreasuryName(adLotteryAddress);

                    // Deposit to Ad Lottery treasury
                    ITreasuryManager(registry.getContract("TreasuryManager"))
                        .depositFunds{value: amount}(
                        adLotteryTreasuryName,
                        address(this),
                        amount
                    );

                    emit AdLotteryFeeCollected(amount, block.timestamp);
                }
            } catch Error(string memory reason) {
                emit TreasuryTransferFailed(
                    address(this),
                    amount,
                    reason,
                    block.timestamp
                );
            } catch {
                emit TreasuryTransferFailed(
                    address(this),
                    amount,
                    "Unknown error",
                    block.timestamp
                );
            }
        }
    }

    /**
     * @dev Get Ad Lottery treasury name from Ad Lottery contract
     * @param adLotteryAddress The Ad Lottery contract address
     * @return The treasury name
     */
    function getAdLotteryTreasuryName(
        address adLotteryAddress
    ) external view returns (string memory) {
        // Call the Ad Lottery contract to get its treasury name
        (bool success, bytes memory data) = adLotteryAddress.staticcall(
            abi.encodeWithSignature("treasuryName()")
        );

        if (success && data.length > 0) {
            return abi.decode(data, (string));
        }

        // Fallback to default if call fails
        return "unique_test_lottery_ad";
    }

    /**
     * @dev Notify Ad Lottery contract about new fee deposit
     * @param amount The fee amount that was deposited
     */
    function _notifyAdLotteryOfNewFee(uint256 amount) internal {
        try registry.getContract("CryptolottoAd") returns (
            address adLotteryAddress
        ) {
            if (adLotteryAddress != address(0)) {
                // Call the Ad Lottery contract to process the new fee
                (bool success, ) = adLotteryAddress.call(
                    abi.encodeWithSignature("processNewFee(uint256)", amount)
                );
                if (!success) {
                    emit TreasuryOperationFailed(
                        "ad_lottery_notification_failed",
                        block.timestamp
                    );
                }
            }
        } catch {
            // If notification fails, continue without error
            emit TreasuryOperationFailed(
                "ad_lottery_notification_failed",
                block.timestamp
            );
        }
    }

    /**
     * @dev Referral 수수료를 Treasury로 전송 (fallback)
     */
    function _executeReferralFeeToTreasury(uint256 amount) internal {
        if (_isRegistryAvailable()) {
            try
                ITreasuryManager(registry.getContract("TreasuryManager"))
                    .depositFunds{value: amount}(
                    treasuryName,
                    address(this),
                    amount
                )
            {
                // Successfully sent to treasury
            } catch Error(string memory reason) {
                emit TreasuryTransferFailed(
                    address(this),
                    amount,
                    reason,
                    block.timestamp
                );
            } catch {
                emit TreasuryTransferFailed(
                    address(this),
                    amount,
                    "Unknown error",
                    block.timestamp
                );
            }
        }
    }

    /**
     * @dev 개발자 수수료 전송
     */
    function _executeDeveloperFeeTransfer(uint256 amount) internal {
        if (_isRegistryAvailable()) {
            try
                ITreasuryManager(registry.getContract("TreasuryManager"))
                    .depositFunds{value: amount}(
                    treasuryName,
                    address(this),
                    amount
                )
            {
                emit DeveloperFeeSent(msg.sender, amount, block.timestamp);
            } catch Error(string memory reason) {
                emit TreasuryTransferFailed(
                    address(this),
                    amount,
                    reason,
                    block.timestamp
                );
            } catch {
                emit TreasuryTransferFailed(
                    address(this),
                    amount,
                    "Unknown error",
                    block.timestamp
                );
            }
        }
    }

    /**
     * @notice Emergency pause the game (라이브러리 사용)
     * @param reason The reason for pausing
     */
    function emergencyPause(string memory reason) public virtual {
        require(
            LotteryUtils.validateEmergencyAction(msg.sender, owner()),
            "Not authorized"
        );
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.isActive = false;
        emit LotteryUtils.EmergencyPaused(msg.sender, reason, block.timestamp);
    }

    /**
     * @notice Emergency resume the game (라이브러리 사용)
     */
    function emergencyResume() public virtual {
        require(
            LotteryUtils.validateEmergencyAction(msg.sender, owner()),
            "Not authorized"
        );
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.isActive = true;
        emit LotteryUtils.EmergencyResumed(msg.sender, block.timestamp);
    }

    /**
     * @notice Get current game jackpot
     * @return The current game jackpot amount
     */
    function getCurrentGameJackpot() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        return gameStorage.games[currentGameId].jackpot;
    }

    /**
     * @notice Get current game state
     * @return The current game state
     */
    function getCurrentGameState()
        public
        view
        returns (StorageLayout.GameState)
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        return gameStorage.games[currentGameId].state;
    }

    /**
     * @notice Get current game number
     * @return The current game number
     */
    function getCurrentGameNumber() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        return gameStorage.games[currentGameId].gameNumber;
    }

    /**
     * @notice Get current game player count
     * @return The current game player count
     */
    function getCurrentGamePlayerCount() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        return gameStorage.games[currentGameId].playerCount;
    }

    /**
     * @notice Get remaining game time (라이브러리 사용)
     * @return The remaining game time in seconds
     */
    function getRemainingGameTime() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];
        if (currentGame.state != StorageLayout.GameState.ACTIVE) {
            return 0;
        }
        return LotteryUtils.calculateTimeRemaining(currentGame.endTime);
    }

    /**
     * @notice Get current game end time
     * @return The current game end time
     */
    function getCurrentGameEndTime() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];
        return currentGame.endTime;
    }

    // ============ COMMON VIEW FUNCTIONS ============

    /**
     * @notice Get contract balance
     * @return The contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get player information
     * @param player The player address
     * @return ticketCount The number of tickets purchased
     * @return lastPurchaseTime The last purchase time
     * @return totalSpent The total amount spent
     */
    function getPlayerInfo(
        address player
    )
        public
        view
        virtual
        returns (
            uint256 ticketCount,
            uint256 lastPurchaseTime,
            uint256 totalSpent
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.PlayerInfo storage playerInfo = gameStorage.playerInfo[
            player
        ];
        return (
            playerInfo.ticketCount,
            playerInfo.lastPurchaseTime,
            playerInfo.totalSpent
        );
    }

    /**
     * @notice Get game configuration
     * @return ticketPrice The ticket price
     * @return gameDuration The game duration
     * @return maxTicketsPerPlayer The maximum tickets per player
     * @return isActive Whether the game is active
     */
    function getGameConfig()
        public
        view
        virtual
        returns (
            uint256 ticketPrice,
            uint256 gameDuration,
            uint256 maxTicketsPerPlayer,
            bool isActive
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        return (
            gameStorage.ticketPrice,
            gameStorage.gameDuration,
            gameStorage.maxTicketsPerPlayer,
            gameStorage.isActive
        );
    }

    // ============ COMMON ADMIN FUNCTIONS ============

    /**
     * @notice Reset player cooldown
     * @param player The player address
     */
    function resetPlayerCooldown(address player) external virtual onlyOwner {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.PlayerInfo storage playerInfo = gameStorage.playerInfo[
            player
        ];
        playerInfo.lastPurchaseTime = 0;
        emit PlayerCooldownReset(player, block.timestamp);
    }

    /**
     * @notice Set test mode
     * @param enabled Whether test mode is enabled
     */
    function setTestMode(bool enabled) external virtual onlyOwner {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.testMode = enabled;
        emit TestModeSet(enabled, block.timestamp);
    }

    /**
     * @notice Set purchase cooldown
     * @param newCooldown The new cooldown time
     */
    function setPurchaseCooldown(
        uint256 newCooldown
    ) external virtual onlyOwner {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.purchaseCooldown = newCooldown;
        emit PurchaseCooldownSet(newCooldown, block.timestamp);
    }

    /**
     * @notice Set registry address
     * @param registryAddress The registry address
     */
    function setRegistry(address registryAddress) external virtual onlyOwner {
        require(registryAddress != address(0), "Invalid registry address");
        registry = ContractRegistry(registryAddress);
        emit RegistrySet(registryAddress, block.timestamp);
    }

    /**
     * @notice Set treasury name
     * @param _treasuryName The treasury name
     */
    function setTreasuryName(
        string memory _treasuryName
    ) external virtual onlyOwner {
        treasuryName = _treasuryName;
        emit TreasuryNameSet(_treasuryName, block.timestamp);
    }

    // ============ COMMON INTERNAL FUNCTIONS ============

    /**
     * @notice End current game
     */
    function _endGame() internal virtual {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        if (currentGame.state == StorageLayout.GameState.ACTIVE) {
            _updateGameState(currentGameId);
            address winner = _pickWinner(currentGameId);
            _processWinnerPayout(winner, currentGame.jackpot);
            _processFounderDistribution(currentGame.jackpot);
            _updateGameStats(
                winner,
                currentGame.playerCount,
                currentGame.jackpot,
                0
            );
            _emitGameEndEvents(
                currentGame.gameNumber,
                currentGame.jackpot,
                currentGame.playerCount,
                winner
            );
        }
    }

    /**
     * @notice Buy ticket internal function (라이브러리 사용)
     * @param partner The partner address
     * @param ticketCount The number of tickets
     */
    function _buyTicketInternal(
        address partner,
        uint256 ticketCount
    ) internal virtual {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        currentGameId = _handleGameState(gameStorage, currentGameId);
        _requireCurrentGameActive(currentGameId);

        // 라이브러리를 사용한 검증
        require(
            LotteryUtils.validateTicketCount(ticketCount),
            "Invalid ticket count"
        );

        _updatePlayerInfoOptimized(msg.sender, ticketCount, currentGameId);
        _transferToTreasury(msg.value);
        _processFeeDistributionInternal(msg.value, partner);
        _emitTicketPurchasedEvents(
            gameStorage.games[currentGameId].gameNumber,
            ticketCount
        );
    }

    /**
     * @notice Authorize upgrade (UUPS)
     * @param newImplementation The new implementation address
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

    // ============ FALLBACK FUNCTIONS ============

    /**
     * @notice Fallback function to buy tickets
     */
    fallback() external payable {
        // Buy 1 ticket with the sent value
        buyTicket(address(0), 1);
    }

    /**
     * @notice Receive function
     */
    receive() external payable {
        // Buy 1 ticket with the sent value
        buyTicket(address(0), 1);
    }

    // ============ EVENTS ============

    event PlayerCooldownReset(address indexed player, uint256 timestamp);
    event TestModeSet(bool enabled, uint256 timestamp);
    event PurchaseCooldownSet(uint256 cooldown, uint256 timestamp);
    event RegistrySet(address indexed registry, uint256 timestamp);
    event TreasuryNameSet(string treasuryName, uint256 timestamp);
    event WinnerPayout(
        address indexed winner,
        uint256 amount,
        uint256 timestamp
    );
    event FounderDistribution(
        address indexed founder,
        uint256 amount,
        uint256 timestamp
    );
    event GameStatsUpdated(
        uint256 totalGames,
        uint256 totalPlayers,
        uint256 totalPayouts,
        uint256 timestamp
    );

    // ============ GAME STATE RECOVERY FUNCTIONS ============

    /**
     * @notice Recover corrupted game state - anyone can call this
     * @dev This function fixes corrupted game states and prevents "Invalid range" errors
     */
    function recoverGameState() public {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // Check if game is in corrupted state (ACTIVE but time expired)
        if (
            currentGame.state == StorageLayout.GameState.ACTIVE &&
            block.timestamp >= currentGame.endTime
        ) {
            _forceEndCorruptedGame(currentGameId);
            _startNewGame();
            emit GameStateRecovered(currentGameId, block.timestamp);
        }
    }

    /**
     * @notice Force end a corrupted game state
     * @param gameId The game ID to force end
     */
    function _forceEndCorruptedGame(uint256 gameId) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = gameStorage.games[gameId];

        // Mark game as ended
        game.state = StorageLayout.GameState.ENDED;

        // Reset player ticket counts for the current game
        _resetPlayerTicketCountsForGame(gameId);

        // Emit game ended event
        emit GameStateChanged(
            gameId,
            StorageLayout.GameState.ENDED,
            block.timestamp
        );
    }

    /**
     * @notice Validate game state and return detailed information
     * @return isValid Whether the game state is valid
     * @return reason Reason for invalidity (if any)
     * @return currentState Current game state
     * @return timeExpired Whether game time has expired
     */
    function validateGameState()
        public
        view
        returns (
            bool isValid,
            string memory reason,
            uint8 currentState,
            bool timeExpired
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        timeExpired = block.timestamp >= currentGame.endTime;

        // Check for corrupted states
        if (
            currentGame.state == StorageLayout.GameState.ACTIVE && timeExpired
        ) {
            return (false, "Game is active but time expired", 1, timeExpired); // 1 = ACTIVE
        }

        if (
            currentGame.state == StorageLayout.GameState.ENDED && !timeExpired
        ) {
            return (
                false,
                "Game is ended but time not expired",
                2,
                timeExpired
            ); // 2 = ENDED
        }

        return (
            true,
            "Game state is valid",
            uint8(currentGame.state),
            timeExpired
        );
    }

    /**
     * @notice Enhanced auto end game with corruption detection
     * @dev This function includes safety checks to prevent "Invalid range" errors
     */
    function safeAutoEndGame() public {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // Safety check: ensure there are players before trying to end game
        if (currentGame.players.length == 0) {
            // No players, just start a new game
            _startNewGame();
            return;
        }

        if (_shouldEndGame(currentGame)) {
            _endCurrentGame(currentGameId);
            _startNewGame();
        }
    }

    // ============ ENHANCED EVENTS ============

    event GameStateRecovered(uint256 indexed gameId, uint256 timestamp);
}
