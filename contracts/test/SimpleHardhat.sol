pragma solidity ^0.8.19;

contract SimpleHardhat {
    string public message;
    uint256 public value;
    address public owner;

    event MessageUpdated(string newMessage);
    event ValueUpdated(uint256 newValue);

    constructor() {
        owner = msg.sender;
        message = "Hello from Hardhat!";
        value = 42;
    }

    function setMessage(string memory _message) public {
        require(msg.sender == owner, "Only owner can set message");
        message = _message;
        emit MessageUpdated(_message);
    }

    function setValue(uint256 _value) public {
        require(msg.sender == owner, "Only owner can set value");
        value = _value;
        emit ValueUpdated(_value);
    }

    function getInfo() public view returns (string memory, uint256, address) {
        return (message, value, owner);
    }
}
