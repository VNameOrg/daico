pragma solidity ^0.4.17;

import "./Util/OwnerUtil.sol";
import "./Util/ByteUtil.sol";
import "./PollFactory.sol";
import "./COALITE/COALITE1Token.sol";

contract VNameDaico is OwnerUtil {

    using SafeMath for uint;

    mapping(bytes8 => string) public cobalt_variableMapping;

    //address of the poll factory contract
    PollFactory public pollFactory;

    //address of the COALITE Token Contract for the NAME Token
    COALITE1Token public tokenNAME;

    //amount of NAME remaining in DAICO Balance
    uint public balance_daico;      //total
    uint public balance_presale;    //pre-sale
    uint public balance_sale;       //public sale total
    uint public balance_sale_1;     //first level
    uint public balance_sale_2;     //second level
    uint public balance_sale_3;     //third level
    uint public balance_sale_4;     //fourth level

    //amount of NAME remaining in Team Balance
    uint public balance_team;

    //rate in wei/s in which funds can be removed
    uint public tap;

    //the time when the tap was last called
    uint public time_lastTap;

    uint public timeBetweenTap;

    //how much 1 wei gets you in NAME
    uint public rate_presale;
    uint public rate_sale_1;
    uint public rate_sale_2;
    uint public rate_sale_3;
    uint public rate_sale_4;

    //timestamps for when the sale periods begin
    uint public time_presale;
    uint public time_presale_end;
    uint public time_sale_end;

    function VNameDaico(PollFactory _pollFactory) public {
        owners[msg.sender] = Permissions(true, 10);
        pollFactory = _pollFactory;
        owners[_pollFactory] = Permissions(true, 9);

        //set initial tap value to 100 000 gwei/s
        tap = 100000000000000;
                                                               //  ,  ,  .                   
        tokenNAME = new COALITE1Token("VName Token", "NAME", 18, 300000000000000000000000000);
        balance_daico =  186000000000000000000000000;   //186,000,000.000000000000000000

        balance_presale = 14880000000000000000000000;   // 14,880,000.000000000000000000

        balance_sale  =  171120000000000000000000000;   //171,120,000.000000000000000000
        balance_sale_1 =  24180000000000000000000000;   // 24,180,000.000000000000000000
        balance_sale_2 =  37200000000000000000000000;   // 37,200,000.000000000000000000
        balance_sale_3 =  50220000000000000000000000;   // 50,220,000.000000000000000000
        balance_sale_4 =  59520000000000000000000000;   // 59,520,000.000000000000000000

        balance_team  =   30000000000000000000000000;   // 30,000,000.000000000000000000

        rate_presale = 25000;
        rate_sale_1 =  22000;
        rate_sale_2 =  21000;
        rate_sale_3 =  20000;
        rate_sale_4 =  18500;

        time_presale = 0;
        time_presale_end = 0;
        time_sale_end = 0;

        timeBetweenTap = 1296000; //15 days

        time_lastTap = block.timestamp;

        cobalt_variableMapping[0x01] = "tap";
        cobalt_variableMapping[0x02] = "time_presale";
        cobalt_variableMapping[0x03] = "time_presale_end";
        cobalt_variableMapping[0x04] = "time_sale_end";
        cobalt_variableMapping[0x05] = "timeBetweenTap";
    }

    function _getCurrentStage() internal returns (uint) {
        uint time = block.timestamp;

        if(time > time_sale_end) {
            return 5;
        }

        if(time > time_presale && time < time_presale_end) {
            return 0;
        } else {
            if(balance_sale_1 > 0) {
                return 1;
            }
            if(balance_sale_2 > 0) {
                return 2;
            }
            if(balance_sale_3 > 0) {
                return 3;
            }
            if(balance_sale_4 > 0) {
                return 4;
            }
            return 5;
        }
    }

    function _getCurrentRate(uint _stage) internal returns (uint) {
        if(_stage == 0) {
            return rate_presale;
        }
        if(_stage == 1) {
            return rate_sale_1;
        }
        if(_stage == 2) {
            return rate_sale_2;
        }
        if(_stage == 3) {
            return rate_sale_3;
        }
        if(_stage == 4) {
            return rate_sale_4;
        }
    }

    function _getCurrentBalance(uint _stage) internal returns (uint) {
        if(_stage == 0) {
            return balance_presale;
        }
        if(_stage == 1) {
            return balance_sale_1;
        }
        if(_stage == 2) {
            return balance_sale_2;
        }
        if(_stage == 3) {
            return balance_sale_3;
        }
        if(_stage == 4) {
            return balance_sale_4;
        }
    }

    function _subFromCurrentBalance(uint _stage, uint _value) internal returns (bool) {
        if(_stage == 0) {
            balance_presale = balance_presale.sub(_value);
            return true;
        }
        if(_stage == 1) {
            balance_sale_1 = balance_sale_1.sub(_value);
            return true;
        }
        if(_stage == 2) {
            balance_sale_2 = balance_sale_2.sub(_value);
            return true;
        }
        if(_stage == 3) {
            balance_sale_3 = balance_sale_3.sub(_value);
            return true;
        }
        if(_stage == 4) {
            balance_sale_4 = balance_sale_4.sub(_value);
            return true;
        }
    }

    function buy() public payable returns (uint) {
        //get the current stage and ensure it's a valid sale stage
        uint stage = _getCurrentStage();
        require(stage < 5);

        //get the amount of tokens based off rate and ensure that enough tokens are available in current stage
        uint rate = _getCurrentRate(stage);
        uint tokens = msg.value * rate;
        uint currentBalance = _getCurrentBalance(stage);

        if(tokens <= currentBalance) {                          //if amount of tokens being bought is <= balance of current stage
            require(_subFromCurrentBalance(stage, tokens));
        } else {                                                //if amount of tokens being bought is > balance of current stage
            require(stage != 0);                                //require that current stage isnt presale                               
            require(stage+1 < 5);                               //require that next stage exists
            uint subTokens = _getCurrentBalance(stage);
            uint subWei = SafeMath.div(tokens.sub(subTokens), rate);
            uint newTokens = subWei * _getCurrentRate(stage+1);
            tokens = subTokens.add(newTokens);
            require(_subFromCurrentBalance(stage, subTokens));
            require(_subFromCurrentBalance(stage+1, newTokens)); 
        }

        tokenNAME.transfer(msg.sender, tokens);
        return tokens;
    }

    function poll_increaseTap(bytes32 _newValue, uint _voteMargin) public onlyOwner returns (bool, uint) {
        return pollFactory.createPoll(ByteUtil.concatByt3(0x12010103, _newValue, 0x02), _voteMargin, 0);
    }

    function createDraft(bytes32 _cobalt_identifier, uint _voteMargin) public returns (bool, uint) {
        return pollFactory.createDraft(_cobalt_identifier, _voteMargin, 0);
    }

    function processDraft(uint _id) public returns (bool, uint) {
        return pollFactory.processDraft(_id);
    }

    function processPoll(uint _id) public returns (bool, uint) {
        return pollFactory.processDraft(_id);
    }

    function withdrawTap() public onlyOwner returns (uint) {
        uint time = block.timestamp;

        //require that at least timeBetweenTap (seconds) has passed since last call of function
        require(time.sub(timeBetweenTap) >= time_lastTap);
        uint deltaTime = time - time_lastTap;

        uint eth = deltaTime * tap;
        if(eth > this.balance) {
            eth = this.balance;
        }

        msg.sender.transfer(eth);
    }

    function processPollCallback(bytes32 cobalt_identifier) public returns (bool, uint) {
        require(msg.sender == address(pollFactory));
    }
}