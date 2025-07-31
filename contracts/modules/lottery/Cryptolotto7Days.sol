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
 * @title Cryptolotto7Days
 * @dev 7일 로또 게임 컨트랙트 - 새로운 중앙화된 스토리지 아키텍처 사용
 */
contract Cryptolotto7Days is BaseGame {
    // ============ EVENTS ============
    event ReferralError(string operation, string reason, uint256 timestamp);
    event StatsError(string operation, string reason, uint256 timestamp);
    event DistributorError(string operation, string reason, uint256 timestamp);

    // ============ INITIALIZATION ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address ownableContract,
        address distributor,
        address statsA,
        address referralSystem,
        address _treasuryManager,
        address _registry
    ) public initializer {
        __BaseGame_init(owner, _registry);

        // 게임 타입별 설정 (7일 게임)
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        gameStorage.ticketPrice = 0.01 ether;
        gameStorage.gameDuration = 7 days;
        gameStorage.maxTicketsPerPlayer = 100;
        gameStorage.isActive = true;

        // 외부 컨트랙트 설정
        ownable = IOwnable(ownableContract);
        treasuryName = "Cryptolotto7Days";
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
                game.gameNumber,
                game.players.length - 1 + i,
                block.timestamp
            );
        }
    }

    /**
     * @dev 승자 선택 (중앙화된 스토리지 사용)
     */
    function _pickWinner() internal override returns (address) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames > 0
            ? gameStorage.totalGames - 1
            : 0;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];

        uint256 playerCount = game.players.length;
        uint256 jackpot = game.jackpot;

        // 플레이어가 없으면 null address 반환
        if (playerCount == 0) {
            return address(0);
        }

        uint256 winner;
        uint256 toPlayer;

        if (playerCount == 1) {
            toPlayer = jackpot;
            _processWinnerPayout(game.players[0], toPlayer);
            winner = 0;
        } else {
            // 안전한 범위 계산
            uint256 maxIndex = playerCount - 1;
            winner = randomNumber(
                0,
                maxIndex,
                block.timestamp,
                block.prevrandao,
                block.number,
                blockhash(block.number - 1)
            );

            uint256 distribute = (jackpot * 10) / 100; // 10% 수수료
            toPlayer = jackpot - distribute;

            _processWinnerPayout(game.players[winner], toPlayer);
            _processFounderDistribution(distribute);
        }

        _updateGameStats(game.players[winner], playerCount, toPlayer, winner);

        // 잭팟 분배 이벤트 발생
        emit JackpotDistributed(
            game.players[winner],
            toPlayer,
            game.gameNumber,
            block.timestamp
        );

        return game.players[winner];
    }

    /**
     * @dev 추천 시스템 처리
     */
    function _processReferralSystem(
        address partner,
        address referral
    ) internal override {
        if (address(registry) == address(0)) {
            emit ReferralError(
                "getContract",
                "Registry not initialized",
                block.timestamp
            );
            return;
        }

        try registry.getContract("CryptolottoReferral") returns (
            address referralAddress
        ) {
            if (referralAddress == address(0)) {
                emit ReferralError(
                    "getContract",
                    "Referral contract not found",
                    block.timestamp
                );
                return;
            }

            try
                ICryptolottoReferral(referralAddress).addReferral(
                    partner,
                    referral
                )
            {
                // 성공적으로 처리됨
            } catch Error(string memory reason) {
                emit ReferralError("addReferral", reason, block.timestamp);
            } catch {
                emit ReferralError(
                    "addReferral",
                    "Unknown error",
                    block.timestamp
                );
            }
        } catch Error(string memory reason) {
            emit ReferralError("getContract", reason, block.timestamp);
        } catch {
            emit ReferralError(
                "getContract",
                "Unknown registry error",
                block.timestamp
            );
        }
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

            try
                ITreasuryManager(treasuryAddress).withdrawFunds(
                    treasuryName,
                    winner,
                    amount
                )
            {
                emit TreasuryFundsWithdrawn(winner, amount, block.timestamp);
            } catch Error(string memory reason) {
                emit TreasuryTransferFailed(
                    winner,
                    amount,
                    reason,
                    block.timestamp
                );
            } catch {
                emit TreasuryTransferFailed(
                    winner,
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

            try
                ICryptolottoStatsAggregator(statsAddress).newWinner(
                    winner,
                    getCurrentGameInfo().gameNumber,
                    playerCount,
                    amount,
                    7, // 7일 게임 타입
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
     * @dev 남은 게임 시간 조회
     */
    function getRemainingGameTime() public view returns (uint256) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        uint256 currentGameId = gameStorage.totalGames;
        StorageLayout.Game storage game = gameStorage.games[currentGameId];

        if (block.timestamp >= game.endTime) {
            return 0;
        }
        return game.endTime - block.timestamp;
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
}
