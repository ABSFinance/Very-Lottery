// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleOwnable is Ownable {
    constructor() Ownable(msg.sender) {}

    function isAllowed(address caller) public view returns (bool) {
        return caller == owner();
    }
}
