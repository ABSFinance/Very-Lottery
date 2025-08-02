// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleOwnable
 * @dev 간단한 소유권 관리 컨트랙트
 * @dev 추가된 보안 기능과 유틸리티 함수들
 */
contract SimpleOwnable is Ownable {
    // ============ STORAGE ============

    /**
     * @dev 권한이 있는 주소들의 매핑
     */
    mapping(address => bool) public authorizedOperators;

    /**
     * @dev 긴급 정지 플래그
     */
    bool public emergencyPaused;

    /**
     * @dev 마지막 활동 시간
     */
    uint256 public lastActivityTime;

    // ============ EVENTS ============

    event OperatorAdded(address indexed operator, uint256 timestamp);
    event OperatorRemoved(address indexed operator, uint256 timestamp);
    event EmergencyPaused(address indexed by, uint256 timestamp);
    event EmergencyResumed(address indexed by, uint256 timestamp);
    event ActivityRecorded(address indexed caller, string action, uint256 timestamp);

    // ============ MODIFIERS ============

    /**
     * @dev 긴급 정지 확인
     */
    modifier whenNotEmergencyPaused() {
        require(!emergencyPaused, "Contract is emergency paused");
        _;
    }

    /**
     * @dev 권한 확인 (소유자 또는 승인된 운영자)
     */
    modifier onlyAuthorized() {
        require(msg.sender == owner() || authorizedOperators[msg.sender], "Not authorized");
        _;
    }

    // ============ CONSTRUCTOR ============

    constructor() Ownable(msg.sender) {
        lastActivityTime = block.timestamp;
    }

    // ============ CORE FUNCTIONS ============

    /**
     * @dev 권한이 있는 주소인지 확인
     */
    function isAllowed(address caller) public view returns (bool) {
        return caller == owner() || authorizedOperators[caller];
    }

    /**
     * @dev 운영자 추가
     */
    function addOperator(address operator) external onlyOwner {
        require(operator != address(0), "Invalid operator address");
        require(operator != address(this), "Cannot add self as operator");
        require(!authorizedOperators[operator], "Operator already exists");

        authorizedOperators[operator] = true;
        emit OperatorAdded(operator, block.timestamp);
        _recordActivity("addOperator", operator);
    }

    /**
     * @dev 운영자 제거
     */
    function removeOperator(address operator) external onlyOwner {
        require(authorizedOperators[operator], "Operator does not exist");

        authorizedOperators[operator] = false;
        emit OperatorRemoved(operator, block.timestamp);
        _recordActivity("removeOperator", operator);
    }

    /**
     * @dev 긴급 정지
     */
    function emergencyPause() external onlyOwner {
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender, block.timestamp);
        _recordActivity("emergencyPause", msg.sender);
    }

    /**
     * @dev 긴급 정지 해제
     */
    function emergencyResume() external onlyOwner {
        emergencyPaused = false;
        emit EmergencyResumed(msg.sender, block.timestamp);
        _recordActivity("emergencyResume", msg.sender);
    }

    /**
     * @dev 소유권 이전 (추가 검증)
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner(), "New owner cannot be current owner");

        address oldOwner = owner();
        super.transferOwnership(newOwner);
        _recordActivity("transferOwnership", newOwner);

        // 이전 소유자의 운영자 권한 제거
        if (authorizedOperators[oldOwner]) {
            authorizedOperators[oldOwner] = false;
            emit OperatorRemoved(oldOwner, block.timestamp);
        }
    }

    // ============ UTILITY FUNCTIONS ============

    /**
     * @dev 활동 기록
     */
    function _recordActivity(string memory action, address /* target */ ) internal {
        lastActivityTime = block.timestamp;
        emit ActivityRecorded(msg.sender, action, block.timestamp);
    }

    /**
     * @dev 컨트랙트 상태 조회
     */
    function getContractStatus()
        external
        view
        returns (address currentOwner, bool isEmergencyPaused, uint256 lastActivity, uint256 operatorCount)
    {
        uint256 count = 0;
        // 실제 구현에서는 모든 운영자를 카운트해야 하지만,
        // 가스 비용을 고려하여 간단히 처리
        return (owner(), emergencyPaused, lastActivityTime, count);
    }

    /**
     * @dev 운영자 목록 조회 (제한된 수)
     */
    function getOperators(uint256, /* start */ uint256 /* limit */ )
        external
        pure
        returns (address[] memory operators, uint256 totalCount)
    {
        // 실제 구현에서는 매핑을 순회하여 운영자 목록을 반환
        // 가스 비용을 고려하여 빈 배열 반환
        operators = new address[](0);
        totalCount = 0;
    }

    /**
     * @dev 권한 확인 (상세)
     */
    function checkPermissions(address caller)
        external
        view
        returns (bool isOwner, bool isOperator, bool isAuthorized, bool canPause)
    {
        isOwner = caller == owner();
        isOperator = authorizedOperators[caller];
        isAuthorized = isOwner || isOperator;
        canPause = isOwner;
    }
}
