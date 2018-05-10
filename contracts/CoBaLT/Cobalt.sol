pragma solidity ^0.4.17;

contract Cobalt {

    byte type_byte      = 0x01;
    byte type_bytes32   = 0x02;
    byte type_bool      = 0x03;
    byte type_uint      = 0x04;

    struct Variable {
        string name;
        byte varType;
        bytes32 value;
    }

    Variable[] cobalt_variables;

    function getVariable(bytes2 _n) public view returns (string name, byte varType, bytes32 value) {
        name = cobalt_variables[uint(_n)].name;
        varType = cobalt_variables[uint(_n)].varType;
        value = cobalt_variables[uint(_n)].value;
    }

    function setVariable(bytes2 _n, bytes32 _val) public returns (bool) {
        cobalt_variables[uint(_n)].value = _val;
    }
}