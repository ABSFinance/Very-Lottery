// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title GasOptimizer
 * @author Cryptolotto Team
 * @notice Gas optimization utility library
 * @dev Provides gas-optimized array operations and utilities
 */
library GasOptimizer {
    // Custom Errors
    error IndexOutOfBounds();
    error InvalidSliceRange();

    /**
     * @notice Remove duplicates from an array (gas optimized)
     * @param array The array to remove duplicates from
     */
    function removeDuplicates(address[] storage array) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; ++i) {
            for (uint256 j = i + 1; j < length; ++j) {
                if (array[i] == array[j]) {
                    array[j] = array[length - 1];
                    array.pop();
                    --length;
                    --j;
                }
            }
        }
    }

    /**
     * @notice Remove a specific element from an array (gas optimized)
     * @param array The array to remove the element from
     * @param element The element to remove
     * @return True if the element was found and removed, false otherwise
     */
    function removeElement(address[] storage array, address element) internal returns (bool) {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (array[i] == element) {
                array[i] = array[length - 1];
                array.pop();
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Remove element at specific index (gas optimized)
     * @param array The array to remove the element from
     * @param index The index of the element to remove
     */
    function removeAtIndex(address[] storage array, uint256 index) internal {
        if (index >= array.length) {
            revert IndexOutOfBounds();
        }
        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @notice Sort addresses in an array (gas optimized)
     * @param array The array to sort
     * @return The sorted array
     */
    function sortAddresses(address[] memory array) internal pure returns (address[] memory) {
        address[] memory sorted = _copyArray(array);
        _sortArray(sorted);
        return sorted;
    }

    /**
     * @notice Copy an array
     * @param array The array to copy
     * @return A new array with the same elements
     */
    function _copyArray(address[] memory array) internal pure returns (address[] memory) {
        address[] memory sorted = new address[](array.length);
        for (uint256 i = 0; i < array.length; ++i) {
            sorted[i] = array[i];
        }
        return sorted;
    }

    /**
     * @notice Sort an array using bubble sort
     * @param sorted The array to sort
     */
    function _sortArray(address[] memory sorted) internal pure {
        for (uint256 i = 0; i < sorted.length; ++i) {
            for (uint256 j = i + 1; j < sorted.length; ++j) {
                if (sorted[i] > sorted[j]) {
                    _swapElements(sorted, i, j);
                }
            }
        }
    }

    /**
     * @notice Swap elements in an array
     * @param sorted The array containing the elements
     * @param i The first index
     * @param j The second index
     */
    function _swapElements(address[] memory sorted, uint256 i, uint256 j) internal pure {
        address temp = sorted[i];
        sorted[i] = sorted[j];
        sorted[j] = temp;
    }

    /**
     * @notice Find an element in an array (gas optimized)
     * @param array The array to search in
     * @param element The element to find
     * @return found True if the element was found
     * @return index The index of the element if found
     */
    function findElement(address[] memory array, address element) internal pure returns (bool found, uint256 index) {
        for (uint256 i = 0; i < array.length; ++i) {
            if (array[i] == element) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @notice Slice an array (gas optimized)
     * @param array The array to slice
     * @param start The starting index (inclusive)
     * @param end The ending index (exclusive)
     * @return A new array containing the sliced elements
     */
    function sliceArray(address[] memory array, uint256 start, uint256 end) internal pure returns (address[] memory) {
        if (start > end || end > array.length) {
            revert InvalidSliceRange();
        }

        address[] memory result = new address[](end - start);
        for (uint256 i = start; i < end; ++i) {
            result[i - start] = array[i];
        }

        return result;
    }

    /**
     * @notice Merge two arrays (gas optimized)
     * @param array1 The first array
     * @param array2 The second array
     * @return A new array containing all elements from both arrays
     */
    function mergeArrays(address[] memory array1, address[] memory array2) internal pure returns (address[] memory) {
        address[] memory result = new address[](array1.length + array2.length);

        for (uint256 i = 0; i < array1.length; ++i) {
            result[i] = array1[i];
        }

        for (uint256 i = 0; i < array2.length; ++i) {
            result[array1.length + i] = array2[i];
        }

        return result;
    }

    /**
     * @notice Find intersection of two arrays (gas optimized)
     * @param array1 The first array
     * @param array2 The second array
     * @return A new array containing common elements
     */
    function intersection(address[] memory array1, address[] memory array2) internal pure returns (address[] memory) {
        address[] memory temp = new address[](array1.length);
        uint256 count = 0;

        for (uint256 i = 0; i < array1.length; ++i) {
            for (uint256 j = 0; j < array2.length; ++j) {
                if (array1[i] == array2[j]) {
                    temp[count] = array1[i];
                    count++;
                    break;
                }
            }
        }

        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; ++i) {
            result[i] = temp[i];
        }

        return result;
    }

    /**
     * @notice Find union of two arrays (gas optimized)
     * @param array1 The first array
     * @param array2 The second array
     * @return A new array containing all unique elements from both arrays
     */
    function union(address[] memory array1, address[] memory array2) internal pure returns (address[] memory) {
        address[] memory temp = new address[](array1.length + array2.length);
        uint256 count = 0;

        // Add all elements from array1
        for (uint256 i = 0; i < array1.length; ++i) {
            temp[count] = array1[i];
            count++;
        }

        // Add unique elements from array2
        for (uint256 i = 0; i < array2.length; ++i) {
            bool found = false;
            for (uint256 j = 0; j < array1.length; ++j) {
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
        for (uint256 i = 0; i < count; ++i) {
            result[i] = temp[i];
        }

        return result;
    }

    /**
     * @notice Find difference between two arrays (gas optimized)
     * @param array1 The first array
     * @param array2 The second array
     * @return A new array containing elements from array1 that are not in array2
     */
    function difference(address[] memory array1, address[] memory array2) internal pure returns (address[] memory) {
        address[] memory temp = new address[](array1.length);
        uint256 count = 0;

        for (uint256 i = 0; i < array1.length; ++i) {
            bool found = false;
            for (uint256 j = 0; j < array2.length; ++j) {
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
        for (uint256 i = 0; i < count; ++i) {
            result[i] = temp[i];
        }

        return result;
    }

    /**
     * @notice Shuffle an array (gas optimized)
     * @param array The array to shuffle
     * @param seed A seed for the random shuffle
     * @return A new array with elements in a random order
     */
    function shuffleArray(address[] memory array, uint256 seed) internal pure returns (address[] memory) {
        address[] memory result = new address[](array.length);

        // Copy array
        for (uint256 i = 0; i < array.length; ++i) {
            result[i] = array[i];
        }

        // Fisher-Yates shuffle
        for (uint256 i = result.length - 1; i > 0; --i) {
            uint256 j = uint256(keccak256(abi.encodePacked(seed, i))) % (i + 1);
            address temp = result[i];
            result[i] = result[j];
            result[j] = temp;
        }

        return result;
    }

    /**
     * @notice Rotate an array (gas optimized)
     * @param array The array to rotate
     * @param positions The number of positions to rotate
     * @return A new array with elements rotated by the specified positions
     */
    function rotateArray(address[] memory array, uint256 positions) internal pure returns (address[] memory) {
        if (array.length == 0) return array;

        uint256 actualPositions = positions % array.length;
        if (actualPositions == 0) return array;

        address[] memory result = new address[](array.length);

        for (uint256 i = 0; i < array.length; ++i) {
            uint256 newIndex = (i + actualPositions) % array.length;
            result[newIndex] = array[i];
        }

        return result;
    }

    /**
     * @notice Reverse an array (gas optimized)
     * @param array The array to reverse
     * @return A new array with elements in reverse order
     */
    function reverseArray(address[] memory array) internal pure returns (address[] memory) {
        address[] memory result = new address[](array.length);

        for (uint256 i = 0; i < array.length; ++i) {
            result[i] = array[array.length - 1 - i];
        }

        return result;
    }

    /**
     * @notice Remove duplicates from an array (memory array)
     * @param array The array to remove duplicates from
     * @return A new array with unique elements
     */
    function removeDuplicatesFromMemory(address[] memory array) internal pure returns (address[] memory) {
        if (array.length <= 1) return array;

        address[] memory temp = new address[](array.length);
        uint256 count = 0;

        for (uint256 i = 0; i < array.length; ++i) {
            bool found = false;
            for (uint256 j = 0; j < count; ++j) {
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
        for (uint256 i = 0; i < count; ++i) {
            result[i] = temp[i];
        }

        return result;
    }
}
