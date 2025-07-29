// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title GovernanceManager
 * @dev 거버넌스 시스템
 */
contract GovernanceManager is Initializable, OwnableUpgradeable {
    // Proposal struct
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

    // Governance settings
    uint256 public proposalCount;
    uint256 public votingPeriod = 7 days;
    uint256 public quorum = 1000; // Minimum votes required
    uint256 public proposalThreshold = 100; // Minimum tokens to propose

    // Mappings
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    mapping(address => bool) public isGovernor;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 timestamp
    );
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 timestamp
    );
    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed executor,
        uint256 timestamp
    );
    event ProposalCanceled(
        uint256 indexed proposalId,
        address indexed canceler,
        uint256 timestamp
    );
    event GovernorAdded(address indexed governor, uint256 timestamp);
    event GovernorRemoved(address indexed governor, uint256 timestamp);
    event VotingPowerUpdated(
        address indexed user,
        uint256 oldPower,
        uint256 newPower,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        isGovernor[owner] = true;
        votingPower[owner] = 1000; // Initial voting power
    }

    /**
     * @dev 제안 생성
     */
    function createProposal(
        string memory title,
        string memory description
    ) external returns (uint256) {
        require(isGovernor[msg.sender], "Not a governor");
        require(
            votingPower[msg.sender] >= proposalThreshold,
            "Insufficient voting power"
        );
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");

        proposalCount++;
        uint256 proposalId = proposalCount;

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.title = title;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.proposer = msg.sender;

        emit ProposalCreated(proposalId, msg.sender, title, block.timestamp);

        return proposalId;
    }

    /**
     * @dev 투표
     */
    function vote(uint256 proposalId, bool support) external {
        require(isGovernor[msg.sender], "Not a governor");
        require(votingPower[msg.sender] > 0, "No voting power");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal canceled");

        proposal.hasVoted[msg.sender] = true;
        proposal.votedFor[msg.sender] = support;

        if (support) {
            proposal.forVotes += votingPower[msg.sender];
        } else {
            proposal.againstVotes += votingPower[msg.sender];
        }

        emit VoteCast(proposalId, msg.sender, support, block.timestamp);
    }

    /**
     * @dev 제안 실행
     */
    function executeProposal(uint256 proposalId) external {
        require(isGovernor[msg.sender], "Not a governor");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(
            proposal.forVotes + proposal.againstVotes >= quorum,
            "Quorum not reached"
        );
        require(
            proposal.forVotes > proposal.againstVotes,
            "Proposal not passed"
        );

        proposal.executed = true;

        emit ProposalExecuted(proposalId, msg.sender, block.timestamp);
    }

    /**
     * @dev 제안 취소
     */
    function cancelProposal(uint256 proposalId) external {
        require(isGovernor[msg.sender], "Not a governor");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.proposer == msg.sender, "Not the proposer");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal already canceled");
        require(block.timestamp < proposal.endTime, "Voting ended");

        proposal.canceled = true;

        emit ProposalCanceled(proposalId, msg.sender, block.timestamp);
    }

    /**
     * @dev 거버너 추가
     */
    function addGovernor(address governor) external onlyOwner {
        require(governor != address(0), "Invalid governor address");
        require(!isGovernor[governor], "Already a governor");

        isGovernor[governor] = true;
        votingPower[governor] = 100; // Default voting power

        emit GovernorAdded(governor, block.timestamp);
    }

    /**
     * @dev 거버너 제거
     */
    function removeGovernor(address governor) external onlyOwner {
        require(isGovernor[governor], "Not a governor");
        require(governor != owner(), "Cannot remove owner");

        isGovernor[governor] = false;
        uint256 oldPower = votingPower[governor];
        votingPower[governor] = 0;

        emit GovernorRemoved(governor, block.timestamp);
        emit VotingPowerUpdated(governor, oldPower, 0, block.timestamp);
    }

    /**
     * @dev 투표 권한 업데이트
     */
    function updateVotingPower(
        address user,
        uint256 newPower
    ) external onlyOwner {
        require(isGovernor[user], "User is not a governor");

        uint256 oldPower = votingPower[user];
        votingPower[user] = newPower;

        emit VotingPowerUpdated(user, oldPower, newPower, block.timestamp);
    }

    /**
     * @dev 거버넌스 설정 업데이트
     */
    function updateGovernanceSettings(
        uint256 newVotingPeriod,
        uint256 newQuorum,
        uint256 newProposalThreshold
    ) external onlyOwner {
        require(newVotingPeriod >= 1 days, "Voting period too short");
        require(newVotingPeriod <= 30 days, "Voting period too long");
        require(newQuorum > 0, "Quorum must be greater than 0");
        require(
            newProposalThreshold > 0,
            "Proposal threshold must be greater than 0"
        );

        votingPeriod = newVotingPeriod;
        quorum = newQuorum;
        proposalThreshold = newProposalThreshold;
    }

    /**
     * @dev 제안 정보 조회
     */
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
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            proposal.canceled,
            proposal.proposer
        );
    }

    /**
     * @dev 투표 상태 조회
     */
    function getVoteInfo(
        uint256 proposalId,
        address voter
    )
        external
        view
        returns (bool hasVoted, bool votedFor, uint256 userVotingPower)
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.hasVoted[voter],
            proposal.votedFor[voter],
            votingPower[voter]
        );
    }

    /**
     * @dev 거버넌스 수정자
     */
    modifier onlyGovernor() {
        require(isGovernor[msg.sender], "Not a governor");
        _;
    }
}
