// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICryptolottoReferral {
    // Events
    event NewPartner(address indexed _address, uint256 _percent, uint256 _time);
    event NewSalesPartner(
        address indexed _partnerAddress, address indexed _salesPartnerAddress, uint256 _percent, uint256 _time
    );
    event NewReferral(address indexed _partner, address indexed _referral, uint256 _time);
    event NewGame(address _game, uint256 _time);
    event PartnerRemoved(address indexed _address, uint256 _time);
    event GameRemoved(address _game, uint256 _time);

    // Partner management
    function addPartner(address _address, uint256 _percent) external;

    function removePartner(address _address) external;

    function getPartnerByReferral(address _referral) external view returns (address);

    function getPartnerPercent(address _partner) external view returns (uint256);

    function isPartner(address _address) external view returns (bool);

    // Sales partner management
    function addSalesPartner(address _partnerAddress, address _salesPartnerAddress, uint256 _percent) external;

    function getSalesPartnerByPartner(address _partner) external view returns (address);

    function getSalesPartnerPercent(address _salesPartner) external view returns (uint256);

    function isSalesPartner(address _address) external view returns (bool);

    // Referral management
    function addReferral(address _partner, address _referral) external;

    function getReferralsByPartner(address _partner) external view returns (address[] memory);

    function isReferral(address _address) external view returns (bool);

    // Game management
    function addGame(address _game) external;

    function removeGame(address _game) external;

    function isGame(address _game) external view returns (bool);

    function getGames() external view returns (address[] memory);

    // Commission calculation
    function calculateCommission(address _player, uint256 _amount) external view returns (uint256);

    function distributeCommission(address _player, uint256 _amount) external;

    // Access control
    function owner() external view returns (address);
}
