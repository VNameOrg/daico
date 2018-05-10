pragma solidity ^0.4.17;

interface IPollFactory {

    function processTopicCallback(byte _typ, uint _id) public returns (bool, uint);
}