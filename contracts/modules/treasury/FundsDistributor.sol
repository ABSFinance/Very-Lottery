// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Cryptolotto Funds Distributor
 * @dev Receives and distributes commission funds to founders/team
 */
contract FundsDistributor {
    address public owner;
    bool private _locked;

    /**
     * @dev Commission received event
     */
    event CommissionReceived(uint256 amount, uint256 time);

    /**
     * @dev Funds withdrawn event
     */
    event FundsWithdrawn(address to, uint256 amount, uint256 timestamp);

    /**
     * @dev Owner changed event
     */
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /**
     * @dev Emergency pause functionality
     */
    bool public paused;

    /**
     * @dev Pause event
     */
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    /**
     * @dev Reentrancy guard modifier
     */
    modifier nonReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    /**
     * @dev Constructor
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Modifier for owner only functions
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev Pause modifier
     */
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /**
     * @dev Receive commission funds
     */
    fallback() external payable {
        if (msg.value > 0) {
            emit CommissionReceived(msg.value, block.timestamp);
        }
    }

    /**
     * @dev Receive commission funds
     */
    receive() external payable {
        if (msg.value > 0) {
            emit CommissionReceived(msg.value, block.timestamp);
        }
    }

    /**
     * @dev Withdraw funds to owner
     */
    function withdrawFunds() public onlyOwner nonReentrant whenNotPaused {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");

        (bool success,) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsWithdrawn(owner, amount, block.timestamp);
    }

    /**
     * @dev Withdraw specific amount
     */
    function withdrawAmount(uint256 amount) public onlyOwner nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success,) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsWithdrawn(owner, amount, block.timestamp);
    }

    /**
     * @dev Change owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner must be different");

        address oldOwner = owner;
        owner = newOwner;

        emit OwnerChanged(oldOwner, newOwner);
    }

    /**
     * @dev Get contract balance
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
}
