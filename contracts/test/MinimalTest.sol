// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MinimalTest {
    uint256 public value;

    constructor() {
        value = 42;
    }

    function setValue(uint256 _value) external {
        value = _value;
    }
}
