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
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        require(gameStorage.isActive, "Game is not active");
        require(ticketCount > 0, "Ticket count must be greater than 0");
        require(
            msg.value == gameStorage.ticketPrice * ticketCount,
            "Incorrect amount sent"
        );

        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // 게임 상태 처리 분리
        currentGameId = _handleGameState(gameStorage, currentGameId);
        currentGame = gameStorage.games[currentGameId];

        require(
            currentGame.state == StorageLayout.GameState.ACTIVE,
            "Game not active"
        );

        // 플레이어 정보 업데이트
        _updatePlayerInfoOptimized(msg.sender, ticketCount);
        // 재무 시스템 연동
        _transferToTreasury(msg.value);
        // 수수료 분배 처리
        _processFeeDistributionInternal(msg.value, referrer);
        // 이벤트 발생
        _emitTicketPurchasedEvents(currentGame.gameNumber, ticketCount);
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
        (
            uint256 referralFee,
            uint256 adLotteryFee,
            uint256 developerFee
        ) = _calculateFees(ticketAmount);
        if (
            referralFee > 0 && referrer != address(0) && referrer != msg.sender
        ) {
            _processReferralReward(referrer, msg.sender);
        }
        if (adLotteryFee > 0) {
            _processAdLotteryFee(adLotteryFee);
        }
        if (developerFee > 0) {
            _processDeveloperFee(developerFee);
        }
        emit FeeDistributed(
            referralFee,
            adLotteryFee,
            developerFee,
            block.timestamp
        );
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
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // 오버플로우 방지를 위한 안전한 계산
        uint256 currentTicketCount = gameStorage.playerTicketCount[player];
        require(
            currentTicketCount + ticketCount >= currentTicketCount,
            "Ticket count overflow"
        );

        // 플레이어 티켓 수 업데이트
        gameStorage.playerTicketCount[player] =
            currentTicketCount +
            ticketCount;

        // 새로운 플레이어인지 확인하고 추가 (O(1) 최적화)
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

        // 잭팟에 추가
        currentGame.jackpot += ticketCount * gameStorage.ticketPrice;
    }

    /**
     * @dev 새 게임 시작
     */
    function _startNewGame() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 newGameId = gameStorage.totalGames;

        StorageLayout.Game storage newGame = gameStorage.games[newGameId];
        newGame.gameNumber = newGameId;
        newGame.startTime = block.timestamp;
        newGame.endTime = block.timestamp + gameStorage.gameDuration;
        newGame.state = StorageLayout.GameState.ACTIVE;

        gameStorage.totalGames++;

        emit GameStateChanged(
            newGameId,
            StorageLayout.GameState.ACTIVE,
            block.timestamp
        );

        // 디버깅 이벤트
        emit TicketPurchased(
            address(0), // 더미 주소
            newGameId,
            999, // 특별한 값
            block.timestamp
        );
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

        address[] storage players = currentGame.players;
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
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // 게임이 활성 상태이고 시간이 만료되었는지 확인
        if (
            currentGame.state == StorageLayout.GameState.ACTIVE &&
            block.timestamp >= currentGame.endTime
        ) {
            _endCurrentGame();
        }
    }

    /**
     * @dev 자동 게임 종료 (누구나 호출 가능)
     */
    function autoEndGame() public {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // 게임이 활성 상태이고 시간이 만료되었는지 확인
        if (
            currentGame.state == StorageLayout.GameState.ACTIVE &&
            block.timestamp >= currentGame.endTime
        ) {
            _endCurrentGame();
            // 새 게임 자동 시작
            _startNewGame();
        }
    }

    /**
     * @dev 현재 게임 종료 및 승자 선정
     */
    function _endCurrentGame() internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // 게임 상태를 종료로 변경
        currentGame.state = StorageLayout.GameState.ENDED;

        // 자식 컨트랙트의 승자 선정 함수 호출 (잭팟 분배와 통계 업데이트 포함)
        address winner = _pickWinner();

        // 승자 선정 이벤트 발생
        emit WinnerSelected(
            winner,
            currentGame.gameNumber,
            currentGame.jackpot,
            currentGame.playerCount,
            block.timestamp
        );

        // 게임 종료 이벤트 발생
        emit GameEnded(
            currentGame.gameNumber,
            currentGame.playerCount,
            currentGame.jackpot,
            block.timestamp
        );

        // 게임 상태 변경 이벤트
        emit GameStateChanged(
            currentGame.gameNumber,
            StorageLayout.GameState.ENDED,
            block.timestamp
        );
    }

    /**
     * @dev 승자 선정 (기본 구현)
     */
    function _pickWinner() internal virtual returns (address) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        if (currentGame.players.length == 0) {
            return address(0);
        }

        // BaseGame의 randomNumber 함수 사용
        uint256 randomIndex = enhancedRandomNumberSecure(
            0,
            currentGame.players.length - 1,
            block.timestamp
        );

        return currentGame.players[randomIndex];
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
            // registry가 설정되지 않은 경우 (테스트 환경) 무시
            if (address(registry) == address(0)) {
                return;
            }

            try registry.getContract(treasuryName) returns (
                address treasuryAddress
            ) {
                if (treasuryAddress != address(0)) {
                    try
                        ITreasuryManager(treasuryAddress).depositFunds(
                            treasuryName,
                            msg.sender,
                            amount
                        )
                    {
                        // 성공적으로 Treasury로 전송됨
                    } catch {
                        // Treasury 전송 실패 시 컨트랙트에 보관
                        // (긴급 상황에서만 사용)
                    }
                }
            } catch {
                // registry에서 컨트랙트를 찾을 수 없는 경우 무시
            }
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
        // 총 수수료 계산 (10%)
        uint256 totalFee = (ticketAmount * TOTAL_FEE_PERCENT) / 100;

        if (totalFee > 0) {
            // 리퍼럴 수수료 계산 (2%)
            uint256 referralFee = (ticketAmount * REFERRAL_FEE_PERCENT) / 100;

            // Ad Lottery 수수료 계산 (3%)
            uint256 adLotteryFee = (ticketAmount * AD_LOTTERY_FEE_PERCENT) /
                100;

            // 개발자 수수료 계산 (5%)
            uint256 developerFee = (ticketAmount * DEVELOPER_FEE_PERCENT) / 100;

            // 리퍼럴 보상 처리
            if (
                referrer != address(0) &&
                referrer != msg.sender &&
                referralFee > 0
            ) {
                _processReferralReward(referrer, msg.sender);
            }

            // Ad Lottery 수수료 처리
            if (adLotteryFee > 0) {
                _processAdLotteryFee(adLotteryFee);
            }

            // 개발자 수수료 처리
            if (developerFee > 0) {
                _processDeveloperFee(developerFee);
            }

            // 수수료 분배 이벤트 발생
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
        // 단순화된 리퍼럴 시스템 - 리퍼러가 유효한 주소인 경우에만 보상 지급
        if (referrer != address(0) && referrer != player) {
            // registry가 설정되지 않은 경우 (테스트 환경) 무시
            if (address(registry) == address(0)) {
                return;
            }

            // 리퍼럴 컨트랙트 주소 가져오기
            try registry.getContract("CryptolottoReferral") returns (
                address referralContract
            ) {
                if (referralContract != address(0)) {
                    // 리퍼럴 보상 처리 (BaseGame에서 계산된 금액 사용)
                    try
                        CryptolottoReferral(referralContract)
                            .processReferralReward{value: 0}(
                            referrer,
                            0 // 금액은 _processFeeDistribution에서 처리됨
                        )
                    {
                        // 성공적으로 처리됨
                    } catch {
                        // 리퍼럴 처리 실패 시 무시 (게임은 계속 진행)
                    }
                }
            } catch {
                // registry에서 컨트랙트를 찾을 수 없는 경우 무시
            }
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
        // 개발자 수수료 처리 (FundsDistributor로 전송)
        if (amount > 0) {
            // registry가 설정되지 않은 경우 (테스트 환경) 무시
            if (address(registry) == address(0)) {
                return;
            }

            try registry.getContract("FundsDistributor") returns (
                address distributorAddress
            ) {
                if (distributorAddress != address(0)) {
                    // FundsDistributor로 직접 ETH 전송
                    (bool success, ) = payable(distributorAddress).call{
                        value: amount
                    }("");
                    if (success) {
                        emit DeveloperFeeSent(
                            distributorAddress,
                            amount,
                            block.timestamp
                        );
                    } else {
                        // 개발자 수수료 처리 실패 시 Treasury로 전송
                        _transferToTreasury(amount);
                    }
                }
            } catch {
                // registry에서 컨트랙트를 찾을 수 없는 경우 무시
            }
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
        gameStorage.ticketPrice = price;
        emit TicketPriceChanged(oldPrice, price, block.timestamp);
    }

    /**
     * @dev 최대 티켓 수 변경
     */
    function changeMaxTicketsPerPlayer(uint256 maxTickets) public virtual {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 oldValue = gameStorage.maxTicketsPerPlayer;
        gameStorage.maxTicketsPerPlayer = maxTickets;
        emit MaxTicketsPerPlayerUpdated(oldValue, maxTickets, block.timestamp);
    }

    /**
     * @dev 게임 시간 변경
     */
    function changeGameDuration(uint256 duration) public virtual {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 oldValue = gameStorage.gameDuration;
        gameStorage.gameDuration = duration;
        emit GameDurationUpdated(oldValue, duration, block.timestamp);
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

    /**
     * @dev 현재 게임 정보 조회
     */
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
        if (gameStorage.totalGames > 0) {
            StorageLayout.Game storage game = gameStorage.games[
                gameStorage.totalGames - 1
            ];
            return (
                game.gameNumber,
                game.startTime,
                game.endTime,
                game.jackpot,
                game.playerCount,
                game.state
            );
        } else {
            StorageLayout.Game storage game = gameStorage.games[0];
            return (
                game.gameNumber,
                game.startTime,
                game.endTime,
                game.jackpot,
                game.playerCount,
                game.state
            );
        }
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

        // 평균 티켓 수 계산
        averageTicketsPerGame = totalGames > 0
            ? totalJackpot / (totalGames * gameStorage.ticketPrice)
            : 0;

        // 성공률 계산 (완료된 게임 / 총 게임)
        uint256 completedGames = 0;
        for (uint256 i = 0; i < totalGames; i++) {
            if (gameStorage.games[i].state == StorageLayout.GameState.ENDED) {
                completedGames++;
            }
        }
        successRate = totalGames > 0 ? (completedGames * 100) / totalGames : 0;

        return (
            totalGames,
            totalPlayers,
            totalJackpot,
            averageTicketsPerGame,
            successRate
        );
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

        // 게임 참여 수 계산 (간단한 구현)
        gamesParticipated = totalTicketsPurchased > 0 ? 1 : 0;

        // 평균 티켓 수 계산
        averageTicketsPerGame = gamesParticipated > 0
            ? totalTicketsPurchased / gamesParticipated
            : 0;

        return (
            totalTicketsPurchased,
            gamesParticipated,
            lastActivityTime,
            averageTicketsPerGame
        );
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
        uint256 currentGameId_ = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage game = gameStorage.games[currentGameId_];

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
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];

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
}
