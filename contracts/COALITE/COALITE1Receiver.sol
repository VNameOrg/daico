pragma solidity ^0.4.17;

import '../Util/OwnerUtil.sol';
import './Interfaces/ICOALITEDataBase.sol';
import './Interfaces/ICOALITE1Token.sol';

interface ERC20 { function transfer(address to, uint tokens) public returns (bool success); }

/**
 * @title COALITE1 Token Receiver
 * @author Ilan Garcia
 * @dev The Receiver provides a method for a contract to receive a fallback call from a COALITE1 Token and act accordingly
 */
contract COALITE1Receiver is OwnerUtil {

    enum ReferenceMode {
        SINGLE,
        DATABASE,
        ALL
    }

    ReferenceMode mode;
    address TokenAddr;
    ICOALITEDataBase DB;

    ///Called by a COALITE Token
    function tokenReceived(address _sender, uint _value, bytes _data) public returns (bool) {

        //get the token that called this function
        address token = msg.sender;

        //see what mode the Receiver is set to
        //act accordingly: ensure that the token calling the function is accepted

        if (mode == ReferenceMode.SINGLE) {
            if (token != TokenAddr) {
                return false;
            }
        }


        //if using DATABASE mode it's recommended to check which token is being provided using DB.tokens(address _token)
        if (mode == ReferenceMode.DATABASE) {
            if (!DB.tokenExists(token)) {
                return false;
            }
        }

        //if the _data given is at least 4 bytes then it means it can possibly have a valid sig
        if (_data.length >= 4) {
            uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
            bytes4 sig = bytes4(u);

            if (u != 0) {

                this.call(sig, _data);
            }
        }

        //calls internal function which contains custom code
        return _tokenReceivedInternal(token, _sender, _value, _data);
    }

    /**
     * @dev function to be overriden in contract being built. called by tokenReceived after running initial checks
     *
     * @param _token address of the token calling this function
     * @param _sender address of the individual that called the transfer
     * @param _value the amount of tokens in the transfer
     * @param _data optional data included in the transaction
     *
     * @return returns if the transfer is allowed. if false, the transfer will be reverted
     */
    function _tokenReceivedInternal(address _token, address _sender, uint _value, bytes _data) internal returns (bool);

    /**
     * @dev sets the Receiver to SINGLE mode and sets the token address that is accepted
     *
     * @param _token the address of the token to accept
     */
    function setTokenAddress(address _token) public onlyOwner {

        mode = ReferenceMode.SINGLE;
        TokenAddr = _token;
    }

    /**
     * @dev sets the Receiver to DATABASE mode and sets the address to the database containing all accepted tokens
     *
     * @param _db the address of the database to use
     */
    function setDataBase(address _db) public onlyOwner {

        mode = ReferenceMode.DATABASE;
        DB = ICOALITEDataBase(_db);
    }

    /**
     *  @dev sets the Receiver to ALL mode: this allows any token to accepted by the Receiver
     */
    function setNone() public onlyOwner {

        mode = ReferenceMode.ALL;
    }

    /**
     * @dev In case of emergency. Manually send tokens to an address in the event that they get stuck unintentionally.
     *      FOR COALITE TOKENS
     *
     * @param _token address of the (COALITE) token being transferred
     * @param _to address of the person receiving the tokens
     * @param _amount amount of tokens being sent
     */
    function transferTokenCOALITE(address _token, address _to, uint _amount) public onlyOwner {

        ICOALITE1Token(_token).transfer(_to, _amount);
    }

    /**
     * @dev In case of emergency. Manually send tokens to an address in the event that they get stuck unintentionally.
     *      FOR ERC20 TOKENS
     *
     * @param _token address of the (ERC20) token being transferred
     * @param _to address of the person receiving the tokens
     * @param _amount amount of tokens being sent
     */
    function transferTokenERC20(address _token, address _to, uint _amount) public onlyOwner {

        ERC20(_token).transfer(_to, _amount);
    }



}