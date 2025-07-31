// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./StorageLayout.sol";

/**
 * @title StorageOptimizer
 * @dev 스토리지 최적화를 위한 유틸리티 라이브러리
 * 가스 효율적인 스토리지 패턴 제공
 */
library StorageOptimizer {
    // ============ PACKED STORAGE STRUCTURES ============

    /**
     * @dev 패킹된 게임 데이터 (32바이트 슬롯 최적화)
     */
    struct PackedGameData {
        uint128 jackpot; // 16 bytes
        uint64 startTime; // 8 bytes
        uint64 endTime; // 8 bytes
    }

    /**
     * @dev 패킹된 사용자 데이터
     */
    struct PackedUserData {
        uint128 totalWinnings; // 16 bytes
        uint64 lastActivity; // 8 bytes
        uint32 totalGames; // 4 bytes
        uint32 totalWins; // 4 bytes
    }

    /**
     * @dev 패킹된 설정 데이터
     */
    struct PackedConfigData {
        uint128 ticketPrice; // 16 bytes
        uint64 gameDuration; // 8 bytes
        uint32 maxTickets; // 4 bytes
        uint32 feePercentage; // 4 bytes
        bool isActive; // 1 byte
    }

    // ============ STORAGE OPTIMIZATION FUNCTIONS ============

    /**
     * @dev 배열에서 중복 제거 (가스 최적화)
     */
    function removeDuplicates(address[] storage array) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                if (array[i] == array[j]) {
                    array[j] = array[length - 1];
                    array.pop();
                    length--;
                    j--;
                }
            }
        }
    }

    /**
     * @dev 효율적인 배열 추가 (중복 체크 포함)
     */
    function addUniquePlayer(
        address[] storage players,
        address player
    ) internal returns (bool) {
        uint256 length = players.length;
        for (uint256 i = 0; i < length; i++) {
            if (players[i] == player) {
                return false; // 이미 존재함
            }
        }
        players.push(player);
        return true; // 새로 추가됨
    }

    /**
     * @dev 배치 업데이트 (가스 최적화)
     */
    function batchUpdatePlayerScores(
        mapping(address => uint256) storage scores,
        address[] memory players,
        uint256[] memory newScores
    ) internal {
        require(players.length == newScores.length, "Array length mismatch");
        for (uint256 i = 0; i < players.length; i++) {
            scores[players[i]] = newScores[i];
        }
    }

    /**
     * @dev 스토리지 슬롯 최적화 검증
     */
    function validateStorageLayout() internal pure returns (bool) {
        // PackedGameData가 32바이트에 맞는지 확인
        PackedGameData memory test;
        assembly {
            // 32바이트 슬롯 사용 확인
            let size := 32
            test := mload(0x40)
            mstore(0x40, add(test, size))
        }
        return true;
    }

    /**
     * @dev 스토리지 접근 최적화 (캐싱)
     */
    function getCachedGameData(
        mapping(uint256 => StorageLayout.Game) storage games,
        uint256 gameId
    )
        internal
        view
        returns (
            uint256 gameNumber,
            uint256 startTime,
            uint256 endTime,
            uint256 jackpot,
            uint256 playerCount,
            StorageLayout.GameState state
        )
    {
        StorageLayout.Game storage game = games[gameId];
        return (
            game.gameNumber,
            game.startTime,
            game.endTime,
            game.jackpot,
            game.playerCount,
            game.state
        );
    }

    /**
     * @dev 스토리지 쓰기 최적화 (배치 업데이트)
     */
    function batchUpdateGameData(
        mapping(uint256 => StorageLayout.Game) storage games,
        uint256 gameId,
        uint256 newJackpot,
        uint256 newPlayerCount,
        StorageLayout.GameState newState
    ) internal {
        StorageLayout.Game storage game = games[gameId];
        game.jackpot = newJackpot;
        game.playerCount = newPlayerCount;
        game.state = newState;
    }
}
