pragma solidity ^0.4.17;

interface ICOALITEDataBase {
    function tokenExists(address _token) public view returns (bool);
}