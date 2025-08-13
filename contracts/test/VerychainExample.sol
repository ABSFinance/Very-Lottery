// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ExampleContract {
    // State variables
    address public owner;
    uint256 public value;

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Functions
    function setValue(uint256 _value) public {
        require(msg.sender == owner, "Not authorized");
        value = _value;
    }
}
