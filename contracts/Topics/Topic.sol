pragma solidity ^0.4.17;

import "./IPollFactory.sol";

contract Topic {

    byte public DRAFT = 0x00;
    byte public POLL  = 0x01;

    //CoBaLT relevant variables
    bytes32 public cobalt_identifier;
    bytes32 public cobalt_policy;

    //address of the PollFactory that created this topic
    IPollFactory public pollFactory;

    //is this topic a draft or a poll
    byte public topicType;

    uint public topicID;

    //is voting in this topic obligatory
    bool public voteRequired;

    struct Vote {
        uint id;
        uint amount;
    }

    //mapping and array of voters that participated
    mapping(address => Vote) voters;
    address[] voterArray;

    //current amount of tokens voted
    uint public currentVotes;

    //the minimum amount of tokens required for this topic to pass
    uint public voteMargin;

    //the time in epoch when the topic finishes voting phase
    uint public timeEnd;

    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Topic(uint _id, bytes32 _cobalt_identifier, byte _topicType, bool _voteRequired, uint _voteMargin, uint _duration) public {
        owner = msg.sender;
        pollFactory = IPollFactory(msg.sender);
        topicID = _id;
        cobalt_identifier = _cobalt_identifier;
        topicType = _topicType;
        voteRequired = _voteRequired;
        voteMargin = _voteMargin;
        timeEnd = block.timestamp + _duration;
    }

    function getIdentifier() public view returns (bytes32) {
        return cobalt_identifier;
    }
    
    function vote(address _voter, uint _amount) public onlyOwner returns (bool) {
        require(block.timestamp < timeEnd);
        require(_amount > 0);
        require(voters[_voter].amount == 0);

        uint id;
        if(voters[_voter].id == 0) {
            id = voterArray.length;
        } else {
            id = voters[_voter].id;
        }
        voters[_voter] = Vote(id, _amount);
        voterArray.push(_voter);
        currentVotes = add(currentVotes, _amount);
    }

    function removeVote(address _voter) public onlyOwner returns (bool) {
        require(block.timestamp < timeEnd);
        require(voters[_voter].amount > 0);

        currentVotes = sub(currentVotes, voters[_voter].amount);
        delete voterArray[voters[_voter].id];
        delete voters[_voter].amount;
    }

    function processVotes() public onlyOwner returns (bool, uint) {
        require(block.timestamp > timeEnd + 3600);
        
        if(currentVotes < voteMargin) {
            return (false, 0);
        } else {
            return pollFactory.processTopicCallback(topicType, topicID);
        }
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}