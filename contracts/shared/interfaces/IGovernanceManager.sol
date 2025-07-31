// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IGovernanceManager {
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        address proposer;
        mapping(address => bool) hasVoted;
        mapping(address => bool) votedFor;
    }

    function createProposal(
        string memory title,
        string memory description
    ) external returns (uint256);

    function vote(uint256 proposalId, bool support) external;

    function executeProposal(uint256 proposalId) external;

    function cancelProposal(uint256 proposalId) external;

    function addGovernor(address governor) external;

    function removeGovernor(address governor) external;

    function updateVotingPower(address user, uint256 newPower) external;

    function updateGovernanceSettings(
        uint256 newVotingPeriod,
        uint256 newQuorum,
        uint256 newProposalThreshold
    ) external;

    function getProposalInfo(
        uint256 proposalId
    )
        external
        view
        returns (
            uint256 id,
            string memory title,
            string memory description,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 startTime,
            uint256 endTime,
            bool executed,
            bool canceled,
            address proposer
        );

    function getVoteInfo(
        uint256 proposalId,
        address voter
    ) external view returns (bool hasVoted, bool votedFor, uint256 votingPower);
}
