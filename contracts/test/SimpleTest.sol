// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleTest {
    uint256 public value;
    string public name;

    constructor() {
        value = 42;
        name = "SimpleTest";
    }

    function setValue(uint256 _value) external {
        value = _value;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }
}
