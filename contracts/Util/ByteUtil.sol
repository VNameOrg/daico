pragma solidity ^0.4.17;

library ByteUtil {

    function leftShift_UintToByte (uint _in) public pure returns (bytes32 conv, uint len) {
        conv = bytes32(_in);
        while(conv[31-len] != 0x00) {
            ++len;
        }
        conv = conv << 8*(32-len);
    }

    function uintToMeasuredByt(uint _in) public pure returns (bytes32 result) {
        bytes32 conv;
        uint len;
        (conv, len) = leftShift_UintToByte(_in);
        conv = conv >> 8;
        byte bLen = byte(len);
        assembly {
            result := add(bLen, conv)
        }
    }

    function leftShift_BytToUint(bytes32 _in, uint _len) public pure returns (uint) {
        uint shift = 32 - _len;
        return uint(_in >> 8*shift);
    }

    function measuredBytToUint(bytes32 _byt) public pure returns (uint) {
        uint _len = uint(byte(_byt));
        bytes32 _in = _byt << 8;
        return leftShift_BytToUint(_in, _len); 
    }

    function concatByt3(bytes32 _a, bytes32 _b, bytes32 _c) public pure returns (bytes32) {
        uint count = 0;
        bytes32 result;
        bytes32 sum;
        
        //first part
        for(uint i1 = 0; i1 < 32; ++i1) {
            if(_a[i1] == 0x00) {
                break;
            }
            require(count < 32);
            sum = bytes32(_a[i1]) >> 8*count;
            assembly {
                result := add(result, sum)
            }
            count++;
        }
        
        //second part
        for(uint i2 = 0; i2 < 32; ++i2) {
            if(_b[i2] == 0x00) {
                break;
            }
            require(count < 32);
            sum = bytes32(_b[i2]) >> 8*count;
            assembly {
                result := add(result, sum)
            }
            count++;
        }
        
        //third part
        for(uint i3 = 0; i3 < 32; ++i3) {
            if(_c[i3] == 0x00) {
                break;
            }
            require(count < 32);
            sum = bytes32(_c[i3]) >> 8*count;
            assembly {
                result := add(result, sum)
            }
            count++;
        }
        
        return result;
    }
}