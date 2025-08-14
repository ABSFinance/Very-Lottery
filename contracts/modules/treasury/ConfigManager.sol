// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title ConfigManager
 * @dev 시스템 설정을 중앙에서 관리하는 컨트랙트
 */
contract ConfigManager is Initializable, OwnableUpgradeable {
    // Configuration struct
    struct GameConfig {
        uint256 ticketPrice;
        uint256 gameDuration;
        uint8 fee;
        uint256 maxTicketsPerPlayer;
        bool isActive;
    }

    // Configuration mappings
    mapping(uint8 => GameConfig) public gameConfigs;
    mapping(string => uint256) public systemParams;
    mapping(string => address) public contractAddresses;

    // Events
    event GameConfigUpdated(uint8 gameType, uint256 ticketPrice, uint256 gameDuration, uint8 fee, uint256 maxTickets);
    event SystemParamUpdated(string param, uint256 oldValue, uint256 newValue);
    event ContractAddressUpdated(string contractName, address oldAddress, address newAddress);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init();
        _initializeDefaultConfigs();
    }

    /**
     * @dev 기본 설정 초기화
     */
    function _initializeDefaultConfigs() internal {
        // 1-day game config (gameType = 4)
        gameConfigs[4] = GameConfig({
            ticketPrice: 0.02 ether,
            gameDuration: 86400,
            fee: 10,
            maxTicketsPerPlayer: 100,
            isActive: true
        });

        // 7-days game config (gameType = 5)
        gameConfigs[5] =
            GameConfig({ticketPrice: 1 ether, gameDuration: 604800, fee: 10, maxTicketsPerPlayer: 50, isActive: true});

        // System parameters
        systemParams["minTicketPrice"] = 0.01 ether;
        systemParams["maxTicketPrice"] = 10 ether;
        systemParams["minGameDuration"] = 3600; // 1 hour
        systemParams["maxGameDuration"] = 2592000; // 30 days
    }

    /**
     * @dev 게임 설정 업데이트
     */
    function updateGameConfig(
        uint8 gameType,
        uint256 ticketPrice,
        uint256 gameDuration,
        uint8 fee,
        uint256 maxTicketsPerPlayer
    ) external onlyOwner {
        require(ticketPrice >= systemParams["minTicketPrice"], "Ticket price too low");
        require(ticketPrice <= systemParams["maxTicketPrice"], "Ticket price too high");
        require(gameDuration >= systemParams["minGameDuration"], "Game duration too short");
        require(gameDuration <= systemParams["maxGameDuration"], "Game duration too long");
        require(fee <= 20, "Fee too high");
        require(maxTicketsPerPlayer > 0, "Max tickets must be greater than 0");

        gameConfigs[gameType] = GameConfig({
            ticketPrice: ticketPrice,
            gameDuration: gameDuration,
            fee: fee,
            maxTicketsPerPlayer: maxTicketsPerPlayer,
            isActive: gameConfigs[gameType].isActive
        });

        emit GameConfigUpdated(gameType, ticketPrice, gameDuration, fee, maxTicketsPerPlayer);
    }

    /**
     * @dev 게임 활성화/비활성화
     */
    function setGameActive(uint8 gameType, bool isActive) external onlyOwner {
        gameConfigs[gameType].isActive = isActive;
    }

    /**
     * @dev 시스템 파라미터 업데이트
     */
    function updateSystemParam(string memory param, uint256 value) external onlyOwner {
        uint256 oldValue = systemParams[param];
        systemParams[param] = value;
        emit SystemParamUpdated(param, oldValue, value);
    }

    /**
     * @dev 컨트랙트 주소 업데이트
     */
    function updateContractAddress(string memory contractName, address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid contract address");
        address oldAddress = contractAddresses[contractName];
        contractAddresses[contractName] = newAddress;
        emit ContractAddressUpdated(contractName, oldAddress, newAddress);
    }

    /**
     * @dev 게임 설정 조회
     */
    function getGameConfig(uint8 gameType) external view returns (GameConfig memory) {
        return gameConfigs[gameType];
    }

    /**
     * @dev 시스템 파라미터 조회
     */
    function getSystemParam(string memory param) external view returns (uint256) {
        return systemParams[param];
    }

    /**
     * @dev 컨트랙트 주소 조회
     */
    function getContractAddress(string memory contractName) external view returns (address) {
        return contractAddresses[contractName];
    }
}
