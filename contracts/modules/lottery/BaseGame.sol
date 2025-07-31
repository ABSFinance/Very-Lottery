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
    event TicketPurchased(
        address indexed player,
        uint256 indexed gameNumber,
        uint256 ticketCount,
        uint256 totalAmount
    );

    // 추가된 이벤트들
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

    // ============ ABSTRACT FUNCTIONS ============
    function _processReferralSystem(
        address partner,
        address referral
    ) internal virtual;

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
        __Ownable_init(owner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        registry = ContractRegistry(_registry);

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
        address partner,
        uint256 ticketCount
    ) public payable nonReentrant {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        require(gameStorage.isActive, "Game is not active");
        require(ticketCount > 0, "Ticket count must be greater than 0");
        require(
            msg.value == gameStorage.ticketPrice * ticketCount,
            "Incorrect amount sent"
        );

        // 현재 게임 정보 가져오기
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // 게임이 아직 시작되지 않았다면 시작
        if (currentGame.state == StorageLayout.GameState.WAITING) {
            _startNewGame();
            currentGame = gameStorage.games[gameStorage.totalGames - 1]; // 새로 생성된 게임을 가져옴
        }

        // 게임이 활성 상태이고 시간이 만료되었는지 자동 체크
        if (
            currentGame.state == StorageLayout.GameState.ACTIVE &&
            block.timestamp >= currentGame.endTime
        ) {
            _endCurrentGame();
            // 새 게임 시작
            _startNewGame();
            currentGame = gameStorage.games[gameStorage.totalGames - 1];
        }

        require(
            currentGame.state == StorageLayout.GameState.ACTIVE,
            "Game not active"
        );

        // 플레이어 정보 업데이트
        _updatePlayerInfo(msg.sender, ticketCount);

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
                currentGame.gameNumber,
                i, // players.length - 1 + i 대신 단순히 i 사용
                block.timestamp
            );
        }
    }

    /**
     * @dev 플레이어 정보 업데이트 (최적화된 버전)
     */
    function _updatePlayerInfo(address player, uint256 ticketCount) internal {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0; // 안전한 계산
        StorageLayout.Game storage currentGame = gameStorage.games[
            currentGameId
        ];

        // 플레이어 티켓 수 업데이트
        gameStorage.playerTicketCount[player] += ticketCount;
        currentGame.jackpot += msg.value;
        // currentGame.playerCount += ticketCount; // 잘못된 부분 제거

        // 새로운 플레이어인지 확인하고 추가
        if (StorageOptimizer.addUniquePlayer(currentGame.players, player)) {
            gameStorage.totalPlayers++;
            currentGame.playerCount += 1;
        }
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
        uint256 randomIndex = randomNumber(
            0,
            currentGame.players.length - 1,
            block.timestamp,
            block.prevrandao,
            block.number,
            blockhash(block.number - 1)
        );

        return currentGame.players[randomIndex];
    }

    /**
     * @dev 랜덤 숫자 생성 (BaseGame에서 제공)
     */
    function randomNumber(
        uint256 min,
        uint256 max,
        uint256 time,
        uint256 difficulty,
        uint256 number,
        bytes32 bHash
    ) public pure returns (uint256) {
        require(max >= min, "Max must be greater than or equal to min");

        uint256 hash = uint256(
            keccak256(abi.encodePacked(time, difficulty, number, bHash))
        );

        // 안전한 범위 계산
        uint256 range = max - min + 1;
        uint256 randomValue = hash % range;

        return min + randomValue;
    }

    // ============ TREASURY FUNCTIONS ============

    /**
     * @dev 재무 시스템으로 자금 이체 (개선된 에러 처리)
     */
    function _transferToTreasury(uint256 amount) internal {
        if (address(registry) == address(0)) {
            emit RegistryError("transfer", "TreasuryManager", block.timestamp);
            return;
        }

        try registry.getContract("TreasuryManager") returns (
            address treasuryAddress
        ) {
            if (treasuryAddress == address(0)) {
                emit ContractNotFound("TreasuryManager", block.timestamp);
                return;
            }

            try
                ITreasuryManager(treasuryAddress).depositFunds(
                    treasuryName,
                    msg.sender,
                    amount
                )
            {
                emit TreasuryFundsDeposited(amount, block.timestamp);
            } catch Error(string memory reason) {
                emit TreasuryTransferFailed(
                    msg.sender,
                    amount,
                    reason,
                    block.timestamp
                );
            } catch {
                emit TreasuryTransferFailed(
                    msg.sender,
                    amount,
                    "Unknown treasury error",
                    block.timestamp
                );
            }
        } catch Error(string memory reason) {
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
        require(ownable.isAllowed(msg.sender), "Not authorized");
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.isActive = false;
        emit EmergencyPaused(msg.sender, reason, block.timestamp);
    }

    /**
     * @dev 긴급 재개
     */
    function emergencyResume() public virtual {
        require(ownable.isAllowed(msg.sender), "Not authorized");
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
        returns (StorageLayout.Game memory)
    {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        if (gameStorage.totalGames > 0) {
            return gameStorage.games[gameStorage.totalGames - 1];
        } else {
            return gameStorage.games[0];
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
}
