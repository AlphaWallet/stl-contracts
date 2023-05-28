/* Attestation decode and validation */
/* AlphaWallet 2021 - 2022 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./AsnDecode.sol";
import "./Utils.sol";

contract Pok is AsnDecode, Utils {
    // uint256[2] private G = [ 21282764439311451829394129092047993080259557426320933158672611067687630484067,
    // 3813889942691430704369624600187664845713336792511424430006907067499686345744 ];

    // uint256[2] private H = [ 10844896013696871595893151490650636250667003995871483372134187278207473369077,
    // 9393217696329481319187854592386054938412168121447413803797200472841959383227 ];

    uint256 constant H_X = 10844896013696871595893151490650636250667003995871483372134187278207473369077;
    uint256 constant H_Y = 9393217696329481319187854592386054938412168121447413803797200472841959383227;

    uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 public constant CURVE_ORDER = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 constant CURVE_ORDER_BIT_LENGTH = 254;
    uint256 constant CURVE_ORDER_BIT_SHIFT = 256 - CURVE_ORDER_BIT_LENGTH;

    bytes constant H_POINT =
        abi.encodePacked(
            uint8(0x04),
            uint256(10844896013696871595893151490650636250667003995871483372134187278207473369077),
            uint256(9393217696329481319187854592386054938412168121447413803797200472841959383227)
        );

    struct FullProofOfExponent {
        bytes tPoint;
        uint256 challenge;
        bytes entropy;
    }

    function recoverPOK(
        bytes memory attestation,
        uint256 decodeIndex
    ) internal pure returns (FullProofOfExponent memory pok, uint256 resultIndex) {
        bytes memory data;
        (, decodeIndex, ) = decodeLength(attestation, decodeIndex); //68 POK data
        (, data, decodeIndex, ) = decodeElement(attestation, decodeIndex);
        pok.challenge = bytesToUint(data);
        (, pok.tPoint, decodeIndex, ) = decodeElement(attestation, decodeIndex);
        (, pok.entropy, resultIndex, ) = decodeElement(attestation, decodeIndex);
    }

    function verifyPOK(
        bytes memory com1,
        bytes memory com2,
        FullProofOfExponent memory pok
    ) internal view returns (bool) {
        // Riddle is H*(r1-r2) with r1, r2 being the secret randomness of com1, respectively com2
        uint256[2] memory riddle = getRiddle(com1, com2);

        // Compute challenge in a Fiat-Shamir style, based on context specific entropy to avoid reuse of proof
        bytes memory cArray = abi.encodePacked(H_POINT, com1, com2, pok.tPoint, pok.entropy);
        uint256 c = mapToCurveMultiplier(cArray);

        uint256[2] memory lhs = ecMul(pok.challenge, H_X, H_Y);
        if (lhs[0] == 0 && lhs[1] == 0) {
            return false;
        } //early revert to avoid spending more gas

        //ECPoint riddle multiply by proof (component hash)
        uint256[2] memory rhs = ecMul(c, riddle[0], riddle[1]);
        if (rhs[0] == 0 && rhs[1] == 0) {
            return false;
        } //early revert to avoid spending more gas

        uint256[2] memory point;
        (point[0], point[1]) = extractXYFromPoint(pok.tPoint);
        rhs = ecAdd(rhs, point);

        return ecEquals(lhs, rhs);
    }

    function ecEquals(uint256[2] memory ecPoint1, uint256[2] memory ecPoint2) private pure returns (bool) {
        return (ecPoint1[0] == ecPoint2[0] && ecPoint1[1] == ecPoint2[1]);
    }

    //////////////////////////////////////////////////////////////
    // Cryptograph_Y & Ethereum constructs
    //////////////////////////////////////////////////////////////

    function getRiddle(bytes memory com1, bytes memory com2) internal view returns (uint256[2] memory riddle) {
        uint256[2] memory lhs;
        uint256[2] memory rhs;
        (lhs[0], lhs[1]) = extractXYFromPoint(com1);
        (rhs[0], rhs[1]) = extractXYFromPoint(com2);

        rhs = ecInv(rhs);

        riddle = ecAdd(lhs, rhs);
    }

    /* Verify ZK (Zero-Knowledge) proof of equality of message in two
       Pedersen commitments by proving knowledge of the discrete log
       of their difference. This verifies that the message
       (identifier, such as email address) in both commitments are the
       same, and the one constructing the proof knows the secret of
       both these commitments.  See:

     Commitment1: https://github.com/TokenScript/attestation/blob/main/src/main/java/org/tokenscript/attestation/IdentifierAttestation.java

     Commitment2: https://github.com/TokenScript/attestation/blob/main/src/main/java/org/devcon/ticket/Ticket.java

     Reference implementation: https://github.com/TokenScript/attestation/blob/main/src/main/java/org/tokenscript/attestation/core/AttestationCrypto.java
    */

    function extractXYFromPoint(bytes memory data) internal pure returns (uint256 x, uint256 y) {
        assembly {
            x := mload(add(data, 0x21)) //copy from 33rd byte because first 32 bytes are array length, then 1st byte of data is the 0x04;
            y := mload(add(data, 0x41)) //65th byte as x value is 32 bytes.
        }
    }

    function ecAdd(uint256[2] memory p1, uint256[2] memory p2) internal view returns (uint256[2] memory retP) {
        bool success;
        uint256[4] memory i = [p1[0], p1[1], p2[0], p2[1]];

        assembly {
            // call ecadd precompile
            // inputs are: x1, y1, x2, y2
            success := staticcall(not(0), 0x06, i, 0x80, retP, 0x40)
        }

        if (!success) {
            retP[0] = 0;
            retP[1] = 0;
        }
    }

    // Note, this will return 0 if the shifted hash > curveOrder, which will cause the equate to fail
    function mapToCurveMultiplier(bytes memory input) internal pure returns (uint256 res) {
        bytes memory nextInput = input;
        bytes32 idHash = keccak256(nextInput);
        res = uint256(idHash) >> CURVE_ORDER_BIT_SHIFT;
        if (res >= CURVE_ORDER) {
            res = 0;
        }
    }

    function ecMul(uint256 s, uint256 x, uint256 y) internal view returns (uint256[2] memory retP) {
        bool success;
        // With a public key (x, y), this computes p = scalar * (x, y).
        uint256[3] memory i = [x, y, s];

        assembly {
            // call ecmul precompile
            // inputs are: x, y, scalar
            success := staticcall(not(0), 0x07, i, 0x60, retP, 0x40)
        }

        if (!success) {
            retP[0] = 0;
            retP[1] = 0;
        }
    }

    function ecInv(uint256[2] memory point) private pure returns (uint256[2] memory invPoint) {
        invPoint[0] = point[0];
        int256 n = int256(FIELD_SIZE) - int256(point[1]);
        n = n % int256(FIELD_SIZE);
        if (n < 0) {
            n += int256(FIELD_SIZE);
        }
        invPoint[1] = uint256(n);
    }
}
