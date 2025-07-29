// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title GasOptimizer
 * @dev 가스 최적화를 위한 유틸리티 함수들
 */
library GasOptimizer {
    // 가스 최적화된 배열 조작
    function removeElement(address[] storage array, address element) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }

    function removeElement(uint256[] storage array, uint256 element) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }

    // 가스 최적화된 매핑 조작
    function safeTransfer(
        address payable recipient,
        uint256 amount
    ) internal returns (bool) {
        (bool success, ) = recipient.call{value: amount}("");
        return success;
    }

    // 가스 최적화된 검증
    function validateAddress(address addr) internal pure returns (bool) {
        return addr != address(0);
    }

    function validateAmount(uint256 amount) internal pure returns (bool) {
        return amount > 0;
    }

    // 가스 최적화된 계산
    function calculatePercentage(
        uint256 amount,
        uint256 percentage
    ) internal pure returns (uint256) {
        return (amount * percentage) / 100;
    }

    function calculateFee(
        uint256 amount,
        uint256 feeRate
    ) internal pure returns (uint256) {
        return (amount * feeRate) / 10000; // feeRate in basis points
    }

    // 가스 최적화된 이벤트 배치 처리
    function batchEmitTransfer(
        address[] memory from,
        address[] memory to,
        uint256[] memory amounts
    ) internal {
        require(
            from.length == to.length && to.length == amounts.length,
            "Array length mismatch"
        );
        for (uint256 i = 0; i < from.length; i++) {
            // Transfer 이벤트는 여기서 직접 발생시키지 않고, 호출자가 처리하도록 함
        }
    }

    // 가스 최적화된 스토리지 접근
    function getStorageSlot(bytes32 slot) internal view returns (bytes32) {
        bytes32 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    function setStorageSlot(bytes32 slot, bytes32 value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    // 가스 최적화된 메모리 복사
    function copyArray(
        address[] memory source
    ) internal pure returns (address[] memory) {
        address[] memory result = new address[](source.length);
        for (uint256 i = 0; i < source.length; i++) {
            result[i] = source[i];
        }
        return result;
    }

    function copyArray(
        uint256[] memory source
    ) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](source.length);
        for (uint256 i = 0; i < source.length; i++) {
            result[i] = source[i];
        }
        return result;
    }

    // 가스 최적화된 검색
    function findAddress(
        address[] memory array,
        address target
    ) internal pure returns (bool, uint256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == target) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function findUint256(
        uint256[] memory array,
        uint256 target
    ) internal pure returns (bool, uint256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == target) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    // 가스 최적화된 정렬 (간단한 버블 정렬)
    function sortAddresses(
        address[] memory array
    ) internal pure returns (address[] memory) {
        address[] memory sorted = copyArray(array);
        for (uint256 i = 0; i < sorted.length - 1; i++) {
            for (uint256 j = 0; j < sorted.length - i - 1; j++) {
                if (sorted[j] > sorted[j + 1]) {
                    address temp = sorted[j];
                    sorted[j] = sorted[j + 1];
                    sorted[j + 1] = temp;
                }
            }
        }
        return sorted;
    }

    // 가스 최적화된 랜덤 시드 생성
    function generateRandomSeed(
        address sender,
        uint256 blockNumber,
        uint256 timestamp
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(sender, blockNumber, timestamp))
            );
    }

    // 가스 최적화된 해시 계산
    function calculateHash(bytes memory data) internal pure returns (bytes32) {
        return keccak256(data);
    }

    function calculateHash(
        address addr,
        uint256 value
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr, value));
    }
}
