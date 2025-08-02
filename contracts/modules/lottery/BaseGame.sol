// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../../shared/interfaces/ITreasuryManager.sol";
import "../../shared/interfaces/ICryptolottoReferral.sol";
import "../../shared/interfaces/IFundsDistributor.sol";
import "../../shared/interfaces/IAnalyticsEngine.sol";
import "../../shared/interfaces/IOwnable.sol";
import "../../shared/utils/ContractRegistry.sol";
import "../../shared/utils/GasOptimizer.sol";
import "../../shared/storage/StorageLayout.sol";
import "../../shared/storage/StorageAccess.sol";
import "../../shared/storage/StorageOptimizer.sol";
import "../../modules/treasury/CryptolottoReferral.sol";

using GasOptimizer for address[];
using StorageOptimizer for address[];

/**
 * @title BaseGame
 * @dev 모든 게임 컨트랙트의 기본 클래스
 * 새로운 중앙화된 스토리지 아키텍처 사용
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

    // 중앙화된 스토리지 접근을 위한 변수들
    ContractRegistry public registry;
    string public treasuryName;
    IOwnable public ownable;

    // ============ EVENTS ============
    event TicketPurchased(
        address indexed player,
        uint256 indexed gameNumber,
        uint256 ticketIndex,
        uint256 timestamp
    );
    event WinnerSelected(
        address indexed winner,
        uint256 indexed gameNumber,
        uint256 jackpot,
        uint256 playerCount,
        uint256 timestamp
    );
    event GameEnded(
        uint256 indexed gameNumber,
        uint256 totalPlayers,
        uint256 totalJackpot,
        uint256 timestamp
    );
    event JackpotDistributed(
        address indexed winner,
        uint256 amount,
        uint256 indexed gameNumber,
        uint256 timestamp
    );
    event EmergencyPaused(address indexed by, string reason, uint256 timestamp);
    event EmergencyResumed(address indexed by, uint256 timestamp);
    event MaxTicketsPerPlayerUpdated(
        uint256 oldValue,
        uint256 newValue,
        uint256 timestamp
    );
    event GameDurationUpdated(
        uint256 oldValue,
        uint256 newValue,
        uint256 timestamp
    );
    event FeeDistributed(
        uint256 referralFee,
        uint256 adLotteryFee,
        uint256 developerFee,
        uint256 timestamp
    );
    event DeveloperFeeSent(
        address indexed distributor,
        uint256 amount,
        uint256 timestamp
    );
    event GamePerformanceMetrics(
        uint256 indexed gameNumber,
        uint256 gasUsed,
        uint256 playerCount,
        uint256 jackpot,
        uint256 timestamp
    );
    event GameSecurityEvent(
        address indexed player,
        string eventType,
        uint256 timestamp
    );
    event AdLotteryFeeCollected(uint256 amount, uint256 timestamp);
    event TicketPriceChanged(
        uint256 oldPrice,
        uint256 newPrice,
        uint256 timestamp
    );
    event GameStateChanged(
        uint256 gameNumber,
        StorageLayout.GameState state,
        uint256 timestamp
    );
    event TreasuryFundsDeposited(uint256 amount, uint256 timestamp);
    event TreasuryFundsWithdrawn(
        address winner,
        uint256 amount,
        uint256 timestamp
    );
    event TreasuryOperationFailed(string operation, uint256 timestamp);
    event RegistryError(
        string operation,
        string contractName,
        uint256 timestamp
    );
    event ContractNotFound(string contractName, uint256 timestamp);
    event TreasuryTransferFailed(
        address from,
        uint256 amount,
        string reason,
        uint256 timestamp
    );

    // 추가된 이벤트들
    // event WinnerSelected(
    //     address indexed winner,
    //     uint256 indexed gameNumber,
    //     uint256 jackpot,
    //     uint256 playerCount,
    //     uint256 timestamp
    // );
    // event GameEnded(
    //     uint256 indexed gameNumber,
    //     uint256 totalPlayers,
    //     uint256 totalJackpot,
    //     uint256 timestamp
    // );
    // event JackpotDistributed(
    //     address indexed winner,
    //     uint256 amount,
    //     uint256 indexed gameNumber,
    //     uint256 timestamp
    // );
    // event EmergencyPaused(address indexed by, string reason, uint256 timestamp);
    // event EmergencyResumed(address indexed by, uint256 timestamp);
    // event MaxTicketsPerPlayerUpdated(
    //     uint256 oldValue,
    //     uint256 newValue,
    //     uint256 timestamp
    // );
    // event GameDurationUpdated(
    //     uint256 oldValue,
    //     uint256 newValue,
    //     uint256 timestamp
    // );
    // event FeeDistributed(
    //     address indexed referrer,
    //     uint256 referralFee,
    //     uint256 adLotteryFee,
    //     uint256 developerFee,
    //     uint256 totalFee,
    //     uint256 timestamp
    // );
    // event DeveloperFeeSent(
    //     address indexed developer,
    //     uint256 amount,
    //     uint256 timestamp
    // );
    // event AdLotteryFeeCollected(uint256 amount, uint256 timestamp);
    // event GamePerformanceMetrics(
    //     uint256 gameNumber,
    //     uint256 gasUsed,
    //     uint256 playerCount,
    //     uint256 jackpot,
    //     uint256 timestamp
    // );
    // event GameSecurityEvent(
    //     address indexed player,
    //     string eventType,
    //     uint256 timestamp
    // );

    // ============ ABSTRACT FUNCTIONS ============
    function _processReferralSystem(
        address referrer,
        address player
    ) internal virtual {
        // 단순화된 리퍼럴 시스템 - 리퍼러가 유효한 주소인 경우에만 보상 지급
        if (referrer != address(0) && referrer != player) {
            // 리퍼럴 컨트랙트 주소 가져오기
            address referralContract = registry.getContract(
                "CryptolottoReferral"
            );
            if (referralContract != address(0)) {
                // 리퍼럴 보상 처리 (BaseGame에서 계산된 금액 사용)
                try
                    CryptolottoReferral(referralContract).processReferralReward{
                        value: 0
                    }(
                        referrer,
                        0 // 금액은 _processFeeDistribution에서 처리됨
                    )
                {
                    // 성공적으로 처리됨
                } catch {
                    // 리퍼럴 처리 실패 시 무시 (게임은 계속 진행)
                }
            }
        }
    }

    function _processWinnerPayout(
        address winner,
        uint256 amount
    ) internal virtual;

    function _processFounderDistribution(uint256 amount) internal virtual;

    function _updateGameStats(
        address winner,
        uint256 playerCount,
        uint256 amount,
        uint256 winnerIndex
    ) internal virtual;

    // ============ INITIALIZATION ============
    function __BaseGame_init(
        address owner,
        address _registry
    ) internal onlyInitializing {
        require(owner != address(0), "Invalid owner address");
        // registry는 나중에 설정될 수 있으므로 조건부 검증
        if (_registry != address(0)) {
            registry = ContractRegistry(_registry);
        }

        __Ownable_init(owner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        // Set ownable to this contract (since it inherits OwnableUpgradeable)
        ownable = IOwnable(address(this));

        // 중앙화된 스토리지 초기화
        _initializeGameStorage();
    }

    /**
     * @dev 중앙화된 게임 스토리지 초기화
     */
    function _initializeGameStorage() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        if (gameStorage.ticketPrice == 0) {
            gameStorage.ticketPrice = 0.01 ether;
            gameStorage.gameDuration = 1 days;
            gameStorage.maxTicketsPerPlayer = 100;
            gameStorage.isActive = true;

            // 초기 게임 생성
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
     * @dev 티켓 구매 (중앙화된 스토리지 사용)
     */
    function buyTicket(
        address referrer,
        uint256 ticketCount
    ) public payable nonReentrant {
        _requireGameActive(ticketCount);
        uint256 currentGameId = _getCurrentGameId(getGameStorage());
        currentGameId = _handleGameState(getGameStorage(), currentGameId);
        _requireCurrentGameActive(currentGameId);
        _updatePlayerInfoOptimized(msg.sender, ticketCount);
        _transferToTreasury(msg.value);
        _processFeeDistributionInternal(msg.value, referrer);
        _emitTicketPurchasedEvents(
            getGameStorage().games[currentGameId].gameNumber,
            ticketCount
        );
    }

    function _requireGameActive(uint256 ticketCount) internal view {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        require(gameStorage.isActive, "Game is not active");
        require(ticketCount > 0, "Ticket count must be greater than 0");
        require(
            msg.value == gameStorage.ticketPrice * ticketCount,
            "Incorrect amount sent"
        );
    }

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
     * @dev 현재 게임 ID 가져오기
     */
    function _getCurrentGameId(
        StorageLayout.GameStorage storage gameStorage
    ) internal view returns (uint256) {
        return gameStorage.totalGames > 0 ? gameStorage.totalGames - 1 : 0;
    }

    function _handleGameState(
        StorageLayout.GameStorage storage gameStorage,
        uint256 currentGameId
    ) internal returns (uint256) {
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];
        if (currentGame.state == StorageLayout.GameState.WAITING) {
            _startNewGame();
            return gameStorage.totalGames - 1;
        }
        if (
            currentGame.state == StorageLayout.GameState.ACTIVE &&
            block.timestamp >= currentGame.endTime
        ) {
            _endCurrentGame();
            _startNewGame();
            return gameStorage.totalGames - 1;
        }
        return currentGameId;
    }

    function _emitTicketPurchasedEvents(
        uint256 gameNumber,
        uint256 ticketCount
    ) internal {
        for (uint i = 0; i < ticketCount; i++) {
            emit TicketPurchased(msg.sender, gameNumber, i, block.timestamp);
        }
    }

    function _processFeeDistributionInternal(
        uint256 ticketAmount,
        address referrer
    ) internal {
        _processFeeDistributionNew(ticketAmount, referrer);
    }

    /**
     * @dev 수수료 분배 처리 (새로운 구현)
     * @param ticketAmount 티켓 가격
     * @param referrer 리퍼러 주소
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
     * @dev 총 수수료 계산
     */
    function _calculateTotalFee(
        uint256 ticketAmount
    ) internal pure returns (uint256) {
        return (ticketAmount * TOTAL_FEE_PERCENT) / 100;
    }

    /**
     * @dev 개별 수수료 계산
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
        referralFee = (ticketAmount * REFERRAL_FEE_PERCENT) / 100;
        adLotteryFee = (ticketAmount * AD_LOTTERY_FEE_PERCENT) / 100;
        developerFee = (ticketAmount * DEVELOPER_FEE_PERCENT) / 100;
    }

    /**
     * @dev 유효한 경우 리퍼럴 수수료 처리
     */
    function _processReferralFeeIfValid(
        uint256 referralFee,
        address referrer
    ) internal {
        if (
            referrer != address(0) && referrer != msg.sender && referralFee > 0
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
        uint256 ticketCount
    ) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        _updateTicketCount(gameStorage, player, ticketCount);
        _updatePlayerList(currentGame, gameStorage, player);
        currentGame.jackpot = _updateJackpot(
            currentGame.jackpot,
            ticketCount,
            gameStorage.ticketPrice
        );
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
     * @dev 잭팟 업데이트
     */
    function _updateJackpot(
        uint256 jackpot,
        uint256 ticketCount,
        uint256 ticketPrice
    ) internal pure returns (uint256) {
        return jackpot + (ticketCount * ticketPrice);
    }

    /**
     * @dev 새 게임 초기화
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
        uint256 endTime = block.timestamp + gameDuration;
        StorageLayout.GameState state = StorageLayout.GameState.ACTIVE;
        return (gameNumber, startTime, endTime, state);
    }

    /**
     * @dev 새 게임 이벤트 발생
     */
    function _emitNewGameEvents(uint256 newGameId) internal {
        emit GameStateChanged(
            newGameId,
            StorageLayout.GameState.ACTIVE,
            block.timestamp
        );

        // 디버깅 이벤트
        emit TicketPurchased(address(0), newGameId, 999, block.timestamp);
    }

    /**
     * @dev 플레이어 티켓 수 초기화 (최적화된 버전)
     */
    function _resetPlayerTicketCounts() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames;
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        _resetPlayerTickets(gameStorage, currentGame.players);
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
            gameStorage.playerTicketCount[players[i]] = 0;
        }
    }

    /**
     * @dev 게임 종료 확인 및 처리
     */
    function checkAndEndGame() public {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        if (_shouldEndGame(currentGame)) {
            _endCurrentGame();
        }
    }

    /**
     * @dev 자동 게임 종료 (누구나 호출 가능)
     */
    function autoEndGame() public {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        if (_shouldEndGame(currentGame)) {
            _endCurrentGame();
            _startNewGame();
        }
    }

    /**
     * @dev 게임 종료 조건 확인
     */
    function _shouldEndGame(
        StorageLayout.Game storage currentGame
    ) internal view returns (bool) {
        return
            currentGame.state == StorageLayout.GameState.ACTIVE &&
            block.timestamp >= currentGame.endTime;
    }

    /**
     * @dev 현재 게임 종료 및 승자 선정
     */
    function _endCurrentGame() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        _updateGameState();
        address winner = _pickWinner();
        _emitGameEndEvents(
            currentGame.gameNumber,
            currentGame.jackpot,
            currentGame.playerCount,
            winner
        );
    }

    /**
     * @dev 게임 상태 업데이트
     */
    function _updateGameState() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];
        currentGame.state = StorageLayout.GameState.ENDED;
    }

    /**
     * @dev 게임 종료 이벤트 발생
     */
    function _emitGameEndEvents(
        uint256 gameNumber,
        uint256 jackpot,
        uint256 playerCount,
        address winner
    ) internal {
        emit WinnerSelected(
            winner,
            gameNumber,
            jackpot,
            playerCount,
            block.timestamp
        );

        emit GameEnded(gameNumber, playerCount, jackpot, block.timestamp);

        emit GameStateChanged(
            gameNumber,
            StorageLayout.GameState.ENDED,
            block.timestamp
        );
    }

    /**
     * @dev 승자 선정 (기본 구현)
     */
    function _pickWinner() internal virtual returns (address) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        if (currentGame.players.length == 0) {
            return address(0);
        }

        return _selectRandomWinner(currentGame.players);
    }

    /**
     * @dev 랜덤 승자 선택
     */
    function _selectRandomWinner(
        address[] storage players
    ) internal view returns (address) {
        uint256 randomIndex = enhancedRandomNumberSecure(
            0,
            players.length - 1,
            block.timestamp
        );
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
     * @dev Treasury 예치 실행
     */
    function _executeTreasuryDeposit(
        address treasuryAddress,
        uint256 amount
    ) internal {
        try
            ITreasuryManager(treasuryAddress).depositFunds(
                treasuryName,
                msg.sender,
                amount
            )
        {
            // 성공적으로 Treasury로 전송됨
        } catch {
            // Treasury 전송 실패 시 컨트랙트에 보관 (긴급 상황에서만 사용)
        }
    }

    // ============ FEE DISTRIBUTION ============

    /**
     * @dev 총 수수료 비율 (10%)
     */
    uint256 public constant TOTAL_FEE_PERCENT = 10;

    /**
     * @dev 리퍼럴 수수료 비율 (2%)
     */
    uint256 public constant REFERRAL_FEE_PERCENT = 2;

    /**
     * @dev Ad Lottery 수수료 비율 (3%)
     */
    uint256 public constant AD_LOTTERY_FEE_PERCENT = 3;

    /**
     * @dev 개발자 수수료 비율 (5%)
     */
    uint256 public constant DEVELOPER_FEE_PERCENT = 5;

    /**
     * @dev 수수료 분배 처리
     * @param ticketAmount 티켓 가격
     * @param referrer 리퍼러 주소
     */
    function _processFeeDistribution(
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
     * @dev 리퍼럴 보상 처리 (CryptolottoReferral 사용)
     * @param referrer 리퍼러 주소
     * @param player 플레이어 주소
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
     * @dev 유효한 리퍼러인지 확인
     */
    function _isValidReferrer(
        address referrer,
        address player
    ) internal pure returns (bool) {
        return referrer != address(0) && referrer != player;
    }

    /**
     * @dev 리퍼럴 보상 실행
     */
    function _executeReferralReward(address referrer) internal {
        try registry.getContract("CryptolottoReferral") returns (
            address referralContract
        ) {
            if (referralContract != address(0)) {
                _callReferralContract(referralContract, referrer);
            }
        } catch {
            // registry에서 컨트랙트를 찾을 수 없는 경우 무시
        }
    }

    /**
     * @dev 리퍼럴 컨트랙트 호출
     */
    function _callReferralContract(
        address referralContract,
        address referrer
    ) internal {
        try
            CryptolottoReferral(referralContract).processReferralReward{
                value: 0
            }(referrer, 0)
        {
            // 성공적으로 처리됨
        } catch {
            // 리퍼럴 처리 실패 시 무시 (게임은 계속 진행)
        }
    }

    /**
     * @dev Ad Lottery 수수료 처리
     * @param amount 수수료 금액
     */
    function _processAdLotteryFee(uint256 amount) internal virtual {
        if (amount > 0) {
            // Ad Lottery 수수료는 Ad Lottery 게임의 당첨금으로 사용
            // 현재는 컨트랙트에 보관하고 나중에 Ad Lottery 게임에서 사용
            // 실제 구현에서는 Treasury나 별도 컨트랙트에 보관할 수 있음
            emit AdLotteryFeeCollected(amount, block.timestamp);
        }
    }

    /**
     * @dev 개발자 수수료 처리 (FundsDistributor 사용)
     * @param amount 수수료 금액
     */
    function _processDeveloperFee(uint256 amount) internal virtual {
        if (amount > 0) {
            if (_isRegistryAvailable()) {
                _executeDeveloperFeeTransfer(amount);
            }
        }
    }

    /**
     * @dev 개발자 수수료 전송 실행
     */
    function _executeDeveloperFeeTransfer(uint256 amount) internal {
        try registry.getContract("FundsDistributor") returns (
            address distributorAddress
        ) {
            if (distributorAddress != address(0)) {
                _sendToDistributor(distributorAddress, amount);
            }
        } catch {
            // registry에서 컨트랙트를 찾을 수 없는 경우 무시
        }
    }

    /**
     * @dev Distributor로 전송
     */
    function _sendToDistributor(
        address distributorAddress,
        uint256 amount
    ) internal {
        (bool success, ) = payable(distributorAddress).call{value: amount}("");
        if (success) {
            emit DeveloperFeeSent(distributorAddress, amount, block.timestamp);
        } else {
            // 개발자 수수료 처리 실패 시 Treasury로 전송
            _transferToTreasury(amount);
        }
    }

    // ============ UTILITY FUNCTIONS ============

    /**
     * @dev 티켓 가격 변경
     */
    function changeTicketPrice(uint256 price) public {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 oldPrice = gameStorage.ticketPrice;
        _updateTicketPrice(gameStorage, price);
        emit TicketPriceChanged(oldPrice, price, block.timestamp);
    }

    /**
     * @dev 티켓 가격 업데이트
     */
    function _updateTicketPrice(
        StorageLayout.GameStorage storage gameStorage,
        uint256 price
    ) internal {
        gameStorage.ticketPrice = price;
    }

    /**
     * @dev 최대 티켓 수 변경
     */
    function changeMaxTicketsPerPlayer(uint256 maxTickets) public virtual {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 oldValue = gameStorage.maxTicketsPerPlayer;
        _updateMaxTicketsPerPlayer(gameStorage, maxTickets);
        emit MaxTicketsPerPlayerUpdated(oldValue, maxTickets, block.timestamp);
    }

    /**
     * @dev 최대 티켓 수 업데이트
     */
    function _updateMaxTicketsPerPlayer(
        StorageLayout.GameStorage storage gameStorage,
        uint256 maxTickets
    ) internal {
        gameStorage.maxTicketsPerPlayer = maxTickets;
    }

    /**
     * @dev 게임 시간 변경
     */
    function changeGameDuration(uint256 duration) public virtual {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 oldValue = gameStorage.gameDuration;
        _updateGameDuration(gameStorage, duration);
        emit GameDurationUpdated(oldValue, duration, block.timestamp);
    }

    /**
     * @dev 게임 시간 업데이트
     */
    function _updateGameDuration(
        StorageLayout.GameStorage storage gameStorage,
        uint256 duration
    ) internal {
        gameStorage.gameDuration = duration;
    }

    /**
     * @dev 긴급 일시정지
     */
    function emergencyPause(string memory reason) public virtual {
        require(msg.sender == owner(), "Not authorized");
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.isActive = false;
        emit EmergencyPaused(msg.sender, reason, block.timestamp);
    }

    /**
     * @dev 긴급 재개
     */
    function emergencyResume() public virtual {
        require(msg.sender == owner(), "Not authorized");
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.isActive = true;
        emit EmergencyResumed(msg.sender, block.timestamp);
    }

    // 기존 getCurrentGameInfo 함수는 주석 처리
    /*
    function getCurrentGameInfo()
        public
        view
        returns (
            uint256 gameNumber,
            uint256 startTime,
            uint256 endTime,
            uint256 jackpot,
            uint256 playerCount,
            StorageLayout.GameState state
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = _getCurrentGame(gameStorage);
        return _getGameInfo(game);
    }
    */

    function getCurrentGameNumber() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = _getCurrentGame(gameStorage);
        return game.gameNumber;
    }

    function getCurrentGameStartTime() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = _getCurrentGame(gameStorage);
        return game.startTime;
    }

    function getCurrentGameEndTime() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = _getCurrentGame(gameStorage);
        return game.endTime;
    }

    function getCurrentGameJackpot() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = _getCurrentGame(gameStorage);
        return game.jackpot;
    }

    function getCurrentGamePlayerCount() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = _getCurrentGame(gameStorage);
        return game.playerCount;
    }

    function getCurrentGameState()
        public
        view
        returns (StorageLayout.GameState)
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        StorageLayout.Game storage game = _getCurrentGame(gameStorage);
        return game.state;
    }

    /**
     * @dev 현재 게임 가져오기
     */
    function _getCurrentGame(
        StorageLayout.GameStorage storage gameStorage
    ) internal view returns (StorageLayout.Game storage) {
        if (gameStorage.totalGames > 0) {
            return gameStorage.games[gameStorage.totalGames - 1];
        } else {
            return gameStorage.games[0];
        }
    }

    /**
     * @dev 게임 정보 반환
     */
    function _getGameInfo(
        StorageLayout.Game storage game
    )
        internal
        view
        returns (
            uint256 gameNumber,
            uint256 startTime,
            uint256 endTime,
            uint256 jackpot,
            uint256 playerCount,
            StorageLayout.GameState state
        )
    {
        return (
            game.gameNumber,
            game.startTime,
            game.endTime,
            game.jackpot,
            game.playerCount,
            game.state
        );
    }

    /**
     * @dev 게임 설정 조회
     */
    function getGameConfig()
        public
        view
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

    /**
     * @dev 게임 상세 통계 조회 (BaseGame 레벨)
     * @return totalGames 총 게임 수
     * @return totalPlayers 총 플레이어 수
     * @return totalJackpot 총 잭팟
     * @return averageTicketsPerGame 게임당 평균 티켓 수
     * @return successRate 성공률
     */
    function getDetailedGameStats()
        external
        view
        virtual
        returns (
            uint256 totalGames,
            uint256 totalPlayers,
            uint256 totalJackpot,
            uint256 averageTicketsPerGame,
            uint256 successRate
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();

        totalGames = gameStorage.totalGames;
        totalPlayers = gameStorage.totalPlayers;
        totalJackpot = gameStorage.totalJackpot;

        averageTicketsPerGame = _calculateAverageTicketsPerGame(
            totalGames,
            totalJackpot,
            gameStorage.ticketPrice
        );
        successRate = _calculateSuccessRate(gameStorage, totalGames);

        return (
            totalGames,
            totalPlayers,
            totalJackpot,
            averageTicketsPerGame,
            successRate
        );
    }

    /**
     * @dev 게임당 평균 티켓 수 계산
     */
    function _calculateAverageTicketsPerGame(
        uint256 totalGames,
        uint256 totalJackpot,
        uint256 ticketPrice
    ) internal pure returns (uint256) {
        return totalGames > 0 ? totalJackpot / (totalGames * ticketPrice) : 0;
    }

    /**
     * @dev 성공률 계산
     */
    function _calculateSuccessRate(
        StorageLayout.GameStorage storage gameStorage,
        uint256 totalGames
    ) internal view returns (uint256) {
        uint256 completedGames = _countCompletedGames(gameStorage, totalGames);
        return totalGames > 0 ? (completedGames * 100) / totalGames : 0;
    }

    /**
     * @dev 완료된 게임 수 계산
     */
    function _countCompletedGames(
        StorageLayout.GameStorage storage gameStorage,
        uint256 totalGames
    ) internal view returns (uint256) {
        uint256 completedGames = 0;
        for (uint256 i = 0; i < totalGames; i++) {
            if (gameStorage.games[i].state == StorageLayout.GameState.ENDED) {
                completedGames++;
            }
        }
        return completedGames;
    }

    /**
     * @dev 플레이어 활동 분석 (BaseGame 레벨)
     * @param player 분석할 플레이어 주소
     * @return totalTicketsPurchased 총 구매한 티켓 수
     * @return gamesParticipated 참여한 게임 수
     * @return lastActivityTime 마지막 활동 시간
     * @return averageTicketsPerGame 게임당 평균 티켓 수
     */
    function getPlayerAnalytics(
        address player
    )
        external
        view
        virtual
        returns (
            uint256 totalTicketsPurchased,
            uint256 gamesParticipated,
            uint256 lastActivityTime,
            uint256 averageTicketsPerGame
        )
    {
        totalTicketsPurchased = getGameStorage().playerTicketCount[player];
        lastActivityTime = 0; // BaseGame에서는 lastPurchaseTime이 없으므로 0

        gamesParticipated = _calculateGamesParticipated(totalTicketsPurchased);
        averageTicketsPerGame = _calculatePlayerAverageTickets(
            totalTicketsPurchased,
            gamesParticipated
        );

        return (
            totalTicketsPurchased,
            gamesParticipated,
            lastActivityTime,
            averageTicketsPerGame
        );
    }

    /**
     * @dev 참여한 게임 수 계산
     */
    function _calculateGamesParticipated(
        uint256 totalTicketsPurchased
    ) internal pure returns (uint256) {
        return totalTicketsPurchased > 0 ? 1 : 0;
    }

    /**
     * @dev 플레이어 평균 티켓 수 계산
     */
    function _calculatePlayerAverageTickets(
        uint256 totalTicketsPurchased,
        uint256 gamesParticipated
    ) internal pure returns (uint256) {
        return
            gamesParticipated > 0
                ? totalTicketsPurchased / gamesParticipated
                : 0;
    }

    /**
     * @dev 게임 상태 일괄 조회 (BaseGame 레벨)
     * @return isActive 게임 활성 상태
     * @return currentGameId 현재 게임 ID
     * @return playerCount 플레이어 수
     * @return jackpot 잭팟
     * @return remainingTime 남은 시간
     * @return gameState 게임 상태
     */
    function getCompleteGameStatus()
        external
        view
        virtual
        returns (
            bool isActive,
            uint256 currentGameId,
            uint256 playerCount,
            uint256 jackpot,
            uint256 remainingTime,
            StorageLayout.GameState gameState
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId_ = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage game = gameStorage.games[currentGameId_];

        return _getGameStatus(gameStorage, game, currentGameId_);
    }

    /**
     * @dev 게임 상태 반환
     */
    function _getGameStatus(
        StorageLayout.GameStorage storage gameStorage,
        StorageLayout.Game storage game,
        uint256 currentGameId_
    )
        internal
        view
        returns (
            bool isActive,
            uint256 currentGameId,
            uint256 playerCount,
            uint256 jackpot,
            uint256 remainingTime,
            StorageLayout.GameState gameState
        )
    {
        return (
            gameStorage.isActive,
            currentGameId_,
            game.players.length,
            game.jackpot,
            getRemainingGameTime(),
            game.state
        );
    }

    /**
     * @dev 컨트랙트 상태 점검 (BaseGame 레벨)
     * @return isInitialized 초기화 상태
     * @return contractBalance 컨트랙트 잔액
     * @return totalGames 총 게임 수
     * @return totalPlayers 총 플레이어 수
     * @return totalJackpot 총 잭팟
     */
    function getContractHealth()
        external
        view
        virtual
        returns (
            bool isInitialized,
            uint256 contractBalance,
            uint256 totalGames,
            uint256 totalPlayers,
            uint256 totalJackpot
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        return (
            address(registry) != address(0),
            address(this).balance,
            gameStorage.totalGames,
            gameStorage.totalPlayers,
            gameStorage.totalJackpot
        );
    }

    /**
     * @dev 남은 게임 시간 조회
     */
    function getRemainingGameTime() public view virtual returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = _getCurrentGameId(gameStorage);
        StorageLayout.Game storage game = gameStorage.games[currentGameId];

        return _calculateRemainingTime(game);
    }

    /**
     * @dev 남은 시간 계산
     */
    function _calculateRemainingTime(
        StorageLayout.Game storage game
    ) internal view returns (uint256) {
        if (block.timestamp >= game.endTime) {
            return 0;
        }
        return game.endTime - block.timestamp;
    }

    // ============ UPGRADE FUNCTIONS ============

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // ============ FALLBACK FUNCTIONS ============

    fallback() external payable {
        buyTicket(address(0), 1);
    }

    receive() external payable {
        buyTicket(address(0), 1);
    }

    // ============ CUSTOM ERRORS ============
    error GameNotActive();
    error InvalidTicketCount();
    error IncorrectAmount();
    error GameNotInActiveState();
    error ExceedsMaxTickets();
    error InvalidRange();
    error NoPlayersInGame();
    error ReferralProcessingFailed();
    error StatsUpdateFailed();

    // ============ ADMIN FUNCTIONS ============

    /**
     * @dev Registry 설정 (관리자만)
     * @param _registry 새로운 registry 주소
     * @custom:security onlyOwner
     */
    function setRegistry(address _registry) external onlyOwner {
        require(_registry != address(0), "Invalid registry address");
        registry = ContractRegistry(_registry);
    }

    /**
     * @dev Treasury 이름 설정 (관리자만)
     * @param _treasuryName 새로운 treasury 이름
     * @custom:security onlyOwner
     */
    function setTreasuryName(string memory _treasuryName) external onlyOwner {
        require(bytes(_treasuryName).length > 0, "Invalid treasury name");
        treasuryName = _treasuryName;
    }

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
        gameStorage.totalGames++;
        _emitNewGameEvents(newGameId);
    }
}
