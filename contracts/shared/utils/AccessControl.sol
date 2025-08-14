// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title AccessControl
 * @dev 고급 접근 제어 시스템
 */
contract AdvancedAccessControl is AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // 역할별 권한 매핑
    mapping(bytes32 => mapping(address => bool)) public roleMembers;
    mapping(address => bytes32[]) public userRoles;

    // 이벤트
    event EmergencyPaused(address indexed by, uint256 timestamp);
    event EmergencyResumed(address indexed by, uint256 timestamp);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    // 역할 관리 함수들
    function grantRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.grantRole(role, account);
        roleMembers[role][account] = true;
        userRoles[account].push(role);
        emit RoleGranted(role, account, msg.sender);
    }

    function revokeRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.revokeRole(role, account);
        roleMembers[role][account] = false;
        _removeUserRole(account, role);
        emit RoleRevoked(role, account, msg.sender);
    }

    function _removeUserRole(address user, bytes32 role) internal {
        bytes32[] storage roles = userRoles[user];
        for (uint256 i = 0; i < roles.length; i++) {
            if (roles[i] == role) {
                roles[i] = roles[roles.length - 1];
                roles.pop();
                break;
            }
        }
    }

    // 긴급 정지 함수들
    function emergencyPause() external onlyRole(EMERGENCY_ROLE) {
        _pause();
        emit EmergencyPaused(msg.sender, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    function emergencyResume() external onlyRole(EMERGENCY_ROLE) {
        _unpause();
        emit EmergencyResumed(msg.sender, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    // 역할 확인 함수들
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return roleMembers[role][account];
    }

    function getUserRoles(address user) external view returns (bytes32[] memory) {
        return userRoles[user];
    }

    // 수정자들
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "AccessControl: admin role required");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "AccessControl: operator role required");
        _;
    }

    modifier onlyEmergency() {
        require(hasRole(EMERGENCY_ROLE, msg.sender), "AccessControl: emergency role required");
        _;
    }

    modifier onlyUpgrader() {
        require(hasRole(UPGRADER_ROLE, msg.sender), "AccessControl: upgrader role required");
        _;
    }
}
