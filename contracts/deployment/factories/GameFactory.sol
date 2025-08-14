// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ERC1967Proxy} from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ContractRegistry} from "../../shared/utils/ContractRegistry.sol";
import {GasOptimizer} from "../../shared/utils/GasOptimizer.sol";
import {IOwnable} from "../../shared/interfaces/IOwnable.sol";
import {ICryptolottoStatsAggregator} from "../../shared/interfaces/ICryptolottoStatsAggregator.sol";
import {ICryptolottoReferral} from "../../shared/interfaces/ICryptolottoReferral.sol";

using GasOptimizer for address[];

/**
 * @title GameFactory
 * @author Cryptolotto Team
 * @notice Factory contract for creating and managing lottery games
 * @dev This contract handles the creation and management of different types of lottery games
 */
contract GameFactory is Initializable, OwnableUpgradeable {
    using GasOptimizer for uint256;

    // Custom Errors
    error InvalidGameType();
    error GameNotFound();
    error GameAlreadyExists();

    /**
     * @notice Game information structure
     * @param gameAddress The address of the game contract
     * @param gameType The type of game (ONE_DAY or SEVEN_DAYS)
     * @param isActive Whether the game is currently active
     * @param createdAt Timestamp when the game was created
     */
    struct GameInfo {
        address gameAddress; // 20 bytes
        bool isActive; // 1 byte
        GameType gameType; // 1 byte
        uint256 createdAt; // 32 bytes
    }

    /**
     * @notice Game types enumeration
     */
    enum GameType {
        ONE_DAY,
        SEVEN_DAYS
    }

    /**
     * @notice Emitted when a new game is created
     * @param gameAddress The address of the created game
     * @param gameType The type of game created
     * @param timestamp The timestamp when the game was created
     */
    event GameCreated(address indexed gameAddress, GameType indexed gameType, uint256 timestamp);

    /**
     * @notice Emitted when a game is deactivated
     * @param gameAddress The address of the deactivated game
     * @param timestamp The timestamp when the game was deactivated
     */
    event GameDeactivated(address indexed gameAddress, uint256 indexed timestamp);

    // State variables
    /**
     * @notice Mapping of game addresses to their information
     */
    mapping(address => GameInfo) public games;
    /**
     * @notice Array of all game addresses
     */
    address[] public allGames;

    // Dependencies
    /**
     * @notice Ownable contract instance
     */
    IOwnable public ownable;
    /**
     * @notice Stats aggregator contract instance
     */
    ICryptolottoStatsAggregator public statsAggregator;
    /**
     * @notice Referral system contract instance
     */
    ICryptolottoReferral public referralSystem;
    /**
     * @notice Funds distributor contract instance
     */
    address public fundsDistributor;
    /**
     * @notice Contract registry instance
     */
    ContractRegistry public registry;

    // Implementation addresses
    /**
     * @notice 1-day game implementation address
     */
    address public oneDayImplementation;
    /**
     * @notice 7-days game implementation address
     */
    address public sevenDaysImplementation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    /**
     * @notice Constructor for the GameFactory contract
     * @dev Disables initializers to prevent re-initialization
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the factory contract
     * @param owner The owner of the factory contract
     * @param ownableContract The ownable contract address
     * @param statsContract The stats aggregator contract address
     * @param referralContract The referral system contract address
     * @param distributor The funds distributor contract address
     * @param _oneDayImplementation The 1-day game implementation address
     * @param _sevenDaysImplementation The 7-days game implementation address
     * @param _registryContract The contract registry address
     */
    function initialize(
        address owner,
        address ownableContract,
        address statsContract,
        address referralContract,
        address distributor,
        address _oneDayImplementation,
        address _sevenDaysImplementation,
        address _registryContract
    ) external initializer {
        __Ownable_init();

        ownable = IOwnable(ownableContract);
        statsAggregator = ICryptolottoStatsAggregator(statsContract);
        referralSystem = ICryptolottoReferral(referralContract);
        fundsDistributor = distributor;
        oneDayImplementation = _oneDayImplementation;
        sevenDaysImplementation = _sevenDaysImplementation;
        registry = ContractRegistry(_registryContract);

        // ContractRegistry에 컨트랙트들 등록
        string[] memory contractNames = new string[](3);
        contractNames[0] = "TreasuryManager";
        contractNames[1] = "ReferralSystem";
        contractNames[2] = "StatsAggregator";

        address[] memory contractAddresses = new address[](3);
        contractAddresses[0] = distributor;
        contractAddresses[1] = referralContract;
        contractAddresses[2] = statsContract;

        registry.registerBatchContracts(contractNames, contractAddresses);
    }

    /**
     * @notice Create a new game
     * @param gameType The type of game to create
     * @return The address of the created game contract
     */
    function createGame(GameType gameType) external onlyOwner returns (address) {
        address gameAddress;

        if (gameType == GameType.ONE_DAY) {
            gameAddress = _create1DayGame();
        } else if (gameType == GameType.SEVEN_DAYS) {
            gameAddress = _create7DaysGame();
        } else {
            revert InvalidGameType();
        }

        // Register the game
        games[gameAddress] = GameInfo({
            gameAddress: gameAddress,
            gameType: gameType,
            isActive: true,
            createdAt: block.timestamp // solhint-disable-line not-rely-on-time
        });

        allGames.push(gameAddress);

        emit GameCreated(gameAddress, gameType, block.timestamp); // solhint-disable-line not-rely-on-time

        return gameAddress;
    }

    /**
     * @notice Create 1-day game
     * @return The address of the created 1-day game contract
     */
    function _create1DayGame() internal returns (address) {
        bytes memory initData = abi.encodeWithSelector(
            0x485cc955, // initialize(address,address,address,address,address,address,address)
            msg.sender,
            address(ownable),
            fundsDistributor,
            address(statsAggregator),
            address(referralSystem),
            address(0), // treasuryManager placeholder
            address(registry) // registry address
        );

        ERC1967Proxy proxy = new ERC1967Proxy(oneDayImplementation, initData);

        return address(proxy);
    }

    /**
     * @notice Create 7-days game
     * @return The address of the created 7-days game contract
     */
    function _create7DaysGame() internal returns (address) {
        bytes memory initData = abi.encodeWithSelector(
            0x485cc955, // initialize(address,address,address,address,address,address,address)
            msg.sender,
            address(ownable),
            fundsDistributor,
            address(statsAggregator),
            address(referralSystem),
            address(0), // treasuryManager placeholder
            address(registry) // registry address
        );

        ERC1967Proxy proxy = new ERC1967Proxy(sevenDaysImplementation, initData);

        return address(proxy);
    }

    /**
     * @notice Deactivate a game
     * @param gameAddress The address of the game to deactivate
     */
    function deactivateGame(address gameAddress) external onlyOwner {
        if (games[gameAddress].gameAddress == address(0)) {
            revert GameNotFound();
        }
        games[gameAddress].isActive = false;
        emit GameDeactivated(gameAddress, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Get all active games
     * @return Array of active game addresses
     */
    function getActiveGames() external view returns (address[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allGames.length; ++i) {
            if (games[allGames[i]].isActive) {
                ++activeCount;
            }
        }

        address[] memory activeGames = new address[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allGames.length; ++i) {
            if (games[allGames[i]].isActive) {
                activeGames[index] = allGames[i];
                ++index;
            }
        }

        return activeGames;
    }

    /**
     * @notice Get game info
     * @param gameAddress The address of the game
     * @return GameInfo structure containing game details
     */
    function getGameInfo(address gameAddress) external view returns (GameInfo memory) {
        return games[gameAddress];
    }

    /**
     * @notice Set implementation addresses
     * @param _oneDayImplementation The 1-day game implementation address
     * @param _sevenDaysImplementation The 7-days game implementation address
     */
    function setImplementations(address _oneDayImplementation, address _sevenDaysImplementation) external onlyOwner {
        oneDayImplementation = _oneDayImplementation;
        sevenDaysImplementation = _sevenDaysImplementation;
    }

    /**
     * @notice Get all games
     * @return Array of all game addresses
     */
    function getAllGames() external view returns (address[] memory) {
        return allGames;
    }

    /**
     * @notice Get game count
     * @return The total number of games
     */
    function getGameCount() external view returns (uint256) {
        return allGames.length;
    }

    /**
     * @notice Get games by type
     * @param gameType The type of games to retrieve
     * @return Array of game addresses of the specified type
     */
    function getGamesByType(GameType gameType) external view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allGames.length; ++i) {
            if (games[allGames[i]].gameType == gameType) {
                ++count;
            }
        }

        address[] memory gamesByType = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allGames.length; ++i) {
            if (games[allGames[i]].gameType == gameType) {
                gamesByType[index] = allGames[i];
                ++index;
            }
        }

        return gamesByType;
    }
}
