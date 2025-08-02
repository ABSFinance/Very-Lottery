// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title GasOptimizer
 * @dev 가스 최적화를 위한 유틸리티 라이브러리
 */
library GasOptimizer {
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
     * @dev 배열에서 특정 요소 제거 (가스 최적화)
     */
    function removeElement(
        address[] storage array,
        address element
    ) internal returns (bool) {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == element) {
                array[i] = array[length - 1];
                array.pop();
                return true;
            }
        }
        return false;
    }

    /**
     * @dev 배열에서 특정 인덱스 제거 (가스 최적화)
     */
    function removeAtIndex(address[] storage array, uint256 index) internal {
        require(index < array.length, "Index out of bounds");
        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @dev 배열 정렬 (가스 최적화)
     */
    function sortAddresses(
        address[] memory array
    ) internal pure returns (address[] memory) {
        address[] memory sorted = _copyArray(array);
        _sortArray(sorted);
        return sorted;
    }

    /**
     * @dev 배열 복사
     */
    function _copyArray(
        address[] memory array
    ) internal pure returns (address[] memory) {
        address[] memory sorted = new address[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            sorted[i] = array[i];
        }
        return sorted;
    }

    /**
     * @dev 배열 정렬
     */
    function _sortArray(address[] memory sorted) internal pure {
        for (uint256 i = 0; i < sorted.length; i++) {
            for (uint256 j = i + 1; j < sorted.length; j++) {
                if (sorted[i] > sorted[j]) {
                    _swapElements(sorted, i, j);
                }
            }
        }
    }

    /**
     * @dev 요소 교환
     */
    function _swapElements(
        address[] memory sorted,
        uint256 i,
        uint256 j
    ) internal pure {
        address temp = sorted[i];
        sorted[i] = sorted[j];
        sorted[j] = temp;
    }

    /**
     * @dev 배열에서 특정 요소 검색 (가스 최적화)
     */
    function findElement(
        address[] memory array,
        address element
    ) internal pure returns (bool, uint256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @dev 배열 슬라이스 (가스 최적화)
     */
    function sliceArray(
        address[] memory array,
        uint256 start,
        uint256 end
    ) internal pure returns (address[] memory) {
        require(
            start <= end && end <= array.length,
            "Invalid slice parameters"
        );

        address[] memory result = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = array[i];
        }

        return result;
    }

    /**
     * @dev 배열 병합 (가스 최적화)
     */
    function mergeArrays(
        address[] memory array1,
        address[] memory array2
    ) internal pure returns (address[] memory) {
        address[] memory result = new address[](array1.length + array2.length);

        for (uint256 i = 0; i < array1.length; i++) {
            result[i] = array1[i];
        }

        for (uint256 i = 0; i < array2.length; i++) {
            result[array1.length + i] = array2[i];
        }

        return result;
    }

    /**
     * @dev 배열 교집합 (가스 최적화)
     */
    function intersection(
        address[] memory array1,
        address[] memory array2
    ) internal pure returns (address[] memory) {
        address[] memory temp = new address[](array1.length);
        uint256 count = 0;

        for (uint256 i = 0; i < array1.length; i++) {
            for (uint256 j = 0; j < array2.length; j++) {
                if (array1[i] == array2[j]) {
                    temp[count] = array1[i];
                    count++;
                    break;
                }
            }
        }

        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = temp[i];
        }

        return result;
    }

    /**
     * @dev 배열 합집합 (가스 최적화)
     */
    function union(
        address[] memory array1,
        address[] memory array2
    ) internal pure returns (address[] memory) {
        address[] memory temp = new address[](array1.length + array2.length);
        uint256 count = 0;

        // Add all elements from array1
        for (uint256 i = 0; i < array1.length; i++) {
            temp[count] = array1[i];
            count++;
        }

        // Add unique elements from array2
        for (uint256 i = 0; i < array2.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < array1.length; j++) {
                if (array2[i] == array1[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                temp[count] = array2[i];
                count++;
            }
        }

        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = temp[i];
        }

        return result;
    }

    /**
     * @dev 배열 차집합 (가스 최적화)
     */
    function difference(
        address[] memory array1,
        address[] memory array2
    ) internal pure returns (address[] memory) {
        address[] memory temp = new address[](array1.length);
        uint256 count = 0;

        for (uint256 i = 0; i < array1.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < array2.length; j++) {
                if (array1[i] == array2[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                temp[count] = array1[i];
                count++;
            }
        }

        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = temp[i];
        }

        return result;
    }

    /**
     * @dev 배열 섞기 (가스 최적화)
     */
    function shuffleArray(
        address[] memory array,
        uint256 seed
    ) internal pure returns (address[] memory) {
        address[] memory result = new address[](array.length);

        // Copy array
        for (uint256 i = 0; i < array.length; i++) {
            result[i] = array[i];
        }

        // Fisher-Yates shuffle
        for (uint256 i = result.length - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(seed, i))) % (i + 1);
            address temp = result[i];
            result[i] = result[j];
            result[j] = temp;
        }

        return result;
    }

    /**
     * @dev 배열 회전 (가스 최적화)
     */
    function rotateArray(
        address[] memory array,
        uint256 positions
    ) internal pure returns (address[] memory) {
        if (array.length == 0) return array;

        uint256 actualPositions = positions % array.length;
        if (actualPositions == 0) return array;

        address[] memory result = new address[](array.length);

        for (uint256 i = 0; i < array.length; i++) {
            uint256 newIndex = (i + actualPositions) % array.length;
            result[newIndex] = array[i];
        }

        return result;
    }

    /**
     * @dev 배열 역순 (가스 최적화)
     */
    function reverseArray(
        address[] memory array
    ) internal pure returns (address[] memory) {
        address[] memory result = new address[](array.length);

        for (uint256 i = 0; i < array.length; i++) {
            result[i] = array[array.length - 1 - i];
        }

        return result;
    }

    /**
     * @dev 배열 중복 제거 (메모리 배열용)
     */
    function removeDuplicatesFromMemory(
        address[] memory array
    ) internal pure returns (address[] memory) {
        if (array.length <= 1) return array;

        address[] memory temp = new address[](array.length);
        uint256 count = 0;

        for (uint256 i = 0; i < array.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < count; j++) {
                if (array[i] == temp[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                temp[count] = array[i];
                count++;
            }
        }

        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = temp[i];
        }

        return result;
    }
}
