// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITokenRegistry {
    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        bool isActive;
        uint256 createdAt;
    }

    function registerToken(
        address tokenAddress,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply
    ) external;

    function deactivateToken(address tokenAddress) external;

    function reactivateToken(address tokenAddress) external;

    function getTokenInfo(
        address tokenAddress
    ) external view returns (TokenInfo memory);

    function getTokenByName(string memory name) external view returns (address);

    function getActiveTokens() external view returns (address[] memory);

    function getAllTokens() external view returns (address[] memory);

    function isTokenRegistered(
        address tokenAddress
    ) external view returns (bool);

    function getActiveTokenCount() external view returns (uint256);
}
