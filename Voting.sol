// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    constructor() Ownable(msg.sender){  }

    uint winningProposalId;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAdress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    event Whitelisted(address _address);

    mapping(address => Voter[]) Voters;
    mapping(address=> bool) private _whitelist;

    Proposal[] public Proposals;

    WorkflowStatus public currentStatus = WorkflowStatus.ProposalsRegistrationStarted;

    function whitelist(address _address) public onlyOwner {
        require(!_whitelist[_address], "This address is already whitelisted !");
        _whitelist[_address] = true;
         emit Whitelisted(_address);
    }

    function isWhitelisted(address _address) public view onlyOwner returns (bool){
      return _whitelist[_address];
    }

    function openingRegistrationSession() public {
        require(!(currentStatus == WorkflowStatus.ProposalsRegistrationStarted), "Voting session is aldready open.");
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(currentStatus, WorkflowStatus.ProposalsRegistrationStarted);
    }
    function closingRegistrationSession() public {
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "Voting session is not open.");
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(currentStatus, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function openingVotingSession() public {
        require(!(currentStatus == WorkflowStatus.VotingSessionStarted), "Voting session is aldready open.");
        currentStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(currentStatus, WorkflowStatus.VotingSessionStarted);
    }
    function closingVotingSession() public {
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "Voting session is not open.");
        currentStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(currentStatus, WorkflowStatus.VotingSessionEnded);
    }

    function registerProposition(uint proposalId, string calldata _description, address _address, Voter calldata _voter) public {
        require(_voter.isRegistered, "You are not registered to the session.");
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "Register session is not open for the moment");
        require(_whitelist[_address], "You are not authorize to register a proposal");
        Proposals.push(Proposal({
            description: _description,
            voteCount: 0
        }));
        emit ProposalRegistered(proposalId);
    }

    function Vote(address _address,uint _proposalId, Voter memory _voter) public {
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "Voting session is not open for the moment, please try again later.");
        require(!_voter.hasVoted, "You already have vote.");
        require(_voter.isRegistered, "You are not registered to the session.");
        require(_whitelist[_address], "You are not authorize to vote");
        Proposals[_proposalId].voteCount++;
        _voter.hasVoted = true;
        _voter.votedProposalId = _proposalId;
        emit VoterRegistered(_address);
    }

    function TallyingVotes() public returns (uint totalVotes) {
        totalVotes = 0;
        for(uint i = 0; i < Proposals.length; i++ ) {
            totalVotes = totalVotes + Proposals[i].voteCount;
        }
        currentStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(currentStatus, WorkflowStatus.VotesTallied);
        return totalVotes;
    }

    function getWinner() public view returns (uint winner)
    {
        uint winnerVoteCount = 0;
        for (uint i = 0; i < Proposals.length; i++) {
            if (Proposals[i].voteCount > winnerVoteCount) {
                winnerVoteCount = Proposals[i].voteCount;
                winner = i;
            }
        }
        return winner;
    }
}