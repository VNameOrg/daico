pragma solidity ^0.4.17;

interface ICOALITE1Receiver {
    function tokenReceived(address _sender, uint _value, bytes _data) public returns (bool);
}