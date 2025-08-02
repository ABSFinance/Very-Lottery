// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./StorageLayout.sol";

/**
 * @title StorageAccess
 * @dev 중앙화된 스토리지 접근 인터페이스
 * 모든 컨트랙트가 동일한 스토리지에 접근할 수 있도록 함
 */
contract StorageAccess {
    // ============ STORAGE SLOTS ============
    // 각 스토리지 영역을 위한 고유 슬롯
    bytes32 constant GAME_STORAGE_SLOT = keccak256("game.storage");
    bytes32 constant TREASURY_STORAGE_SLOT = keccak256("treasury.storage");
    bytes32 constant ANALYTICS_STORAGE_SLOT = keccak256("analytics.storage");
    bytes32 constant REFERRAL_STORAGE_SLOT = keccak256("referral.storage");
    bytes32 constant SECURITY_STORAGE_SLOT = keccak256("security.storage");
    bytes32 constant CONFIG_STORAGE_SLOT = keccak256("config.storage");

    // ============ STORAGE ACCESS FUNCTIONS ============

    /**
     * @dev 게임 스토리지 접근
     */
    function getGameStorage() internal pure returns (StorageLayout.GameStorage storage s) {
        bytes32 slot = GAME_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev 재무 스토리지 접근
     */
    function getTreasuryStorage() internal pure returns (StorageLayout.TreasuryStorage storage s) {
        bytes32 slot = TREASURY_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev 분석 스토리지 접근
     */
    function getAnalyticsStorage() internal pure returns (StorageLayout.AnalyticsStorage storage s) {
        bytes32 slot = ANALYTICS_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev 추천 스토리지 접근
     */
    function getReferralStorage() internal pure returns (StorageLayout.ReferralStorage storage s) {
        bytes32 slot = REFERRAL_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev 보안 스토리지 접근
     */
    function getSecurityStorage() internal pure returns (StorageLayout.SecurityStorage storage s) {
        bytes32 slot = SECURITY_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev 설정 스토리지 접근
     */
    function getConfigStorage() internal pure returns (StorageLayout.ConfigStorage storage s) {
        bytes32 slot = CONFIG_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    // ============ STORAGE VALIDATION ============

    /**
     * @dev 스토리지 초기화 상태 확인
     */
    function isStorageInitialized() internal view returns (bool) {
        StorageLayout.GameStorage storage gameStorage = getGameStorage();
        return gameStorage.ticketPrice > 0;
    }

    /**
     * @dev 스토리지 버전 확인
     */
    function getStorageVersion() internal pure returns (uint256) {
        return 1; // 현재 스토리지 버전
    }
}
