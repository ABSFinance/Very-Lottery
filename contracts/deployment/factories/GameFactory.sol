// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../shared/interfaces/ITreasuryManager.sol";
import "../../shared/utils/ContractRegistry.sol";
import "../../shared/utils/GasOptimizer.sol";
import "../../shared/interfaces/IOwnable.sol";
import "../../shared/interfaces/ICryptolottoStatsAggregator.sol";
import "../../shared/interfaces/ICryptolottoReferral.sol";

using GasOptimizer for address[];

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
    address public registry;

    // Implementation addresses
    address public oneDayImplementation;
    address public sevenDaysImplementation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address ownableContract,
        address statsContract,
        address referralContract,
        address distributor,
        address _oneDayImplementation,
        address _sevenDaysImplementation,
        address _registryContract
    ) public initializer {
        __Ownable_init(owner);
        ownable = IOwnable(ownableContract);
        statsAggregator = ICryptolottoStatsAggregator(statsContract);
        referralSystem = ICryptolottoReferral(referralContract);
        fundsDistributor = distributor;
        oneDayImplementation = _oneDayImplementation;
        sevenDaysImplementation = _sevenDaysImplementation;
        registry = _registryContract;

        // ContractRegistry에 컨트랙트들 등록
        ContractRegistry registryInstance = ContractRegistry(_registryContract);
        string[] memory contractNames = new string[](3);
        contractNames[0] = "TreasuryManager";
        contractNames[1] = "CryptolottoReferral";
        contractNames[2] = "StatsAggregator";

        address[] memory contractAddresses = new address[](3);
        contractAddresses[0] = address(0);
        contractAddresses[1] = referralContract;
        contractAddresses[2] = statsContract;

        registryInstance.registerBatchContracts(
            contractNames,
            contractAddresses
        );
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
     * @dev Create 7-days game
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

        ERC1967Proxy proxy = new ERC1967Proxy(
            sevenDaysImplementation,
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

    /**
     * @dev Set implementation addresses
     */
    function setImplementations(
        address _oneDayImplementation,
        address _sevenDaysImplementation
    ) external onlyOwner {
        oneDayImplementation = _oneDayImplementation;
        sevenDaysImplementation = _sevenDaysImplementation;
    }

    function getAllGames() public view returns (address[] memory) {
        address[] storage allGamesArr = allGames;
        uint256 length = allGamesArr.length;
        address[] memory result = new address[](length);
        for (uint i = 0; i < length; i++) {
            result[i] = allGamesArr[i];
        }
        return result;
    }

    function getGameCount() public view returns (uint) {
        return allGames.length;
    }

    function getGamesByType(
        string memory /* gameType */
    ) public view returns (address[] memory) {
        address[] storage allGamesArr = allGames;
        uint256 length = allGamesArr.length;
        address[] memory temp = new address[](length);
        uint256 count = 0;

        for (uint i = 0; i < length; i++) {
            // 여기서는 간단한 예시로 모든 게임을 반환
            // 실제로는 게임 타입을 체크하는 로직이 필요
            temp[count] = allGamesArr[i];
            count++;
        }

        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = temp[i];
        }

        return result;
    }
}
