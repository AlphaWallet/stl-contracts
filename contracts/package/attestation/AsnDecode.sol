/* Attestation decode and validation */
/* AlphaWallet 2021 - 2022 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract AsnDecode {
    struct Status {
        uint decodeIndex;
        uint objCodeIndex;
    }

    function decodeLength(
        bytes memory byteCode,
        uint decodeIndex
    ) internal pure returns (uint256 length, uint256 newIndex, bytes1 tag) {
        uint codeLength = 1;
        length = 0;
        newIndex = decodeIndex;
        tag = bytes1(byteCode[newIndex++]);

        if ((byteCode[newIndex] & 0x80) == 0x80) {
            codeLength = uint8((byteCode[newIndex++] & 0x7f));
        }

        for (uint i = 0; i < codeLength; i++) {
            length |= uint(uint8(byteCode[newIndex++] & 0xFF)) << ((codeLength - i - 1) * 8);
        }
    }

    function copyDataBlock(bytes memory byteCode, uint dIndex, uint length) internal pure returns (bytes memory data) {
        uint256 blank = 0;
        uint256 index = dIndex;

        uint dStart = 0x20 + index;
        uint cycles = length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - remove the looping
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank
        }

        data = new bytes(requiredAlloc);

        assembly {
            let mc := add(data, 0x20) //offset into bytes we're writing into
            let cycle := 0

            for {
                let cc := add(byteCode, dStart)
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size
        if (length % 0x20 > 0) {
            uint offsetStart = 0x20 + length;
            assembly {
                let mc := add(data, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back
                mstore(data, length)
            }
        }
    }

    function decodeElementOffset(
        bytes memory byteCode,
        uint decodeIndex,
        uint offset
    ) internal pure returns (uint256 length, bytes memory content, uint256 newIndex) {
        (content, newIndex, length, ) = decodeDERData(byteCode, decodeIndex, offset);
    }

    //////////////////////////////////////////////////////////////
    // DER Helper functions
    //////////////////////////////////////////////////////////////

    function decodeDERData(
        bytes memory byteCode,
        uint dIndex
    ) internal pure returns (bytes memory data, uint256 index, uint256 length, bytes1 tag) {
        return decodeDERData(byteCode, dIndex, 0);
    }

    function decodeDERData(
        bytes memory byteCode,
        uint dIndex,
        uint offset
    ) internal pure returns (bytes memory data, uint256 index, uint256 length, bytes1 tag) {
        index = dIndex;

        (length, index, tag) = decodeLength(byteCode, index);

        if (offset <= length) {
            uint requiredLength = length - offset;
            uint dStart = index + offset;

            data = copyDataBlock(byteCode, dStart, requiredLength);
        } else {
            data = bytes("");
        }

        index += length;
    }

    function copyStringBlock(bytes memory byteCode) internal pure returns (string memory stringData) {
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;

        uint cycles = byteCode.length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }

        stringData = new string(requiredAlloc);

        //copy data in 32 byte blocks
        assembly {
            let cycle := 0

            for {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20) //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0) {
            uint offsetStart = 0x20 + length;
            assembly {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
        }
    }

    function decodeElement(
        bytes memory byteCode,
        uint decodeIndex
    ) internal pure returns (uint256 length, bytes memory content, uint256 newIndex, bytes1 tag) {
        (content, newIndex, length, tag) = decodeDERData(byteCode, decodeIndex);
    }

    function decodeIA5String(
        bytes memory byteCode,
        uint256[] memory objCodes,
        uint objCodeIndex,
        uint decodeIndex
    ) internal pure returns (Status memory) {
        uint length = uint8(byteCode[decodeIndex++]);
        bytes32 store = 0;
        for (uint j = 0; j < length; j++) store |= bytes32(byteCode[decodeIndex++] & 0xFF) >> (j * 8);
        objCodes[objCodeIndex++] = uint256(store);
        Status memory retVal;
        retVal.decodeIndex = decodeIndex;
        retVal.objCodeIndex = objCodeIndex;

        return retVal;
    }
}
