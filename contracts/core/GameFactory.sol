// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../games/Cryptolotto1Day.sol";
import "../games/Cryptolotto7Days.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/ICryptolottoStatsAggregator.sol";
import "../interfaces/ICryptolottoReferral.sol";

/**
 * @title GameFactory
 * @dev 게임 컨트랙트 생성을 관리하는 팩토리 컨트랙트
 */
contract GameFactory is Initializable, OwnableUpgradeable {
    // Game type enum
    enum GameType {
        ONE_DAY,
        SEVEN_DAYS
    }

    // Game info struct
    struct GameInfo {
        address gameAddress;
        GameType gameType;
        bool isActive;
        uint createdAt;
    }

    // Events
    event GameCreated(
        address indexed gameAddress,
        GameType gameType,
        uint timestamp
    );
    event GameDeactivated(address indexed gameAddress, uint timestamp);

    // State variables
    mapping(address => GameInfo) public games;
    address[] public allGames;

    // Contract addresses
    IOwnable public ownable;
    ICryptolottoStatsAggregator public statsAggregator;
    ICryptolottoReferral public referralSystem;
    address public fundsDistributor;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address ownableContract,
        address statsContract,
        address referralContract,
        address distributor
    ) public initializer {
        __Ownable_init(owner);
        ownable = IOwnable(ownableContract);
        statsAggregator = ICryptolottoStatsAggregator(statsContract);
        referralSystem = ICryptolottoReferral(referralContract);
        fundsDistributor = distributor;
    }

    /**
     * @dev Create a new game contract
     */
    function createGame(
        GameType gameType
    ) external onlyOwner returns (address) {
        address gameAddress;

        if (gameType == GameType.ONE_DAY) {
            gameAddress = _create1DayGame();
        } else if (gameType == GameType.SEVEN_DAYS) {
            gameAddress = _create7DaysGame();
        } else {
            revert("Invalid game type");
        }

        // Register the game
        games[gameAddress] = GameInfo({
            gameAddress: gameAddress,
            gameType: gameType,
            isActive: true,
            createdAt: block.timestamp
        });

        allGames.push(gameAddress);

        emit GameCreated(gameAddress, gameType, block.timestamp);

        return gameAddress;
    }

    /**
     * @dev Create 1-day game
     */
    function _create1DayGame() internal returns (address) {
        Cryptolotto1Day implementation = new Cryptolotto1Day();

        bytes memory initData = abi.encodeWithSelector(
            Cryptolotto1Day.initialize.selector,
            msg.sender,
            address(ownable),
            fundsDistributor,
            address(statsAggregator),
            address(referralSystem)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        return address(proxy);
    }

    /**
     * @dev Create 7-days game
     */
    function _create7DaysGame() internal returns (address) {
        Cryptolotto7Days implementation = new Cryptolotto7Days();

        bytes memory initData = abi.encodeWithSelector(
            Cryptolotto7Days.initialize.selector,
            msg.sender,
            address(ownable),
            fundsDistributor,
            address(statsAggregator),
            address(referralSystem)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        return address(proxy);
    }

    /**
     * @dev Deactivate a game
     */
    function deactivateGame(address gameAddress) external onlyOwner {
        require(games[gameAddress].gameAddress != address(0), "Game not found");
        games[gameAddress].isActive = false;
        emit GameDeactivated(gameAddress, block.timestamp);
    }

    /**
     * @dev Get all active games
     */
    function getActiveGames() external view returns (address[] memory) {
        uint activeCount = 0;
        for (uint i = 0; i < allGames.length; i++) {
            if (games[allGames[i]].isActive) {
                activeCount++;
            }
        }

        address[] memory activeGames = new address[](activeCount);
        uint index = 0;
        for (uint i = 0; i < allGames.length; i++) {
            if (games[allGames[i]].isActive) {
                activeGames[index] = allGames[i];
                index++;
            }
        }

        return activeGames;
    }

    /**
     * @dev Get game info
     */
    function getGameInfo(
        address gameAddress
    ) external view returns (GameInfo memory) {
        return games[gameAddress];
    }
}
