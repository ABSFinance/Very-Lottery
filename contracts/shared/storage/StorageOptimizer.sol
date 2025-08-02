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
    function addUniquePlayer(address[] storage players, address player) internal returns (bool) {
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
     * @dev 가스 최적화된 플레이어 중복 체크 (mapping + array 조합)
     * @notice O(1) 시간 복잡도로 중복 체크를 수행합니다
     * @param players 플레이어 배열
     * @param playerMap 플레이어 존재 여부를 추적하는 mapping
     * @param player 새로 추가할 플레이어
     * @return isNewPlayer 새로운 플레이어인지 여부
     */
    function addUniquePlayerOptimized(
        address[] storage players,
        mapping(address => bool) storage playerMap,
        address player
    ) internal returns (bool isNewPlayer) {
        // O(1) 중복 체크
        if (playerMap[player]) {
            return false; // 이미 존재함
        }

        // 새로운 플레이어 추가
        players.push(player);
        playerMap[player] = true;
        return true; // 새로 추가됨
    }

    /**
     * @dev 배치 플레이어 추가 (가스 최적화)
     * @notice 여러 플레이어를 한 번에 추가하여 가스를 절약합니다
     * @param players 플레이어 배열
     * @param playerMap 플레이어 존재 여부를 추적하는 mapping
     * @param newPlayers 추가할 플레이어들
     * @return addedCount 실제로 추가된 플레이어 수
     */
    function addBatchPlayersOptimized(
        address[] storage players,
        mapping(address => bool) storage playerMap,
        address[] memory newPlayers
    ) internal returns (uint256 addedCount) {
        return _processBatchPlayers(players, playerMap, newPlayers);
    }

    /**
     * @dev 배치 플레이어 처리
     */
    function _processBatchPlayers(
        address[] storage players,
        mapping(address => bool) storage playerMap,
        address[] memory newPlayers
    ) internal returns (uint256 addedCount) {
        uint256 newPlayerCount = 0;

        for (uint256 i = 0; i < newPlayers.length; i++) {
            if (_addPlayerIfNew(players, playerMap, newPlayers[i])) {
                newPlayerCount++;
            }
        }

        return newPlayerCount;
    }

    /**
     * @dev 새로운 플레이어인 경우에만 추가
     */
    function _addPlayerIfNew(address[] storage players, mapping(address => bool) storage playerMap, address player)
        internal
        returns (bool)
    {
        if (!playerMap[player]) {
            players.push(player);
            playerMap[player] = true;
            return true;
        }
        return false;
    }

    /**
     * @dev 플레이어 제거 (mapping 업데이트 포함)
     * @notice 플레이어를 배열에서 제거하고 mapping도 업데이트합니다
     * @param players 플레이어 배열
     * @param playerMap 플레이어 존재 여부를 추적하는 mapping
     * @param player 제거할 플레이어
     * @return removed 플레이어가 제거되었는지 여부
     */
    function removePlayerOptimized(
        address[] storage players,
        mapping(address => bool) storage playerMap,
        address player
    ) internal returns (bool removed) {
        if (!playerMap[player]) {
            return false; // 플레이어가 존재하지 않음
        }

        return _findAndRemovePlayer(players, playerMap, player);
    }

    /**
     * @dev 플레이어 찾기 및 제거
     */
    function _findAndRemovePlayer(address[] storage players, mapping(address => bool) storage playerMap, address player)
        internal
        returns (bool)
    {
        uint256 length = players.length;
        for (uint256 i = 0; i < length; i++) {
            if (players[i] == player) {
                _removePlayerAtIndex(players, playerMap, player, i);
                return true;
            }
        }
        return false;
    }

    /**
     * @dev 특정 인덱스에서 플레이어 제거
     */
    function _removePlayerAtIndex(
        address[] storage players,
        mapping(address => bool) storage playerMap,
        address player,
        uint256 index
    ) internal {
        // 마지막 요소를 현재 위치로 이동
        players[index] = players[players.length - 1];
        players.pop();
        playerMap[player] = false;
    }

    /**
     * @dev 플레이어 존재 여부 확인 (O(1) 최적화)
     * @param playerMap 플레이어 존재 여부를 추적하는 mapping
     * @param player 확인할 플레이어
     * @return exists 플레이어 존재 여부
     */
    function isPlayerExists(mapping(address => bool) storage playerMap, address player)
        internal
        view
        returns (bool exists)
    {
        return playerMap[player];
    }

    /**
     * @dev 플레이어 수 계산 (mapping 기반)
     * @return count 고유한 플레이어 수
     */
    function getUniquePlayerCount(mapping(address => bool) storage /* playerMap */ )
        internal
        pure
        returns (uint256 count)
    {
        // mapping의 모든 키를 순회하는 것은 비효율적이므로
        // 별도의 카운터를 유지하는 것이 좋습니다
        // 이 함수는 현재 mapping만으로는 정확한 카운트를 제공할 수 없습니다
        // 실제 구현에서는 별도의 카운터 변수를 사용해야 합니다
        return 0; // 임시 반환값
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

    /*
    function validateStorageLayout() internal pure returns (bool) {
        // PackedGameData가 32바이트에 맞는지 확인
        // PackedGameData memory test;
        // assembly {
        //     // 32바이트 슬롯 사용 확인
        //     let size := 32
        //     test := mload(0x40)
        //     mstore(0x40, add(test, size))
        // }
        // return true;
        // (테스트/개발용 함수이므로 커버리지 환경에서는 주석 처리)
    }
    */

    /**
     * @dev 스토리지 접근 최적화 (캐싱)
     */
    function getCachedGameData(mapping(uint256 => StorageLayout.Game) storage games, uint256 gameId)
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
        return (game.gameNumber, game.startTime, game.endTime, game.jackpot, game.playerCount, game.state);
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
