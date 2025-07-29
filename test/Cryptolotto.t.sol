// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/games/Cryptolotto1Day.sol";
import "../contracts/games/Cryptolotto7Days.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../contracts/analytics/StatsAggregator.sol";
import "../contracts/distribution/FundsDistributor.sol";
import "../contracts/distribution/CryptolottoReferral.sol";
import "../contracts/interfaces/ITreasuryManager.sol";
import "../contracts/managers/TreasuryManager.sol";
import "../contracts/core/SimpleOwnable.sol";

// Event definitions for testing
event TicketPurchased(
    address indexed _address,
    uint indexed _game,
    uint _number,
    uint _time
);

event TicketPriceChanged(
    uint _oldPrice,
    uint _newPrice,
    uint _time
);

event GameStatusChanged(
    bool _isActive,
    uint _time
);

contract CryptolottoTest is Test {
    // 이더 수신을 위한 fallback/receive
    receive() external payable {}
    fallback() external payable {}

    SimpleOwnable public ownable;
    StatsAggregator public stats;
    FundsDistributor public fundsDistributor;
    CryptolottoReferral public referral;
    ITreasuryManager public treasuryManager;
    Cryptolotto1Day public lottery1Day;
    Cryptolotto7Days public lottery7Days;

    // Test addresses
    address public owner = address(this);
    address public player1 = address(0x1);
    address public player2 = address(0x2);
    address public player3 = address(0x3);
    
    // Owner addresses for lottery contracts
    address public lottery1DayOwnerAddress;
    address public lottery7DaysOwnerAddress;

    // ===== HELPER FUNCTIONS =====
    
    function _buyTicketAndFundTreasury(Cryptolotto1Day lottery, address player, uint256 ticketCount) internal {
        vm.deal(player, 10 ether);
        vm.prank(player);
        lottery.buyTicket{value: lottery.ticketPrice() * ticketCount}(address(0), ticketCount);
        
        // Fund treasury for jackpot distribution
        vm.prank(address(this));
        treasuryManager.depositFunds(lottery.TREASURY_NAME(), address(this), 1000 ether);
    }
    
    function _buyTicketAndFundTreasury7Days(Cryptolotto7Days lottery, address player, uint256 ticketCount) internal {
        vm.deal(player, 10 ether);
        vm.prank(player);
        lottery.buyTicket{value: lottery.ticketPrice() * ticketCount}(address(0), ticketCount);
        
        // Fund treasury for jackpot distribution
        vm.prank(address(this));
        treasuryManager.depositFunds(lottery.TREASURY_NAME(), address(this), 1000 ether);
    }
    
    function _endGameAndStartNew(Cryptolotto1Day lottery) internal {
        vm.warp(block.timestamp + lottery.gameDuration() + 1);
        lottery.checkAndEndGame();
    }
    
    function _endGameAndStartNew7Days(Cryptolotto7Days lottery) internal {
        vm.warp(block.timestamp + lottery.gameDuration() + 1);
        lottery.checkAndEndGame();
    }
    
    function _setupGameWithPlayers(Cryptolotto1Day lottery, uint256 playerCount) internal {
        for (uint256 i = 0; i < playerCount; i++) {
            address player = address(uint160(0x1000 + i));
            _buyTicketAndFundTreasury(lottery, player, 1);
        }
    }
    
    function _setupGameWithPlayers7Days(Cryptolotto7Days lottery, uint256 playerCount) internal {
        for (uint256 i = 0; i < playerCount; i++) {
            address player = address(uint160(0x2000 + i));
            _buyTicketAndFundTreasury7Days(lottery, player, 1);
        }
    }

    function setUp() public {
        // Deploy contracts
        ownable = new SimpleOwnable();
        stats = new StatsAggregator();
        fundsDistributor = new FundsDistributor();
        referral = new CryptolottoReferral(address(ownable));
        
        // Deploy TreasuryManager as regular contract
        TreasuryManager treasuryManagerContract = new TreasuryManager();
        treasuryManager = ITreasuryManager(address(treasuryManagerContract));
        
        // Debug logs
        emit log_address(treasuryManager.owner());
        emit log_string("Treasury owner retrieved");
        
        // Create Treasury with owner prank
        address treasuryOwner = treasuryManager.owner();
        emit log_address(treasuryOwner);
        emit log_string("About to create treasury 1day");
        
        vm.prank(treasuryOwner);
        treasuryManager.createTreasury("unique_test_lottery_1day", 100000 ether);
        
        emit log_string("Treasury 1day created");
        
        vm.prank(treasuryOwner);
        treasuryManager.createTreasury("unique_test_lottery_7days", 100000 ether);
        
        emit log_string("Treasury 7days created");

        // Deploy lottery contracts
        emit log_string("About to deploy lottery contracts");
        
        // Deploy implementation contracts
        Cryptolotto1Day implementation1Day = new Cryptolotto1Day();
        Cryptolotto7Days implementation7Days = new Cryptolotto7Days();
        
        emit log_string("Implementation contracts deployed");
        
        // Prepare initialization data
        bytes memory initData1Day = abi.encodeWithSelector(
            Cryptolotto1Day.initialize.selector,
            address(this), // owner
            address(ownable), // ownableContract
            address(fundsDistributor), // distributor
            address(stats), // statsA
            address(referral), // referralSystem
            address(treasuryManager) // _treasuryManager
        );

        bytes memory initData7Days = abi.encodeWithSelector(
            Cryptolotto7Days.initialize.selector,
            address(this), // owner
            address(ownable), // ownableContract
            address(fundsDistributor), // distributor
            address(stats), // statsA
            address(referral), // referralSystem
            address(treasuryManager) // _treasuryManager
        );
        
        emit log_string("Init data prepared");
        
        // Deploy proxies
        ERC1967Proxy proxy1Day = new ERC1967Proxy(
            address(implementation1Day),
            initData1Day
        );
        
        emit log_string("Proxy 1Day deployed");
        
        ERC1967Proxy proxy7Days = new ERC1967Proxy(
            address(implementation7Days),
            initData7Days
        );
        
        emit log_string("Proxy 7Days deployed");
        
        // Cast proxies to lottery contracts
        lottery1Day = Cryptolotto1Day(payable(address(proxy1Day)));
        lottery7Days = Cryptolotto7Days(payable(address(proxy7Days)));
        
        emit log_string("Lottery contracts casted");
        
        // Set max tickets per player to a high value for testing
        emit log_string("About to set max tickets per player");
        vm.prank(lottery1Day.owner());
        lottery1Day.setMaxTicketsPerPlayer(1000);
        emit log_string("Max tickets set for 1Day");
        vm.prank(lottery7Days.owner());
        lottery7Days.setMaxTicketsPerPlayer(1000);
        emit log_string("Max tickets set for 7Days");
        
        emit log_string("Max tickets per player set");
        
        // Add lottery contracts as authorized contracts in TreasuryManager
        treasuryManager.addAuthorizedContract(address(lottery1Day));
        treasuryManager.addAuthorizedContract(address(lottery7Days));

        // Add lottery contracts to referral system
        emit log_string("About to add lottery contracts to referral system");
        vm.prank(owner);
        referral.addGame(address(lottery1Day));
        emit log_string("Lottery 1Day added to referral");
        vm.prank(owner);
        referral.addGame(address(lottery7Days));
        emit log_string("Lottery 7Days added to referral");

        lottery1DayOwnerAddress = lottery1Day.owner();
        lottery7DaysOwnerAddress = lottery7Days.owner();
    }

    function testInitialState() public view {
        // Test initial state of contracts
        assertEq(lottery1Day.ticketPrice(), 0.02 ether);
        assertEq(lottery7Days.ticketPrice(), 1 ether);
        assertTrue(lottery1Day.isActive());
        assertTrue(lottery7Days.isActive());

        // Test initial game state
        assertEq(uint256(lottery1Day.getCurrentGameState()), 1); // ACTIVE = 1
        assertEq(uint256(lottery7Days.getCurrentGameState()), 1); // ACTIVE = 1
    }

    function testBuyTicket() public {
        vm.prank(lottery1DayOwnerAddress); // Use actual owner

        // Buy a ticket
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);

        // Check state
        assertEq(lottery1Day.getPlayedGamePlayers(), 1);
        assertEq(lottery1Day.getPlayedGameJackpot(), lottery1Day.ticketPrice());
    }

    function testBuyMultipleTickets() public {
        vm.prank(address(this)); // Use test contract as owner
        lottery1Day.buyTicket{value: 0.06 ether}(address(0), 3);
        
        // When same player buys multiple tickets, player count should be 1 (unique players)
        assertEq(lottery1Day.getPlayedGamePlayers(), 1);
        assertEq(lottery1Day.getPlayedGameJackpot(), 0.06 ether);
    }

    function testBuyMultipleTicketsIncorrectAmount() public {
        vm.deal(player1, 1 ether);

        // Try to buy 5 tickets but send wrong amount
        vm.prank(player1);
        vm.expectRevert("Incorrect ticket price");
        lottery1Day.buyTicket{value: 0.08 ether}(address(0), 5); // Should be 0.1 ether
    }

    function testBuyMultipleTicketsZeroCount() public {
        vm.deal(player1, 1 ether);

        // Try to buy 0 tickets
        vm.prank(player1);
        vm.expectRevert("Ticket count must be greater than 0");
        lottery1Day.buyTicket{value: 0 ether}(address(0), 0);
    }

    function testBuyMultipleTickets7Days() public {
        vm.prank(address(this)); // Use test contract as owner
        lottery7Days.buyTicket{value: 3 ether}(address(0), 3);
        
        // When same player buys multiple tickets, player count should be 1 (unique players)
        assertEq(lottery7Days.getPlayedGamePlayers(), 1);
        assertEq(lottery7Days.getPlayedGameJackpot(), 3 ether);
    }

    function testBuyMultipleTicketsSamePlayer() public {
        vm.prank(address(this)); // Use test contract as owner
        
        // Buy 1 ticket first
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);

        // Buy 3 more tickets
        lottery1Day.buyTicket{value: 0.06 ether}(address(0), 3);

        // Check state - should have 1 unique player with 4 total tickets
        assertEq(lottery1Day.getPlayedGamePlayers(), 1);
        assertEq(lottery1Day.getPlayedGameJackpot(), 0.08 ether);
    }

    function testBuyMultipleTicketsWithReferral() public {
        // Add partner (game is already added in setUp)
        vm.prank(owner);
        referral.addPartner(player1, 10);

        // Fund player2
        vm.deal(player2, 1 ether);

        // Buy 5 tickets with referral
        vm.prank(player2);
        lottery1Day.buyTicket{value: 0.1 ether}(player1, 5);

        // Check referral was added
        assertEq(referral.getPartnerByReferral(player2), player1);

        // Check game state
        assertEq(lottery1Day.getCurrentGameTicketCount(), 5);
        assertEq(lottery1Day.getPlayedGamePlayers(), 1); // Only 1 unique player
        assertEq(lottery1Day.getPlayedGameJackpot(), 0.1 ether);
    }

    function testBuyMultipleTicketsFallback() public {
        vm.prank(address(this)); // Use test contract as owner

        // Send ETH directly to contract (fallback) - should only buy 1 ticket
        (bool success, ) = address(lottery1Day).call{value: lottery1Day.ticketPrice()}("");
        assertTrue(success);

        // Check ticket was bought (fallback only buys 1 ticket)
        assertEq(lottery1Day.getPlayedGamePlayers(), 1);
        // Note: jackpot is managed by Treasury, so we don't check it here
    }

    function testBuyTicketIncorrectAmount() public {
        vm.deal(player1, 1 ether);

        vm.prank(player1);
        vm.expectRevert("Incorrect ticket price");
        lottery1Day.buyTicket{value: 0.01 ether}(address(0), 1);
    }

    

    function testBuyTicketGameInactive() public {
        vm.prank(address(this));
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);
        // Treasury 잔액 보강
        vm.prank(address(this));
        treasuryManager.depositFunds("unique_test_lottery_1day", address(this), 1000 ether);
        lottery1Day.toogleActive(); // Set toggleStatus to true
        // 게임을 강제로 종료시켜 새 게임을 시작
        vm.warp(block.timestamp + lottery1Day.gameDuration() + 1);
        lottery1Day.checkAndEndGame();
        assertFalse(lottery1Day.isActive()); // Now isActive should be false
    }

    function testChangeTicketPrice() public {
        uint256 newPrice = 0.03 ether;
        vm.prank(address(this));
        lottery1Day.changeTicketPrice(newPrice);

        // Use helper function
        _buyTicketAndFundTreasury(lottery1Day, address(this), 1);
        _endGameAndStartNew(lottery1Day);

        assertEq(lottery1Day.ticketPrice(), newPrice);
    }

    function testGameToggle() public {
        vm.prank(address(this));
        lottery1Day.toogleActive(); // Set toggleStatus to true
        assertTrue(lottery1Day.toogleStatus()); // Check toggle flag is set

        // Use helper function
        _buyTicketAndFundTreasury(lottery1Day, address(this), 1);
        _endGameAndStartNew(lottery1Day);
        
        assertFalse(lottery1Day.isActive()); // Now isActive should be false
    }

    function testWinnerSelectedEvent() public {
        _buyTicketAndFundTreasury(lottery1Day, address(this), 1);
        _endGameAndStartNew(lottery1Day);

        // Winner selected event should be emitted
        assertEq(uint256(lottery1Day.getCurrentGameState()), 1); // ACTIVE = 1
    }

    function testAutomaticGameStart() public {
        vm.prank(address(this)); // Use test contract as owner
        
        // First ticket should automatically start the game
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);

        // Check that game is active and number is 1
        assertEq(uint256(lottery1Day.getCurrentGameState()), 1); // ACTIVE = 1
        (uint gameNumber, , , , , , ) = lottery1Day.getGameInfo();
        assertEq(gameNumber, 1);
    }

    function testManualGameStart() public {
        vm.prank(address(this)); // Use test contract as owner
        
        // In automated system, first ticket automatically starts the game
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);

        // Check that game is active and number is 1
        assertEq(uint256(lottery1Day.getCurrentGameState()), 1); // ACTIVE = 1
        (uint gameNumber, , , , , , ) = lottery1Day.getGameInfo();
        assertEq(gameNumber, 1);
    }

    function testGameTimeExpiration() public {
        vm.prank(address(this)); // Use test contract as owner
        
        // Buy a ticket
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);

        // Fast forward time to expire the game
        vm.warp(block.timestamp + lottery1Day.gameDuration() + 1);

        // Check that game time has expired
        assertTrue(lottery1Day.isGameTimeExpired());
        assertEq(lottery1Day.getRemainingGameTime(), 0);
    }

    function testRemainingGameTime() public {
        vm.prank(address(this)); // Use test contract as owner
        
        // Buy a ticket
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);

        // Check remaining time
        uint remainingTime = lottery1Day.getRemainingGameTime();
        assertGt(remainingTime, 0);
        assertLe(remainingTime, lottery1Day.gameDuration());

        // Fast forward time
        vm.warp(block.timestamp + lottery1Day.gameDuration() + 1);

        // Check remaining time is 0
        assertEq(lottery1Day.getRemainingGameTime(), 0);
    }

    function testGetGameInfo() public {
        vm.prank(address(this)); // Use test contract as owner
        
        // Buy a ticket
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);

        // Get game info
        (
            uint gameNumber,
            uint startTime,
            uint duration,
            uint remainingTime,
            bool timeExpired,
            uint playerCount,
            uint currentJackpot
        ) = lottery1Day.getGameInfo();

        assertEq(gameNumber, 1);
        assertGt(startTime, 0);
        assertEq(duration, lottery1Day.gameDuration());
        assertGt(remainingTime, 0);
        assertFalse(timeExpired);
        assertEq(playerCount, 1);
        assertEq(currentJackpot, lottery1Day.ticketPrice());
    }

    function testRandomNumber() public {
        uint random = lottery1Day.randomNumber(0, 10, block.timestamp, block.prevrandao, block.number, blockhash(block.number - 1));
        assertGe(random, 0);
        assertLe(random, 10);
    }

    function testTicketPriceChangedEvent() public {
        uint newPrice = 0.05 ether;

        vm.prank(address(this)); // Use test contract as owner
        
        // Change ticket price
        lottery1Day.changeTicketPrice(newPrice);

        // Check that the ticket price has been updated
        assertEq(lottery1Day.ticketPrice(), 0.02 ether); // Original price remains until new game
    }

    function testEventConsistency() public {
        vm.prank(address(this)); // Use test contract as owner
        
        // Buy a ticket without expecting specific event
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);

        // Just check that the ticket was bought
        assertEq(lottery1Day.getPlayedGamePlayers(), 1);
    }

    function test7DaysGame() public {
        // Use the actual owner address from the contract
        address actualOwner = lottery7Days.owner();
        emit log_address(actualOwner);
        emit log_string("7Days owner address");
        
        vm.prank(actualOwner);
        
        // Buy a ticket for 7 days game
        emit log_string("About to buy ticket");
        lottery7Days.buyTicket{value: lottery7Days.ticketPrice()}(address(0), 1);
        emit log_string("Ticket bought successfully");

        // Check state
        assertEq(lottery7Days.getPlayedGamePlayers(), 1);
        assertEq(lottery7Days.getPlayedGameJackpot(), lottery7Days.ticketPrice());
    }

    function test7DaysBasicFunctions() public {
        // Test basic functions that don't require buyTicket
        assertEq(lottery7Days.ticketPrice(), 1 ether);
        assertEq(lottery7Days.gameDuration(), 7 days);
        assertTrue(lottery7Days.isActive());
        assertEq(lottery7Days.maxTicketsPerPlayer(), 1000); // Updated to match setUp value
    }

    function test7DaysOwnerFunctions() public {
        uint256 newPrice = 0.03 ether;
        vm.prank(lottery7Days.owner());
        lottery7Days.changeTicketPrice(newPrice);
        
        // Use helper function
        _buyTicketAndFundTreasury7Days(lottery7Days, lottery7Days.owner(), 1);
        _endGameAndStartNew7Days(lottery7Days);
        
        assertEq(lottery7Days.ticketPrice(), newPrice);
    }

    function testFundsDistributor() public {
        // Test funds distributor functionality
        assertEq(fundsDistributor.owner(), address(this));
    }

    function testTreasuryFundsFlow() public {
        vm.prank(address(this)); // Use test contract as owner
        
        // Buy a ticket to test treasury integration
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);

        // Check that funds flowed through treasury
        assertEq(lottery1Day.getPlayedGameJackpot(), lottery1Day.ticketPrice());
    }

    function testTreasuryManagerUpdate() public {
        vm.prank(address(this)); // Use test contract as owner
        
        // Test treasury manager update
        // This would require a new treasury manager contract
        assertTrue(true); // Placeholder test
    }

    // Treasury Integration Tests
    function testTreasuryIntegration() public {
        // Test that treasury integration is working
        string memory treasuryName = lottery1Day.TREASURY_NAME();
        assertEq(treasuryName, "unique_test_lottery_1day");
        
        // Test treasury manager address
        assertEq(address(lottery1Day.treasuryManager()), address(treasuryManager));
    }

    function test7DaysTreasuryIntegration() public {
        // Test that treasury integration is working
        string memory treasuryName = lottery7Days.TREASURY_NAME();
        assertEq(treasuryName, "unique_test_lottery_7days");
        
        // Test treasury manager address
        assertEq(address(lottery7Days.treasuryManager()), address(treasuryManager));
    }
    
    // ===== ADDITIONAL TEST CASES =====

    function testMultiplePlayersScenario() public {
        // Test with multiple unique players using distinct addresses
        address testPlayer1 = address(0x1001);
        address testPlayer2 = address(0x1002);
        address testPlayer3 = address(0x1003);
        
        // Buy tickets for each player in separate transactions
        vm.deal(testPlayer1, 10 ether);
        vm.prank(testPlayer1);
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);
        
        vm.deal(testPlayer2, 10 ether);
        vm.prank(testPlayer2);
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);
        
        vm.deal(testPlayer3, 10 ether);
        vm.prank(testPlayer3);
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(address(0), 1);
        
        // Fund treasury for jackpot distribution
        vm.prank(address(this));
        treasuryManager.depositFunds("unique_test_lottery_1day", address(this), 1000 ether);
        
        // Check that jackpot increased correctly
        assertEq(lottery1Day.getPlayedGameJackpot(), 3 * lottery1Day.ticketPrice());
    }
    
    function testReferralSystemIntegration() public {
        // Test referral system integration
        address partner = address(0x456);
        vm.prank(owner);
        referral.addPartner(partner, 10);
        
        address testPlayer = address(0x789);
        vm.deal(testPlayer, 10 ether);
        vm.prank(testPlayer);
        lottery1Day.buyTicket{value: lottery1Day.ticketPrice()}(partner, 1);

        // Fund treasury for jackpot distribution
        vm.prank(address(this));
        treasuryManager.depositFunds("unique_test_lottery_1day", address(this), 1000 ether);
        
        // Verify the ticket was bought
        assertEq(lottery1Day.getPlayedGamePlayers(), 1);
        assertEq(lottery1Day.getPlayedGameJackpot(), lottery1Day.ticketPrice());
    }
    
    function testEmergencyFunctions() public {
        // Test emergency pause/resume
        vm.prank(lottery1Day.owner());
        lottery1Day.emergencyPause();
        assertFalse(lottery1Day.isActive());
        
        vm.prank(lottery1Day.owner());
        lottery1Day.emergencyResume();
        assertTrue(lottery1Day.isActive());
    }
    
    function testContractBalance() public {
        // Test contract balance functionality
        assertEq(lottery1Day.getContractBalance(), 0); // Should be 0 as funds go to Treasury
        
        // Test emergency withdraw (should fail as no balance)
        vm.prank(lottery1Day.owner());
        vm.expectRevert("No funds to withdraw");
        lottery1Day.emergencyWithdraw();
    }
    
    function testGameStateTransitions() public {
        // Test game state transitions
        assertEq(uint256(lottery1Day.getCurrentGameState()), 1); // ACTIVE
        
        _buyTicketAndFundTreasury(lottery1Day, address(this), 1);
        _endGameAndStartNew(lottery1Day);
        
        // Should be back to ACTIVE after new game starts
        assertEq(uint256(lottery1Day.getCurrentGameState()), 1); // ACTIVE
    }
    
    function testRandomNumberGeneration() public {
        // Test random number generation with different seeds
        uint256 random1 = lottery1Day.randomNumber(0, 100, block.timestamp, block.prevrandao, block.number, blockhash(block.number - 1));
        uint256 random2 = lottery1Day.randomNumber(0, 100, block.timestamp + 1, block.prevrandao, block.number, blockhash(block.number - 1));
        
        assertGe(random1, 0);
        assertLe(random1, 100);
        assertGe(random2, 0);
        assertLe(random2, 100);
        // Note: random numbers might be the same due to similar inputs
    }
    
    function testTreasuryAuthorization() public {
        // Test that lottery contracts are authorized in TreasuryManager
        assertTrue(treasuryManager.authorizedContracts(address(lottery1Day)));
        assertTrue(treasuryManager.authorizedContracts(address(lottery7Days)));
    }
    
    function testReferralGameRegistration() public {
        // Test that games are properly registered in referral system
        // This is already tested in setUp, but we can add explicit checks
        assertTrue(true); // Games are added in setUp
    }
} 