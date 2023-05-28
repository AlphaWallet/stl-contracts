/* Attestation decode and validation */
/* AlphaWallet 2021 - 2022 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./AsnDecode.sol";
import "./Utils.sol";

contract IdAttest is AsnDecode, Utils {
    uint constant TTL_GAP = 300; // 5 min
    bytes1 constant INTEGER_TAG = bytes1(0x02);
    bytes1 constant COMPOUND_TAG = bytes1(0xA3);

    function recoverSignedIdentifierAddress(
        bytes memory attestation,
        uint256 hashIndex
    )
        internal
        view
        returns (address signer, address subject, bytes memory id_commitment, uint256 resultIndex, bool timeStampValid)
    {
        bytes memory sigData;

        uint256 length;
        uint256 decodeIndex;
        uint256 headerIndex;

        (, hashIndex, ) = decodeLength(attestation, hashIndex); //576  (SignedIdentifierAttestation)

        (length, headerIndex, ) = decodeLength(attestation, hashIndex); //493  (IdentifierAttestation)

        // resultIndex = length + headerIndex; // (length + decodeIndex) - hashIndex);

        bytes memory preHash = copyDataBlock(attestation, hashIndex, (length + headerIndex) - hashIndex);

        decodeIndex = headerIndex + length;

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //Signature algorithm

        (, sigData, resultIndex) = decodeElementOffset(attestation, decodeIndex + length, 1); // Signature

        //get signing address
        signer = recoverSigner(preHash, sigData);

        //Recover public key
        (length, decodeIndex, ) = decodeLength(attestation, headerIndex); //read Version

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Serial

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Signature type (9) 1.2.840.10045.2.1

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Issuer Sequence (14) [[2.5.4.3, ALX]]], (Issuer: CN=ALX)

        (decodeIndex, timeStampValid) = decodeTimeBlock(attestation, decodeIndex + length);

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); // Smartcontract?

        (subject, decodeIndex) = addressFromPublicKey(attestation, decodeIndex + length);

        id_commitment = decodeCommitment(attestation, decodeIndex);
    }

    function recoverSigner(bytes memory prehash, bytes memory signature) internal pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(keccak256(prehash), v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function decodeTimeBlock(
        bytes memory attestation,
        uint256 decodeIndex
    ) internal view returns (uint256 index, bool valid) {
        bytes memory timeBlock;
        uint256 length;
        uint256 blockLength;
        bytes1 tag;

        (blockLength, index, ) = decodeLength(attestation, decodeIndex); //30 32
        (length, decodeIndex, ) = decodeLength(attestation, index); //18 0f
        (length, timeBlock, decodeIndex, tag) = decodeElement(attestation, decodeIndex + length); //INTEGER_TAG if blockchain friendly time is used
        if (tag == INTEGER_TAG) {
            uint256 startTime = bytesToUint(timeBlock);
            (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //18 0F
            (, timeBlock, decodeIndex, ) = decodeElement(attestation, decodeIndex + length);
            uint256 endTime = bytesToUint(timeBlock);
            valid = block.timestamp > (startTime - TTL_GAP) && block.timestamp < endTime;
        } else {
            valid = false; //fail attestation without blockchain friendly timestamps
        }

        index = index + blockLength;
    }

    function addressFromPublicKey(
        bytes memory attestation,
        uint256 decodeIndex
    ) internal pure returns (address keyAddress, uint256 resultIndex) {
        uint256 length;
        bytes memory publicKeyBytes;
        (, decodeIndex, ) = decodeLength(attestation, decodeIndex); // 307 key headerIndex
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); // 236 header tag

        (, publicKeyBytes, resultIndex) = decodeElementOffset(attestation, decodeIndex + length, 2); // public key

        keyAddress = publicKeyToAddress(publicKeyBytes);
    }

    function publicKeyToAddress(bytes memory publicKey) internal pure returns (address keyAddr) {
        bytes32 keyHash = keccak256(publicKey);
        bytes memory scratch = new bytes(32);

        assembly {
            mstore(add(scratch, 32), keyHash)
            mstore(add(scratch, 12), 0)
            keyAddr := mload(add(scratch, 32))
        }
    }

    function decodeCommitment(
        bytes memory attestation,
        uint256 decodeIndex
    ) internal pure virtual returns (bytes memory commitment) {
        uint256 length;

        if (attestation[decodeIndex] != COMPOUND_TAG) {
            // its not commitment, but some other data. example:  SEQUENCE (INTEGER 42, INTEGER 1337)
            (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); // some payload
        }

        (commitment, ) = recoverCommitment(attestation, decodeIndex + length); // Commitment 1, generated by
        // IdentifierAttestation constructor
    }

    function recoverCommitment(
        bytes memory attestation,
        uint256 decodeIndex
    ) internal pure returns (bytes memory commitment, uint256 resultIndex) {
        uint256 length;
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); // Commitment tag (0x57)
        //pull Commitment
        commitment = copyDataBlock(attestation, decodeIndex + (length - 65), 65);
        resultIndex = decodeIndex + length;
    }
}
