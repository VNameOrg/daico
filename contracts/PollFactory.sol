pragma solidity ^0.4.17;

import "./Util/OwnerUtil.sol";
import "./VNameDaico.sol";
import "./Topics/Topic.sol";

contract PollFactory is OwnerUtil {

    Topic[] drafts;
    Topic[] polls;

    mapping(address => bool) isChildTopic;

    address daico;

    modifier onlyDaico {
        require(msg.sender == daico);
        _;
    }

    modifier onlyTopic {
        require(isChildTopic[msg.sender]);
        _;
    }

    modifier onlyDaicoOrTopic {
        require(msg.sender == daico || isChildTopic[msg.sender]);
        _;
    }

    function pollFactory() public {
        owners[msg.sender] = Permissions(true, 10);
    }

    function addDaico(address _daico) public onlyOwner {
        daico = _daico;
    }
    
    function createDraft(bytes32 _cobalt_identifier, uint _voteMargin, uint _duration) public onlyDaico returns (bool, uint) {
        uint id = drafts.length;
        Topic topic = new Topic(id, _cobalt_identifier, 0x00, false, _voteMargin, _duration);
        drafts.push(topic);
        isChildTopic[topic] = true;
    }

    function createPoll(bytes32 _cobalt_identifier, uint _voteMargin, uint _duration) public onlyDaicoOrTopic returns (bool, uint) {
        uint id = polls.length;
        Topic topic = new Topic(id, _cobalt_identifier, 0x01, true, _voteMargin, _duration);
        polls.push(topic);
        isChildTopic[topic] = true;
        return (true, id);
    }

    function voteDraft(address _voter, uint _id, uint _amount) public onlyDaico returns (bool) {
        return drafts[_id].vote(_voter, _amount);
    }

    function votePoll(address _voter, uint _id, uint _amount) public onlyDaico returns (bool) {
        return polls[_id].vote(_voter, _amount);
    }

    function processDraft(uint _id) public onlyDaico returns (bool, uint) {
        return drafts[_id].processVotes();
    }

    function processPoll(uint _id) public onlyDaico returns (bool, uint) {
        return polls[_id].processVotes();
    }

    function processTopicCallback(byte _typ, uint _id) public onlyTopic returns (bool, uint) {
        Topic topic;
        if(_typ == 0x00) {
            topic = drafts[_id];
            return createPoll(topic.getIdentifier(), 0, 0);
        } else {
            topic = polls[_id];
            VNameDaico vname = VNameDaico(daico);
            return vname.processPollCallback(topic.getIdentifier());
        }
    }
}