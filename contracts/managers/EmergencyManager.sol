// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title EmergencyManager
 * @dev 긴급 상황을 중앙에서 관리하는 컨트랙트
 */
contract EmergencyManager is Initializable, OwnableUpgradeable {
    // Emergency state
    bool public emergencyPaused;

    // Contract registry
    mapping(address => bool) public registeredContracts;
    address[] public allContracts;

    // Events
    event EmergencyPaused(address indexed by, uint timestamp);
    event EmergencyResumed(address indexed by, uint timestamp);
    event ContractRegistered(address indexed contractAddress, uint timestamp);
    event ContractUnregistered(address indexed contractAddress, uint timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        emergencyPaused = false;
    }

    /**
     * @dev 긴급 정지
     */
    function emergencyPause() external onlyOwner {
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender, block.timestamp);
    }

    /**
     * @dev 긴급 정지 해제
     */
    function emergencyResume() external onlyOwner {
        emergencyPaused = false;
        emit EmergencyResumed(msg.sender, block.timestamp);
    }

    /**
     * @dev 컨트랙트 등록
     */
    function registerContract(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "Invalid contract address");
        require(
            !registeredContracts[contractAddress],
            "Contract already registered"
        );

        registeredContracts[contractAddress] = true;
        allContracts.push(contractAddress);

        emit ContractRegistered(contractAddress, block.timestamp);
    }

    /**
     * @dev 컨트랙트 등록 해제
     */
    function unregisterContract(address contractAddress) external onlyOwner {
        require(
            registeredContracts[contractAddress],
            "Contract not registered"
        );

        registeredContracts[contractAddress] = false;

        emit ContractUnregistered(contractAddress, block.timestamp);
    }

    /**
     * @dev 긴급 정지 상태 확인
     */
    function isEmergencyPaused() public view returns (bool) {
        return emergencyPaused;
    }

    /**
     * @dev 등록된 모든 컨트랙트 조회
     */
    function getAllContracts() external view returns (address[] memory) {
        return allContracts;
    }

    /**
     * @dev 긴급 정지 수정자
     */
    modifier whenNotEmergencyPaused() {
        require(!emergencyPaused, "System is in emergency pause");
        _;
    }
}
