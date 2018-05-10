pragma solidity ^0.4.17;

contract OwnerUtil {

    struct Permissions {
        bool isOwner;
        uint8 permLevel; //possible options: 0 - 255; recommended: 1 - 10
    }

    mapping(address => Permissions) public owners;


    function _isOwner(address _usr) internal view returns (bool isOwner) {

        return owners[_usr].isOwner;
    }

    function _hasPermission(address _usr, uint8 _level) internal view returns (bool isOwner) {

        return owners[_usr].permLevel >= _level;
    }

    modifier onlyOwner {

        require(_isOwner(msg.sender));
        _;
    }

    modifier hasPermission(uint8 _level) {

        require(_hasPermission(msg.sender, _level));
        _;
    }

    modifier hasPermissionAbove(uint8 _level) {

        uint8 compare = _level;
        if (compare < 255) {
            compare = compare + 1;
        }

        require(_hasPermission(msg.sender, compare));
        _;
    }

    function addOwner(address _newOwner, uint8 _level) onlyOwner hasPermission(_level) public returns (bool success) {

        require(!_isOwner(_newOwner));
        require(_hasPermission(msg.sender, _level));

        owners[_newOwner] = Permissions(true,_level);
        return true;
    }

    function setOwner(address _owner, bool _state, uint8 _level) onlyOwner hasPermissionAbove(owners[_owner].permLevel) public returns (bool success) {

        require(_hasPermission(msg.sender, _level));

        owners[_owner] = Permissions(_state, _level);
        return true;
    }

    function removeOwner(address _owner) onlyOwner hasPermissionAbove(owners[_owner].permLevel) public returns (bool success) {
            
        owners[_owner] = Permissions(false,0);
        return true;
    }
}