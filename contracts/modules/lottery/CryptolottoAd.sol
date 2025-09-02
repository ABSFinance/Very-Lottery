// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
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
import "../treasury/CryptolottoReferral.sol";
import "../treasury/FundsDistributor.sol";
import "../analytics/AnalyticsEngine.sol";
import "../analytics/MonitoringSystem.sol";
import "../analytics/StatsAggregator.sol";
import "../../shared/interfaces/IAdToken.sol";
import "../../shared/libraries/AdLotteryUtils.sol";

using GasOptimizer for address[];
using StorageOptimizer for address[];

/**
 * @title CryptolottoAd
 * @dev Ad Token을 사용한 광고 로또 게임
 * @dev 1일 동안 진행되며 최대 100개 티켓 구매 가능
 * @dev Ad Token으로만 티켓 구매 가능하며, 구매 시 즉시 소각됨
 * @dev 승자는 1Day/7Days 게임의 수수료(ETH)만 받음
 * @dev 총 수수료 10% 중 3%가 Ad Lottery 잭팟에 추가됨
 * @dev Ad Lottery는 자체 수수료가 없음 (commission = 0)
 * @dev 수수료는 1Day/7Days 게임에서 발생하여 Ad Lottery 잭팟에 추가됨
 */
contract CryptolottoAd is BaseGame {
    // Ad Token 컨트랙트
    IAdToken public adToken;
    // Ad Lottery 수수료 (변경 가능)
    // Ad Lottery는 자체 수수료가 없고, 1Day/7Days 게임의 수수료 3%를 받음
    uint256 public adLotteryFee = AdLotteryUtils.AD_LOTTERY_FEE;
    // 보안 강화를 위한 상태 변수
    mapping(address => uint256) public lastPurchaseTime;
    // ============ EVENTS ============

    event ReferralError(string operation, string reason, uint256 timestamp);
    event StatsError(string operation, string reason, uint256 timestamp);
    event DistributorError(string operation, string reason, uint256 timestamp);
    event AdTokenSet(address indexed adToken, uint256 timestamp);

    // ============ INITIALIZATION ============
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev 컨트랙트 초기화
     * @notice Ad Lottery 게임을 초기화하고 필요한 설정을 구성합니다
     * @param owner 컨트랙트 소유자 주소
     * @param _treasuryName Treasury 이름
     * @custom:security initializer
     */
    function initialize(
        address owner,
        address /* distributor */,
        address /* statsA */,
        address /* referralSystem */,
        address /* _treasuryManager */,
        string memory _treasuryName
    ) public initializer {
        require(owner != address(0), "Invalid owner address");
        require(bytes(_treasuryName).length > 0, "Invalid treasury name");
        __BaseGame_init(owner, address(0)); // registry는 나중에 설정
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.ticketPrice = 1 * (10 ** 18); // 1 AD Token
        gameStorage.gameDuration = 1 days;
        gameStorage.maxTicketsPerPlayer = 100;
        // Set Ad Token address (this will be set after deployment)
        // adToken = IAdToken(adTokenAddress);
    }

    // ============ GAME FUNCTIONS ============
    /**
     * @dev Ad Token으로 티켓 구매
     * @notice 사용자가 Ad Token을 사용하여 티켓을 구매합니다
     * @notice 구매된 Ad Token은 즉시 소각됩니다
     * @param ticketCount 구매할 티켓 수 (1-100개)
     * @custom:security nonReentrant
     * @custom:error "Ticket count must be greater than 0" - 티켓 수가 0 이하일 때
     * @custom:error "Exceeds max tickets per game" - 최대 티켓 수 초과 시
     * @custom:error "Insufficient AD tokens" - Ad Token 잔액 부족 시
     * @custom:error "AD token transfer failed" - Ad Token 전송 실패 시
     * @custom:error "Invalid sender address" - 잘못된 발신자 주소
     * @custom:error "Game is not active" - 게임이 비활성 상태
     * @custom:error "Ad Token not set" - Ad Token 주소가 설정되지 않음
     */
    function buyAdTicket(uint256 ticketCount) external nonReentrant {
        require(ticketCount > 0, "Ticket count must be greater than 0");
        require(
            ticketCount <= AdLotteryUtils.AD_MAX_TICKETS,
            "Exceeds max tickets per game"
        );
        require(msg.sender != address(0), "Invalid sender address");
        require(address(adToken) != address(0), "Ad Token not set");
        // 게임 활성 상태 확인
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        require(gameStorage.isActive, "Game is not active");
        // 구매 쿨다운 확인 (테스트 모드가 아닐 때만)
        if (!gameStorage.testMode) {
            require(
                block.timestamp >=
                    lastPurchaseTime[msg.sender] +
                        AdLotteryUtils.PURCHASE_COOLDOWN,
                "Purchase cooldown not met"
            );
        }
        uint256 totalAdTokens = ticketCount * AdLotteryUtils.AD_TICKET_PRICE;
        // Ad Token 잔액 확인
        require(
            adToken.balanceOf(msg.sender) >= totalAdTokens,
            "Insufficient AD tokens"
        );
        // Ad Token 전송 후 소각 (재진입 공격 방지)
        bool transferSuccess = adToken.transferFrom(
            msg.sender,
            address(this),
            totalAdTokens
        );
        require(transferSuccess, "AD token transfer failed");
        // Ad Token 소각 (즉시 실행)
        adToken.burn(totalAdTokens);
        // 구매 시간 업데이트
        lastPurchaseTime[msg.sender] = block.timestamp;
        // 내부 티켓 구매 처리
        _buyAdTicketInternal(ticketCount);
    }

    /**
     * @dev 가스 최적화된 Ad 티켓 구매
     * @notice 배치 처리를 통한 가스 최적화
     */
    function buyAdTicketBatch(
        uint256[] memory ticketCounts
    ) external nonReentrant {
        require(ticketCounts.length > 0, "Empty batch");
        require(msg.sender != address(0), "Invalid sender address");
        require(address(adToken) != address(0), "Ad Token not set");
        // 게임 활성 상태 확인
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        require(gameStorage.isActive, "Game is not active");
        // 구매 쿨다운 확인 (테스트 모드가 아닐 때만)
        if (!gameStorage.testMode) {
            require(
                block.timestamp >=
                    lastPurchaseTime[msg.sender] +
                        AdLotteryUtils.PURCHASE_COOLDOWN,
                "Purchase cooldown not met"
            );
        }
        uint256 totalTickets = 0;
        uint256 totalAdTokens = 0;
        // 총 티켓 수와 필요한 Ad Token 계산
        for (uint256 i = 0; i < ticketCounts.length; i++) {
            require(ticketCounts[i] > 0, "Invalid ticket count");
            require(
                ticketCounts[i] <= AdLotteryUtils.AD_MAX_TICKETS,
                "Exceeds max tickets"
            );
            totalTickets += ticketCounts[i];
            totalAdTokens += ticketCounts[i] * AdLotteryUtils.AD_TICKET_PRICE;
        }
        // Ad Token 잔액 확인
        require(
            adToken.balanceOf(msg.sender) >= totalAdTokens,
            "Insufficient AD tokens"
        );
        // Ad Token 전송 후 소각
        bool transferSuccess = adToken.transferFrom(
            msg.sender,
            address(this),
            totalAdTokens
        );
        require(transferSuccess, "AD token transfer failed");
        // Ad Token 소각
        adToken.burn(totalAdTokens);
        // 구매 시간 업데이트
        lastPurchaseTime[msg.sender] = block.timestamp;
        // 배치 티켓 구매 처리
        _buyAdTicketBatchInternal(ticketCounts);
    }

    /**
     * @dev 향상된 랜덤 생성 함수 (보안 강화)
     * @notice 시간 기반 공격 방지를 위한 추가 엔트로피 소스 사용
     */
    function enhancedRandomNumber(
        uint256 min,
        uint256 max,
        uint256 seed
    ) internal view returns (uint256) {
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
     * @dev 내부 Ad 티켓 구매 함수 (중앙화된 스토리지 사용)
     * @notice 가스 최적화를 위해 스토리지 접근을 최소화합니다
     */
    function _buyAdTicketInternal(uint256 ticketCount) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        require(gameStorage.isActive, "Game is not active");
        require(ticketCount > 0, "Ticket count must be greater than 0");
        // 현재 게임 정보를 한 번만 가져와서 캐싱
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];
        // 게임이 아직 시작되지 않았다면 시작
        if (game.state == StorageLayout.GameState.WAITING) {
            _startNewGame();
            // 새로 생성된 게임의 ID를 다시 계산
            currentGameId = gameStorage.totalGames - 1;
            game = gameStorage.games[currentGameId];
        }
        require(
            game.state == StorageLayout.GameState.ACTIVE,
            "Game not active"
        );
        // 최대 티켓 수 확인 (캐싱된 값 사용)
        uint256 currentTicketCount = gameStorage.playerTicketCount[msg.sender];
        require(
            currentTicketCount + ticketCount <= gameStorage.maxTicketsPerPlayer,
            "Exceeds maximum tickets per player"
        );
        // Ad Lottery 전용 플레이어 정보 업데이트
        _updateAdPlayerInfo(msg.sender, ticketCount);
        // Ad Lottery 수수료 처리 (1day + 7day 수수료의 3%)
        _processAdLotteryFee();
        // 이벤트 발생 (라이브러리 이벤트 사용)
        emit AdLotteryUtils.AdTicketPurchased(
            msg.sender,
            game.gameNumber,
            ticketCount,
            ticketCount * AdLotteryUtils.AD_TICKET_PRICE,
            block.timestamp
        );
    }

    /**
     * @dev 배치 Ad 티켓 구매 내부 함수
     * @notice 여러 티켓을 한 번에 처리하여 가스 최적화
     */
    function _buyAdTicketBatchInternal(uint256[] memory ticketCounts) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        require(gameStorage.isActive, "Game is not active");
        // 현재 게임 정보를 한 번만 가져와서 캐싱
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];
        // 게임이 아직 시작되지 않았다면 시작
        if (game.state == StorageLayout.GameState.WAITING) {
            _startNewGame();
            // 새로 생성된 게임의 ID를 다시 계산
            currentGameId = gameStorage.totalGames - 1;
            game = gameStorage.games[currentGameId];
        }
        require(
            game.state == StorageLayout.GameState.ACTIVE,
            "Game not active"
        );
        // 배치 처리
        for (uint256 i = 0; i < ticketCounts.length; i++) {
            uint256 ticketCount = ticketCounts[i];
            require(ticketCount > 0, "Invalid ticket count");
            // 최대 티켓 수 확인
            uint256 currentTicketCount = gameStorage.playerTicketCount[
                msg.sender
            ];
            require(
                currentTicketCount + ticketCount <=
                    gameStorage.maxTicketsPerPlayer,
                "Exceeds maximum tickets per player"
            );
            // Ad Lottery 전용 플레이어 정보 업데이트
            _updateAdPlayerInfo(msg.sender, ticketCount);
            // 이벤트 발생
            emit AdLotteryUtils.AdTicketPurchased(
                msg.sender,
                game.gameNumber,
                ticketCount,
                ticketCount * AdLotteryUtils.AD_TICKET_PRICE,
                block.timestamp
            );
        }
        // Ad Lottery 수수료 처리 (배치 처리 후 한 번만)
        _processAdLotteryFee();
    }

    /**
     * @dev Ad Lottery 전용 플레이어 정보 업데이트
     * @notice 오버플로우 방지를 위한 안전한 계산
     */
    function _updateAdPlayerInfo(address player, uint256 ticketCount) internal {
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
        // 플레이어 티켓 수 업데이트 (두 곳 모두 업데이트)
        gameStorage.playerTicketCount[player] =
            currentTicketCount +
            ticketCount;

        // Also update playerInfo.ticketCount for getPlayerInfo() compatibility
        StorageLayout.PlayerInfo storage playerInfo = gameStorage.playerInfo[
            player
        ];
        playerInfo.ticketCount += ticketCount;
        playerInfo.lastPurchaseTime = block.timestamp;
        // Note: totalSpent is not updated for Ad Lottery since no ETH is spent

        // Ad Lottery에서는 Ad Token이 소각되므로 jackpot에 추가하지 않음
        // jackpot은 _processAdLotteryFee()에서 고정 수수료로만 추가됨
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
    }

    /**
     * @dev Ad Lottery 승자 선택 (중앙화된 스토리지 사용)
     * @dev 승자는 오직 1Day/7Days에서 수집된 수수료(ETH)만 받음
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

        uint256 randomIndex = enhancedRandomNumber(
            0,
            game.players.length - 1,
            block.timestamp
        );
        return game.players[randomIndex];
    }

    /**
     * @dev Process new fee notification from 1Day/7Days lotteries
     * @param amount The fee amount that was deposited to treasury
     */
    function processNewFee(uint256 amount) external {
        // Only allow calls from authorized lottery contracts
        require(_isRegistryAvailable(), "Registry not available");

        address caller = msg.sender;
        address lottery1Day = registry.getContract("Cryptolotto1Day");
        address lottery7Days = registry.getContract("Cryptolotto7Days");

        require(
            caller == lottery1Day || caller == lottery7Days,
            "Only authorized lottery contracts can call this function"
        );

        // Add the fee amount directly to the jackpot
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];

        // 오버플로우 방지
        require(game.jackpot + amount >= game.jackpot, "Jackpot overflow");
        game.jackpot += amount;

        emit AdLotteryFeeCollected(amount, block.timestamp);
    }

    /**
     * @dev Ad Lottery 수수료 처리 (1day + 7day 수수료의 3%)
     * @notice Ad Lottery는 자체 수수료가 없고, 1Day/7Days 게임의 수수료를 받습니다
     * @notice 이 수수료는 Ad Lottery 잭팟에 추가되어 승자에게 ETH로 지급됩니다
     * @notice Ad Token은 티켓 구매 시 즉시 소각되므로 수수료로 사용되지 않습니다
     */
    function _processAdLotteryFee() internal {
        // 1day와 7day 게임의 수수료 3%를 Ad Lottery 잭팟에 추가
        // Treasury에서 Ad Lottery 잭팟으로 ETH를 전송
        if (_isRegistryAvailable()) {
            try registry.getContract("TreasuryManager") returns (
                address treasuryAddress
            ) {
                if (treasuryAddress != address(0)) {
                    // Get available balance from Ad Lottery treasury
                    // ITreasuryManager treasury = ITreasuryManager(treasuryAddress);

                    // For now, we'll use a simple approach since the treasury system
                    // requires the caller to have a balance in the treasury
                    // In a production system, we'd need to modify the treasury to allow
                    // the Ad Lottery contract to withdraw accumulated fees

                    // TODO: Implement proper treasury withdrawal mechanism
                    // The current treasury system doesn't allow the Ad Lottery to withdraw
                    // fees that were deposited by other contracts (1Day/7Days)

                    emit AdLotteryFeeCollected(0, block.timestamp);
                }
            } catch {
                // If treasury access fails, continue without funding
                emit TreasuryOperationFailed(
                    "ad_lottery_funding",
                    block.timestamp
                );
            }
        }
    }

    /**
     * @dev 승자 지급 처리
     */
    function _processWinnerPayout(
        address winner,
        uint256 /* amount */
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
            if (winner != address(0)) {
                uint256 jackpot = getCurrentGameJackpot();
                if (jackpot > 0) {
                    try
                        ITreasuryManager(treasuryAddress).withdrawFunds(
                            treasuryName,
                            winner,
                            jackpot
                        )
                    {
                        emit WinnerPayout(winner, jackpot, block.timestamp);
                    } catch {
                        emit TreasuryTransferFailed(
                            address(this),
                            jackpot,
                            "Withdrawal failed",
                            block.timestamp
                        );
                    }
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
     * @dev 창립자 분배 처리 (Ad Lottery는 수수료 없음)
     * @notice Ad Lottery는 자체 수수료가 없습니다
     * @notice 수수료는 1Day/7Days 게임에서 발생하여 Ad Lottery 잭팟에 추가됩니다
     * @notice 따라서 Ad Lottery에서는 별도의 수수료 분배가 필요하지 않습니다
     */
    function _processFounderDistribution(uint256 amount) internal override {
        // Ad Lottery는 수수료가 없으므로 아무것도 하지 않음
        // 수수료는 1Day/7Days 게임에서 발생하여 Ad Lottery 잭팟에 추가됨
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
                    3, // Ad Lottery 게임 타입
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

    // ============ UTILITY FUNCTIONS ============
    /**
     * @dev Ad Lottery 성능 메트릭 기록
     * @notice 게임 성능을 추적하기 위한 메트릭 기록
     */
    function _recordPerformanceMetrics(
        uint256 gameNumber,
        uint256 gasUsed,
        uint256 playerCount,
        uint256 jackpot
    ) internal override {
        emit AdLotteryUtils.AdLotteryPerformanceMetrics(
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
        emit AdLotteryUtils.AdLotterySecurityEvent(
            player,
            eventType,
            block.timestamp
        );
    }

    /**
     * @dev Ad Token 잔액 조회
     * @return balance Ad Token 잔액
     */
    function getAdTokenBalance() external view returns (uint256) {
        return adToken.balanceOf(address(this));
    }

    /**
     * @dev Ad Token 인출 (관리자만)
     * @param amount 인출할 금액
     * @custom:security onlyOwner
     * @custom:error "Amount must be greater than 0" - 금액이 0 이하일 때
     * @custom:error "Insufficient AD tokens" - Ad Token 잔액 부족 시
     * @custom:error "AD token transfer failed" - Ad Token 전송 실패 시
     * @custom:error "Invalid amount" - 잘못된 금액
     */
    function withdrawAdTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= adToken.balanceOf(address(this)), "Invalid amount");
        require(
            adToken.balanceOf(address(this)) >= amount,
            "Insufficient AD tokens"
        );
        // 안전한 전송
        bool transferSuccess = adToken.transfer(msg.sender, amount);
        require(transferSuccess, "AD token transfer failed");
        // 이벤트 발생
        emit TreasuryFundsWithdrawn(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Ad Token 소각된 양 조회 (simplified)
     * @return burnedAmount 소각된 Ad Token 양
     */
    function getAdTokenBurnedAmount() external view returns (uint256) {
        return adToken.totalSupply() - adToken.balanceOf(address(this));
    }

    // Removed getPlayerAnalytics to reduce contract size

    /**
     * @dev Ad Lottery 수수료 비율 설정
     * @notice 관리자만 호출 가능하며, 수수료 비율을 변경합니다
     * @param newFee 새로운 수수료 비율 (0-10%)
     * @custom:security onlyOwner
     * @custom:error "Fee cannot exceed 10%" - 수수료가 10% 초과 시
     */
    function setAdLotteryFee(uint256 newFee) external onlyOwner {
        require(
            newFee <= AdLotteryUtils.AD_LOTTERY_FEE_MAX,
            "Fee cannot exceed 10%"
        );
        uint256 oldFee = adLotteryFee;
        adLotteryFee = newFee;
        emit AdLotteryUtils.AdLotteryFeeUpdated(
            oldFee,
            newFee,
            block.timestamp
        );
    }

    /**
     * @dev Ad Lottery 게임 정보 조회
     * @return currentGameId 현재 게임 ID
     * @return ticketPrice 티켓 가격
     * @return gameDuration 게임 지속 시간
     * @return maxTickets 최대 티켓 수
     * @return adLotteryFeePercent Ad Lottery 수수료 비율
     * @return adTokenBalance Ad Token 잔액
     * @return isActive 활성 상태
     */
    function getAdLotteryInfo()
        external
        view
        returns (
            uint256 currentGameId,
            uint256 ticketPrice,
            uint256 gameDuration,
            uint256 maxTickets,
            uint256 adLotteryFeePercent,
            uint256 adTokenBalance,
            bool isActive
        )
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        return (
            gameStorage.totalGames > 0 ? gameStorage.totalGames - 1 : 0,
            AdLotteryUtils.AD_TICKET_PRICE,
            AdLotteryUtils.AD_GAME_DURATION,
            AdLotteryUtils.AD_MAX_TICKETS,
            adLotteryFee,
            adToken.balanceOf(address(this)),
            gameStorage.isActive
        );
    }

    /**
     * @dev 게임 시간 만료 확인
     */
    function isGameTimeExpired() public view returns (bool) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];
        return block.timestamp >= game.endTime;
    }

    // Removed getGameInfo to reduce contract size

    // Removed more view functions to reduce contract size

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

    // ============ ADMIN FUNCTIONS ============

    /**
     * @notice Set Ad Token address
     * @param adTokenAddress The Ad Token contract address
     */
    function setAdToken(address adTokenAddress) external onlyOwner {
        require(adTokenAddress != address(0), "Invalid Ad Token address");
        require(adTokenAddress != address(this), "Cannot set self as Ad Token");

        // Verify that the Ad Token contract actually exists
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(adTokenAddress)
        }
        require(codeSize > 0, "Ad Token address has no code");

        adToken = IAdToken(adTokenAddress);
        emit AdTokenSet(adTokenAddress, block.timestamp);
    }
}
