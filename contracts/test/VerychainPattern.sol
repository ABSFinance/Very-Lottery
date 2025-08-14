// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VerychainPattern {
    // State variables
    address public owner;
    uint256 public value;

    // Events
    event ValueSet(address indexed setter, uint256 newValue, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        value = 42;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // Functions
    function setValue(uint256 _value) public onlyOwner {
        require(_value > 0, "Value must be greater than 0");
        value = _value;
        emit ValueSet(msg.sender, _value, block.timestamp);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function getValue() public view returns (uint256) {
        return value;
    }
}
