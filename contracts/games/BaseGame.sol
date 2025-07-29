// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../interfaces/ITreasuryManager.sol";
import "../interfaces/ICryptolottoReferral.sol";
import "../interfaces/ICryptolottoStatsAggregator.sol";
import "../interfaces/IOwnable.sol";

/**
 * @title BaseGame
 * @dev 모든 게임 컨트랙트의 공통 기능을 제공하는 베이스 컨트랙트
 */
abstract contract BaseGame is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    // 게임 상태 열거형
    enum GameState {
        WAITING,
        ACTIVE,
        ENDED
    }

    // 게임 구조체
    struct Game {
        uint256 gameNumber;
        uint256 startTime;
        uint256 endTime;
        uint256 jackpot;
        uint256 playerCount;
        GameState state;
        address[] players;
    }

    // 게임 타입 및 설정
    uint8 public gType;
    uint8 public fee;
    uint256 public gameDuration;
    uint256 public ticketPrice;
    uint256 public newPrice;
    uint256 public maxTicketsPerPlayer;
    uint256 public allTimeJackpot;
    uint256 public allTimePlayers;
    uint256 public paidToPartners;

    // 게임 상태
    bool public isActive;
    bool public toogleStatus;

    // 게임 관련 변수들
    Game public currentGame;
    uint256 public nextGameStartTime;

    // 플레이어 관련 변수들
    mapping(address => uint256) public playerTicketCount;

    // 외부 컨트랙트들
    IOwnable public ownable;
    ICryptolottoStatsAggregator public stats;
    ICryptolottoReferral public referralInstance;
    address public fundsDistributor;
    ITreasuryManager public treasuryManager;
    string public treasuryName;

    // 이벤트들
    event GameStarted(uint256 indexed gameNumber, uint256 timestamp);
    event GameEnded(uint256 indexed gameNumber, uint256 timestamp);
    event TicketPurchased(
        address indexed player,
        uint256 indexed gameNumber,
        uint256 ticketCount,
        uint256 totalAmount
    );
    event WinnerSelected(
        address indexed winner,
        uint256 indexed gameNumber,
        uint256 jackpot,
        uint256 timestamp
    );
    event GameStateChanged(
        uint256 indexed gameNumber,
        GameState state,
        uint256 timestamp
    );
    event TicketPriceChanged(
        uint256 oldPrice,
        uint256 newPrice,
        uint256 timestamp
    );

    // 수정자들
    modifier onlyGameActive() {
        require(isActive, "Game is not active");
        _;
    }

    modifier onlyValidTicketCount(uint256 count) {
        require(count > 0, "Ticket count must be greater than 0");
        require(count <= maxTicketsPerPlayer, "Exceeds max tickets per player");
        _;
    }

    modifier onlyValidAmount(uint256 ticketCount) {
        require(
            msg.value == ticketPrice * ticketCount,
            "Incorrect amount sent"
        );
        _;
    }

    // 추상 함수들 - 하위 컨트랙트에서 구현해야 함
    function _buyTicketInternal(
        address partner,
        uint256 ticketCount
    ) internal virtual;

    function _pickWinner() internal virtual;

    function _startNewGame() internal virtual;

    function _processReferralSystem(
        address partner,
        address referral
    ) internal virtual;

    function _processWinnerPayout(
        address winner,
        uint256 amount
    ) internal virtual;

    function _processPartnerPayments(address winner) internal virtual;

    function _processFounderDistribution(uint256 distribute) internal virtual;

    function _updateGameStats(
        address winner,
        uint256 playerCount,
        uint256 toPlayer,
        uint256 winnerIndex
    ) internal virtual;

    // 공통 함수들
    function buyTicket(
        address partner,
        uint256 ticketCount
    ) public payable nonReentrant {
        _buyTicketInternal(partner, ticketCount);
    }

    function buyTicket(address partner) external payable {
        buyTicket(partner, 1);
    }

    function setTicketPrice(uint256 newTicketPrice) external onlyOwner {
        require(newTicketPrice > 0, "Ticket price must be greater than 0");
        uint256 oldPrice = ticketPrice;
        newPrice = newTicketPrice;
        emit TicketPriceChanged(oldPrice, newTicketPrice, block.timestamp);
    }

    function toggleGame() external onlyOwner {
        toogleStatus = true;
    }

    function setMaxTicketsPerPlayer(
        uint256 maxTickets
    ) external virtual onlyOwner {
        require(maxTickets > 0, "Max tickets must be greater than 0");
        maxTicketsPerPlayer = maxTickets;
    }

    function setFee(uint8 newFee) external onlyOwner {
        require(newFee <= 20, "Fee cannot exceed 20%");
        fee = newFee;
    }

    function setTreasuryManager(
        address newTreasuryManager
    ) external virtual onlyOwner {
        require(
            newTreasuryManager != address(0),
            "Invalid treasury manager address"
        );
        treasuryManager = ITreasuryManager(newTreasuryManager);
    }

    function setReferralInstance(
        address newReferralInstance
    ) external onlyOwner {
        require(
            newReferralInstance != address(0),
            "Invalid referral instance address"
        );
        referralInstance = ICryptolottoReferral(newReferralInstance);
    }

    function toogleActive() public {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        if (!isActive) {
            isActive = true;
        } else {
            toogleStatus = !toogleStatus;
        }
    }

    function changeTicketPrice(uint256 price) public {
        require(ownable.isAllowed(msg.sender), "Not authorized");
        uint256 oldPrice = ticketPrice;
        newPrice = price;
        emit TicketPriceChanged(oldPrice, price, block.timestamp);
    }

    function randomNumber(
        uint256 min,
        uint256 max,
        uint256 time,
        uint256 difficulty,
        uint256 number,
        bytes32 bHash
    ) public pure returns (uint256) {
        min++;
        max++;
        uint256 random = (uint256(
            keccak256(abi.encodePacked(time, difficulty, number, bHash))
        ) % 10) + 1;
        uint256 result = (uint256(keccak256(abi.encodePacked(random))) %
            (min + max)) - min;
        if (result > max) result = max;
        if (result < min) result = min;
        result--;
        return result;
    }

    // 뷰 함수들
    function getCurrentGamePlayers()
        public
        view
        virtual
        returns (address[] memory)
    {
        return currentGame.players;
    }

    function getCurrentGameInfo()
        external
        view
        returns (
            uint256 gameNumber,
            uint256 startTime,
            uint256 endTime,
            uint256 jackpot,
            uint256 playerCount,
            GameState state
        )
    {
        return (
            currentGame.gameNumber,
            currentGame.startTime,
            currentGame.endTime,
            currentGame.jackpot,
            currentGame.playerCount,
            currentGame.state
        );
    }

    function isGameTimeExpired() public view virtual returns (bool) {
        return block.timestamp >= currentGame.endTime;
    }

    function getRemainingGameTime() public view virtual returns (uint256) {
        if (block.timestamp >= currentGame.endTime) {
            return 0;
        }
        return currentGame.endTime - block.timestamp;
    }

    function canStartNewGame() public view virtual returns (bool) {
        return
            block.timestamp >= nextGameStartTime &&
            currentGame.state == GameState.ENDED;
    }

    // 내부 함수들
    function _transferToTreasury(uint256 amount) internal {
        if (address(treasuryManager) != address(0)) {
            treasuryManager.depositFunds(treasuryName, msg.sender, amount);
        }
    }

    function _updatePlayerInfo(address player, uint256 ticketCount) internal {
        if (playerTicketCount[player] == 0) {
            currentGame.players.push(player);
            currentGame.playerCount++;
        }
        playerTicketCount[player] += ticketCount;
        currentGame.jackpot += msg.value;
    }

    function _resetPlayerTicketCounts() internal {
        for (uint256 i = 0; i < currentGame.players.length; i++) {
            playerTicketCount[currentGame.players[i]] = 0;
        }
    }

    function __BaseGame_init(address owner) internal onlyInitializing {
        __Ownable_init(owner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // Fallback 함수들
    fallback() external payable {
        buyTicket(address(0), 1);
    }

    receive() external payable {
        buyTicket(address(0), 1);
    }
}
