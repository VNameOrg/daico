pragma solidity ^0.4.17;

import "../Util/OwnerUtil.sol";
import "./Interfaces/ICOALITE1Receiver.sol";

/**
 * @dev Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
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

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

/**
 * @title COALITE1 Token Protocol
 * @author Ilan Garcia
 * @dev The following is the COALITE1 Protocol that can be used as is or inherited
 */
contract COALITE1Token {

    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply;

    event Transfer(address indexed from, address indexed to, uint tokens, bytes data);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint tokens);

    function () public payable {
        revert();
    }

    function COALITE1Token(string _name, string _symbol, uint8 _decimals, uint _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    /**
     * @dev internal transfer function. issues a transfer of defined tokens and if the address
            is a contract, calls the COALITE tokenReceived function
     *
     * @param _from address sending tokens
     * @param _to address receiving tokens
     * @param _value amount of tokens being sent
     * @param _data optional data being included
     */
    function _transfer(address _from, address _to, uint _value, bytes _data) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        if (codeLength>0) {
            ICOALITE1Receiver receiver = ICOALITE1Receiver(_to);
            // Ensure that the Receiver accepts the provided token and amount
            require(receiver.tokenReceived(msg.sender, _value, _data));
        }

        Transfer(_from, _to, _value, _data);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    /**
     * @dev public method that calls the internal function responsible for sending tokens
     *
     * @param _to address receiving tokens
     * @param _value amount of tokens being sent
     * @param _data optional data being included
     */
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        _transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    /**
     * @dev public method that calls the internal function responsible for sending tokens. sends without data
     *
     * @param _to address receiving tokens
     * @param _value amount of tokens being sent
     */
    function transfer(address _to, uint _value) public returns (bool success) {

        bytes memory empty;

        transfer(_to, _value, empty);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     * @param _data the data to send in the transaction
     */
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value, _data);
        return true;
    }

    /**
     * Transfer tokens from other address (does not send data)
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        bytes memory empty;
        return transferFrom(_from, _to, _value, empty);
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {

        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply.sub(_value);                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender].sub(_value);             // Subtract from the sender's allowance
        totalSupply.sub(_value);                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}