// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./BaseGame.sol";

/**
 * @title Cryptolotto7Days
 * @dev 7일 로또 게임을 위한 스마트 컨트랙트
 *
 * 이 컨트랙트는 다음과 같은 기능을 제공합니다:
 * - 7일 주기로 자동 실행되는 로또 게임
 * - 티켓 구매 및 당첨자 선정
 * - 리퍼럴 시스템을 통한 파트너 보상
 * - Treasury Manager를 통한 자금 관리
 * - 업그레이드 가능한 구조 (UUPS)
 *
 * 보안 기능:
 * - ReentrancyGuard로 재진입 공격 방지
 * - 입력 검증 및 접근 제어
 * - Gas 최적화된 구조
 *
 * @author Cryptolotto Team
 */
contract Cryptolotto7Days is BaseGame {
    /**
     * @dev Write to log info about partner's earnings.
     *
     * @param _partner Partner's wallet address.
     * @param _referral Referral's wallet address.
     * @param _amount Earnings amount.
     * @param _time The time when ether was earned.
     */
    event PartnerPaid(
        address indexed _partner,
        address _referral,
        uint _amount,
        uint _time
    );

    /**
     * @dev Write to log info about sales' partner earnings.
     *
     * @param _salesPartner Sales' partner wallet address.
     * @param _partner Partner' wallet address.
     * @param _amount Earnings amount.
     * @param _time The time when ether was earned.
     */
    event SalesPartnerPaid(
        address indexed _salesPartner,
        address _partner,
        uint _amount,
        uint _time
    );

    /**
     * @dev Write to log info about game status changes.
     *
     * @param _isActive New game status.
     * @param _time Time when status was changed.
     */
    event GameStatusChanged(bool _isActive, uint _time);
    event TreasuryManagerUpdated(
        address indexed oldManager,
        address indexed newManager,
        uint _time
    );
    event TreasuryFundsDeposited(uint256 amount, uint256 timestamp);
    event TreasuryFundsWithdrawn(
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );
    event TreasuryOperationFailed(string operation, uint256 timestamp);
    event MaxTicketsPerPlayerUpdated(uint maxTickets, uint256 timestamp);

    string public constant TREASURY_NAME = "unique_test_lottery_7days";

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
        address _treasuryManager
    ) public initializer {
        __BaseGame_init(owner);
        gType = 5;
        fee = 10;
        gameDuration = 604800;
        ticketPrice = 1 ether;
        maxTicketsPerPlayer = 10;
        isActive = true;
        ownable = IOwnable(ownableContract);
        fundsDistributor = distributor;
        stats = ICryptolottoStatsAggregator(statsA);
        referralInstance = ICryptolottoReferral(referralSystem);
        treasuryName = TREASURY_NAME;

        // Treasury Manager setup - required
        require(_treasuryManager != address(0), "Treasury manager is required");
        treasuryManager = ITreasuryManager(_treasuryManager);
        currentGame = Game({
            gameNumber: 1,
            startTime: block.timestamp,
            endTime: block.timestamp + gameDuration,
            jackpot: 0,
            playerCount: 0,
            state: GameState.ACTIVE,
            players: new address[](0)
        });
        nextGameStartTime = currentGame.endTime;
        emit GameStarted(currentGame.gameNumber, block.timestamp);
        emit GameStateChanged(
            currentGame.gameNumber,
            GameState.ACTIVE,
            block.timestamp
        );
    }

    /**
     * @dev Returns current game players.
     */
    function getPlayedGamePlayers() public view returns (uint) {
        return getPlayersInGame(currentGame.gameNumber);
    }

    /**
     * @dev Get players by game.
     *
     * @param playedGame Game number.
     */
    function getPlayersInGame(uint playedGame) public view returns (uint) {
        return currentGame.players.length;
    }

    /**
     * @dev Returns current game jackpot.
     */
    function getPlayedGameJackpot() public view returns (uint) {
        return currentGame.jackpot;
    }

    /**
     * @dev Get jackpot by game number.
     *
     * @param playedGame The number of the played game.
     */
    function getGameJackpot(uint playedGame) public view returns (uint) {
        return currentGame.jackpot;
    }

    /**
     * @dev Change game status.
     * @dev If the game is active sets flag for game status changing. Otherwise, change game status.
     */

    function _buyTicketInternal(
        address partner,
        uint256 ticketCount
    ) internal override {
        // Enhanced input validation
        require(isActive, "Game is not active");
        require(ticketCount > 0, "Ticket count must be greater than 0");
        require(ticketCount <= 1000, "Ticket count exceeds maximum limit");
        require(msg.sender != address(0), "Invalid sender address");
        require(partner != msg.sender, "Partner cannot be the same as sender");

        // Cache current game state to reduce storage reads
        Game storage game = currentGame;

        // Check if current game has expired and end it if needed
        if (isGameTimeExpired() && game.players.length > 0) {
            endGame();
            // Re-read game state after endGame
            game = currentGame;
        }

        // Start new game if not active or if first game
        if (game.state != GameState.ACTIVE) {
            _startNewGame();
            // Re-read game state after startNewGame
            game = currentGame;
        }

        require(game.state == GameState.ACTIVE, "Game not active");
        require(
            msg.value == ticketPrice * ticketCount,
            "Incorrect ticket price"
        );

        // Check max tickets per player (optimized)
        uint currentPlayerTickets = 0;
        uint256 playerCount = game.players.length;
        for (uint i = 0; i < playerCount; i++) {
            if (game.players[i] == msg.sender) {
                currentPlayerTickets++;
            }
        }
        require(
            currentPlayerTickets + ticketCount <= maxTicketsPerPlayer,
            "Exceeds maximum tickets per player"
        );

        // Treasury Manager integration for ticket sales
        treasuryManager.depositFunds(TREASURY_NAME, msg.sender, msg.value);
        game.jackpot += msg.value;

        emit TreasuryFundsDeposited(msg.value, block.timestamp);
        game.playerCount += ticketCount;

        // Add player to game if not already present (optimized)
        bool isNewPlayer = true;
        for (uint i = 0; i < playerCount; i++) {
            if (game.players[i] == msg.sender) {
                isNewPlayer = false;
                break;
            }
        }

        if (isNewPlayer) {
            game.players.push(msg.sender);
        }

        // Process referral system for each ticket
        for (uint i = 0; i < ticketCount; i++) {
            _processReferralSystem(partner, msg.sender);
        }

        // Emit ticket events in batch to save gas
        uint256 gameNumber = game.gameNumber;
        uint256 timestamp = block.timestamp;
        for (uint i = 0; i < ticketCount; i++) {
            uint playerNumber = game.players.length - 1 + i;
            emit TicketPurchased(
                msg.sender,
                gameNumber,
                playerNumber,
                timestamp
            );
        }
    }

    /**
     * @dev Pick the winner.
     * @dev Check game players, depends on player count provides next logic:
     * @dev - if in the game is only one player, by the game rules the whole jackpot
     * @dev without commission returns to that player.
     * @dev - if more than one player is in the game then smart contract randomly selects one player,
     * @dev calculates commission and after that the jackpot is transferred to the winner,
     * @dev commision to founders.
     */
    function _pickWinner() internal override {
        // Cache game state to reduce storage reads
        Game storage game = currentGame;
        uint256 playerCount = game.players.length;
        uint256 jackpot = game.jackpot;

        uint winner;
        uint toPlayer;

        if (playerCount == 1) {
            toPlayer = jackpot;
            _processWinnerPayout(game.players[0], toPlayer);
            winner = 0;
        } else {
            winner = randomNumber(
                0,
                playerCount - 1,
                block.timestamp,
                block.prevrandao,
                block.number,
                blockhash(block.number - 1)
            );

            uint distribute = (jackpot * fee) / 100;
            toPlayer = jackpot - distribute;

            _processWinnerPayout(game.players[winner], toPlayer);
            _processPartnerPayments(game.players[winner]);
            _processFounderDistribution(distribute);
        }

        _updateGameStats(game.players[winner], playerCount, toPlayer, winner);
    }

    /**
     * @dev Process winner payout with treasury integration
     * @param winner Address of the winner
     * @param amount Amount to be paid to winner
     */
    function _processWinnerPayout(
        address winner,
        uint256 amount
    ) internal override {
        // Treasury Manager integration for winner payout
        treasuryManager.withdrawFunds(TREASURY_NAME, winner, amount);
        emit TreasuryFundsWithdrawn(winner, amount, block.timestamp);
    }

    /**
     * @dev Process partner payments
     * @param winner Address of the winner
     */
    function _processPartnerPayments(address winner) internal override {
        transferToPartner(winner);
    }

    /**
     * @dev Process funds distribution to founders
     * @param distribute Amount to distribute
     */
    function _processFounderDistribution(uint256 distribute) internal override {
        distribute -= paidToPartners;
        (bool result, ) = payable(fundsDistributor).call{
            value: distribute,
            gas: 30000
        }("");
        require(result, "Funds distribution failed");
    }

    /**
     * @dev Update game statistics
     * @param winner Address of the winner
     * @param playerCount Number of players
     * @param toPlayer Amount paid to winner
     * @param winnerIndex Index of winner in players array
     */
    function _updateGameStats(
        address winner,
        uint256 playerCount,
        uint256 toPlayer,
        uint256 winnerIndex
    ) internal override {
        paidToPartners = 0;
        stats.newWinner(
            winner,
            currentGame.gameNumber,
            playerCount,
            toPlayer,
            gType,
            winnerIndex
        );

        // Emit winner event immediately after winner selection
        emit WinnerSelected(
            winner,
            currentGame.gameNumber,
            toPlayer,
            block.timestamp
        );

        allTimeJackpot += toPlayer;
        allTimePlayers += playerCount;
    }

    /**
     * @dev Checks if the player is in referral system.
     * @dev Sending earned ether to partners.
     *
     * @param partner Partner address.
     * @param referral Player address.
     */
    function _processReferralSystem(
        address partner,
        address referral
    ) internal override {
        address partnerRef = referralInstance.getPartnerByReferral(referral);
        if (partner != address(0) || partnerRef != address(0)) {
            if (partnerRef == address(0)) {
                referralInstance.addReferral(partner, referral);
                partnerRef = partner;
            }

            if (currentGame.players.length > 1) {
                transferToPartner(referral);
            }
        }
    }

    /**
     * @dev Sending earned ether to partners.
     *
     * @param referral Player address.
     */
    function transferToPartner(address referral) internal {
        address partner = referralInstance.getPartnerByReferral(referral);
        if (partner != address(0)) {
            uint sum = getPartnerAmount(partner);
            if (sum != 0) {
                (bool success, ) = payable(partner).call{value: sum}("");
                require(success, "Partner transfer failed");
                paidToPartners += sum;

                emit PartnerPaid(partner, referral, sum, block.timestamp);

                transferToSalesPartner(partner);
            }
        }
    }

    /**
     * @dev Sending earned ether to sales partners.
     *
     * @param partner Partner address.
     */
    function transferToSalesPartner(address partner) internal {
        address salesPartner = referralInstance.getSalesPartnerByPartner(
            partner
        );
        if (salesPartner != address(0)) {
            uint sum = getSalesPartnerAmount(partner);
            if (sum != 0) {
                (bool success, ) = payable(salesPartner).call{value: sum}("");
                require(success, "Sales partner transfer failed");
                paidToPartners += sum;
                emit SalesPartnerPaid(
                    salesPartner,
                    partner,
                    sum,
                    block.timestamp
                );
            }
        }
    }

    /**
     * @dev Getting partner percent and calculate earned ether.
     *
     * @param partner Partner address.
     */
    function getPartnerAmount(address partner) internal view returns (uint) {
        uint256 partnerPercent = referralInstance.getPartnerPercent(partner);
        if (partnerPercent == 0) {
            return 0;
        }

        return calculateReferral(uint8(partnerPercent));
    }

    /**
     * @dev Getting sales partner percent and calculate earned ether.
     *
     * @param partner sales partner address.
     */
    function getSalesPartnerAmount(
        address partner
    ) internal view returns (uint) {
        uint256 salesPartnerPercent = referralInstance.getSalesPartnerPercent(
            partner
        );
        if (salesPartnerPercent == 0) {
            return 0;
        }

        return calculateReferral(uint8(salesPartnerPercent));
    }

    /**
     * @dev Calculate earned ether by partner percent.
     *
     * @param percent Partner percent.
     */
    function calculateReferral(uint8 percent) internal view returns (uint) {
        uint distribute = (ticketPrice * fee) / 100;

        return (distribute * percent) / 100;
    }

    /**
     * @dev Check if current game time has expired.
     */

    /**
     * @dev Start new game automatically.
     */
    function _startNewGame() internal override {
        // Allow starting new game if current game is waiting, ended, or if it's the first game
        require(
            canStartNewGame() ||
                currentGame.state == GameState.WAITING ||
                currentGame.state == GameState.ENDED ||
                currentGame.gameNumber == 0,
            "Cannot start new game yet"
        );

        // End current game if it has players
        if (currentGame.playerCount > 0) {
            _pickWinner();
        }

        // Apply new ticket price if set
        if (newPrice != 0) {
            ticketPrice = newPrice;
            newPrice = 0;
        }

        // Apply game status changes
        if (toogleStatus) {
            isActive = !isActive;
            toogleStatus = false;
        }

        // Start new game
        currentGame = Game({
            gameNumber: currentGame.gameNumber + 1,
            startTime: block.timestamp,
            endTime: block.timestamp + gameDuration,
            jackpot: 0,
            playerCount: 0,
            state: GameState.ACTIVE,
            players: new address[](0)
        });

        nextGameStartTime = currentGame.endTime;
        emit GameStarted(currentGame.gameNumber, block.timestamp);
        emit GameStateChanged(
            currentGame.gameNumber,
            GameState.ACTIVE,
            block.timestamp
        );
    }

    /**
     * @dev End current game and start new one.
     */
    function endGame() internal {
        require(isGameTimeExpired(), "Game time not expired");

        currentGame.state = GameState.ENDED;
        emit GameStateChanged(
            currentGame.gameNumber,
            GameState.ENDED,
            block.timestamp
        );

        if (currentGame.playerCount > 0) {
            _pickWinner();
        }

        // Start new game immediately
        _startNewGame();
    }

    /**
     * @dev Check and end game if time has expired.
     * @dev Anyone can call this function to end the game when time expires.
     */
    function checkAndEndGame() public {
        if (isGameTimeExpired() && currentGame.players.length > 0) {
            endGame();
        }
    }

    /**
     * @dev Get current game state.
     */
    function getCurrentGameState() public view returns (GameState) {
        return currentGame.state;
    }

    /**
     * @dev Get current game players.
     */

    /**
     * @dev Get total ticket count for current game.
     */
    function getCurrentGameTicketCount() public view returns (uint) {
        return currentGame.playerCount;
    }

    /**
     * @dev Get ticket count for a specific player in current game.
     */
    function getPlayerTicketCount(address player) public view returns (uint) {
        uint ticketCount = 0;
        uint playersLength = currentGame.players.length;
        for (uint i = 0; i < playersLength; i++) {
            if (currentGame.players[i] == player) {
                ticketCount++;
            }
        }
        return ticketCount;
    }

    /**
     * @dev Get current game information.
     */
    function getGameInfo()
        public
        view
        returns (
            uint currentGameNumber,
            uint startTime,
            uint duration,
            uint remainingTime,
            bool timeExpired,
            uint playerCount,
            uint currentJackpot
        )
    {
        return (
            currentGame.gameNumber,
            currentGame.startTime,
            gameDuration,
            getRemainingGameTime(),
            isGameTimeExpired(),
            currentGame.players.length,
            currentGame.jackpot
        );
    }

    /**
     * @dev Emergency pause function for security
     */
    function emergencyPause() external onlyOwner {
        isActive = false;
        emit GameStatusChanged(false, block.timestamp);
    }

    /**
     * @dev Emergency resume function
     */
    function emergencyResume() external onlyOwner {
        isActive = true;
        emit GameStatusChanged(true, block.timestamp);
    }

    /**
     * @dev Get contract balance
     */
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * @dev Emergency withdraw function (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Treasury Manager Management Functions
     */

    /**
     * @dev Get Treasury Manager info
     */
    function getTreasuryInfo()
        external
        view
        returns (address treasuryManagerAddress, string memory treasuryName)
    {
        return (address(treasuryManager), TREASURY_NAME);
    }

    /**
     * @dev Get Treasury balance info
     */
    function getTreasuryBalanceInfo()
        external
        view
        returns (
            uint256 totalBalance,
            uint256 reservedBalance,
            uint256 availableBalance,
            uint256 lastUpdate,
            bool isActive
        )
    {
        return treasuryManager.getTreasuryInfo(TREASURY_NAME);
    }

    /**
     * @dev Set max tickets per player
     */
}
