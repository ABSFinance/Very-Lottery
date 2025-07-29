// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title TokenRegistry
 * @dev 토큰 관리를 위한 중앙화된 레지스트리
 */
contract TokenRegistry is Initializable, OwnableUpgradeable {
    // Token info struct
    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        bool isActive;
        uint256 createdAt;
    }

    // Registry mappings
    mapping(address => TokenInfo) public tokens;
    mapping(string => address) public tokenByName;
    address[] public allTokens;

    // Events
    event TokenRegistered(
        address indexed tokenAddress,
        string name,
        string symbol,
        uint256 timestamp
    );
    event TokenDeactivated(address indexed tokenAddress, uint256 timestamp);
    event TokenReactivated(address indexed tokenAddress, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }

    /**
     * @dev 토큰 등록
     */
    function registerToken(
        address tokenAddress,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply
    ) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(bytes(name).length > 0, "Token name cannot be empty");
        require(bytes(symbol).length > 0, "Token symbol cannot be empty");
        require(!tokens[tokenAddress].isActive, "Token already registered");

        tokens[tokenAddress] = TokenInfo({
            tokenAddress: tokenAddress,
            name: name,
            symbol: symbol,
            decimals: decimals,
            totalSupply: totalSupply,
            isActive: true,
            createdAt: block.timestamp
        });

        tokenByName[name] = tokenAddress;
        allTokens.push(tokenAddress);

        emit TokenRegistered(tokenAddress, name, symbol, block.timestamp);
    }

    /**
     * @dev 토큰 비활성화
     */
    function deactivateToken(address tokenAddress) external onlyOwner {
        require(
            tokens[tokenAddress].isActive,
            "Token not registered or already inactive"
        );

        tokens[tokenAddress].isActive = false;
        emit TokenDeactivated(tokenAddress, block.timestamp);
    }

    /**
     * @dev 토큰 재활성화
     */
    function reactivateToken(address tokenAddress) external onlyOwner {
        require(
            tokens[tokenAddress].tokenAddress != address(0),
            "Token not registered"
        );
        require(!tokens[tokenAddress].isActive, "Token already active");

        tokens[tokenAddress].isActive = true;
        emit TokenReactivated(tokenAddress, block.timestamp);
    }

    /**
     * @dev 토큰 정보 조회
     */
    function getTokenInfo(
        address tokenAddress
    ) external view returns (TokenInfo memory) {
        return tokens[tokenAddress];
    }

    /**
     * @dev 이름으로 토큰 주소 조회
     */
    function getTokenByName(
        string memory name
    ) external view returns (address) {
        return tokenByName[name];
    }

    /**
     * @dev 활성 토큰 목록 조회
     */
    function getActiveTokens() external view returns (address[] memory) {
        address[] memory activeTokens = new address[](allTokens.length);
        uint256 activeCount = 0;

        for (uint256 i = 0; i < allTokens.length; i++) {
            if (tokens[allTokens[i]].isActive) {
                activeTokens[activeCount] = allTokens[i];
                activeCount++;
            }
        }

        // Resize array to actual active count
        assembly {
            mstore(activeTokens, activeCount)
        }

        return activeTokens;
    }

    /**
     * @dev 모든 토큰 목록 조회
     */
    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }

    /**
     * @dev 토큰 존재 여부 확인
     */
    function isTokenRegistered(
        address tokenAddress
    ) external view returns (bool) {
        return tokens[tokenAddress].tokenAddress != address(0);
    }

    /**
     * @dev 활성 토큰 개수 조회
     */
    function getActiveTokenCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (tokens[allTokens[i]].isActive) {
                count++;
            }
        }
        return count;
    }
}
