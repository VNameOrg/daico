pragma solidity ^0.4.17;

import '../Util/OwnerUtil.sol';

/**
 * @title COALITE Token Reference Database
 * @author Ilan Garcia
 * @dev The COALITE Token Database serves as a way to reference tokens that utilize the COALITE Protocol.
 *      Although not required, the Database creates an uncentralized registry of Tokens utilizing the Protocol.
 *      This should NOT be used as means of security due to it's current design.
 */
contract COALITEDataBase is OwnerUtil {

    string public databaseName; //Name of DataBase
    address public creatorAddress; //Creator of the DataBase

    struct Token {
        string name;
        string symbol;
        uint8 decimals;
        uint8 version;  //used to manage what version of the COALITE Protocol the Token uses
    }

    mapping(address => Token) public tokens;

    function COALITEDataBase(string _dbName) public {

        databaseName = _dbName;
        creatorAddress = msg.sender;
        owners[msg.sender] = Permissions(true, 10);
    }

    function tokenExists(address _token) public view returns (bool) {

        return tokens[_token].version > 0;
    }

    function setToken(address _token, string _name, string _symbol, uint8 _decimals, uint8 _version) public onlyOwner {

        if (_version == 0) { 
            _version = 1; 
        }
        
        tokens[_token] = Token(_name, _symbol, _decimals, _version);
    }

    function deleteToken(address _token) public onlyOwner {

        delete tokens[_token];
    }


}