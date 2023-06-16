/* Attestation decode and validation */
/* AlphaWallet 2021 - 2022 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./AsnDecode.sol";
import "./IdAttest.sol";
import "./Pok.sol";

contract VerifyAttestation is AsnDecode, IdAttest, Pok {
    /*    
    // List of All TAGs 
    bytes1 constant BOOLEAN_TAG = bytes1(0x01);
    // bytes1 constant INTEGER_TAG = bytes1(0x02);
    bytes1 constant BIT_STRING_TAG = bytes1(0x03);
    bytes1 constant OCTET_STRING_TAG = bytes1(0x04);
    bytes1 constant NULL_TAG = bytes1(0x05);
    bytes1 constant OBJECT_IDENTIFIER_TAG = bytes1(0x06);
    bytes1 constant EXTERNAL_TAG = bytes1(0x08);
    bytes1 constant ENUMERATED_TAG = bytes1(0x0a); // decimal 10
    bytes1 constant SEQUENCE_TAG = bytes1(0x10); // decimal 16
    bytes1 constant SET_TAG = bytes1(0x11); // decimal 17
    bytes1 constant SET_OF_TAG = bytes1(0x11);

    bytes1 constant NUMERIC_STRING_TAG = bytes1(0x12); // decimal 18
    bytes1 constant PRINTABLE_STRING_TAG = bytes1(0x13); // decimal 19
    bytes1 constant T61_STRING_TAG = bytes1(0x14); // decimal 20
    bytes1 constant VIDEOTEX_STRING_TAG = bytes1(0x15); // decimal 21
    bytes1 constant IA5_STRING_TAG = bytes1(0x16); // decimal 22
    bytes1 constant UTC_TIME_TAG = bytes1(0x17); // decimal 23
    bytes1 constant GENERALIZED_TIME_TAG = bytes1(0x18); // decimal 24
    bytes1 constant GRAPHIC_STRING_TAG = bytes1(0x19); // decimal 25
    bytes1 constant VISIBLE_STRING_TAG = bytes1(0x1a); // decimal 26
    bytes1 constant GENERAL_STRING_TAG = bytes1(0x1b); // decimal 27
    bytes1 constant UNIVERSAL_STRING_TAG = bytes1(0x1c); // decimal 28
    bytes1 constant BMP_STRING_TAG = bytes1(0x1e); // decimal 30
    bytes1 constant UTF8_STRING_TAG = bytes1(0x0c); // decimal 12

    bytes1 constant CONSTRUCTED_TAG = bytes1(0x20); // decimal 28

    bytes1 constant LENGTH_TAG = bytes1(0x30);
    bytes1 constant VERSION_TAG = bytes1(0xA0);
    // bytes1 constant COMPOUND_TAG = bytes1(0xA3);

    uint256 constant IA5_CODE = uint256(bytes32("IA5")); //tags for disambiguating content
    uint256 constant DEROBJ_CODE = uint256(bytes32("OBJID"));
*/
    // event Value(uint256 indexed val);
    // event RtnStr(bytes val);
    // event RtnS(string val);

    // uint256 constant pointLength = 65;

    // We create byte arrays for these at construction time to save gas when we need to use them
    // bytes constant GPoint =
    //     abi.encodePacked(
    //         uint8(0x04),
    //         uint256(21282764439311451829394129092047993080259557426320933158672611067687630484067),
    //         uint256(3813889942691430704369624600187664845713336792511424430006907067499686345744)
    //     );

    bytes constant EMPTY_BYTES = new bytes(0x00);

    // struct Length {
    //     uint decodeIndex;
    //     uint length;
    // }

    /**
     * Perform TicketAttestation verification
     * NOTE: This function DOES NOT VALIDATE whether the public key attested to is the same as the one who signed this transaction; you must perform validation of the subject from the calling function.
     **/
    function verifyTicketAttestation(
        bytes memory attestation,
        address attestor,
        address ticketIssuer
    ) public view returns (address subject, bytes memory ticketId, bytes memory conferenceId, bool attestationValid) {
        address recoveredAttestor;
        address recoveredIssuer;

        (
            recoveredAttestor,
            recoveredIssuer,
            subject,
            ticketId,
            conferenceId,
            attestationValid
        ) = _verifyTicketAttestation(attestation);

        if (recoveredAttestor != attestor || recoveredIssuer != ticketIssuer || !attestationValid) {
            subject = address(0);
            ticketId = EMPTY_BYTES;
            conferenceId = EMPTY_BYTES;
            attestationValid = false;
        }
    }

    function verifyTicketAttestation(
        bytes memory attestation
    )
        public
        view
        returns (
            address attestor,
            address ticketIssuer,
            address subject,
            bytes memory ticketId,
            bytes memory conferenceId,
            bool attestationValid
        )
    {
        (attestor, ticketIssuer, subject, ticketId, conferenceId, attestationValid) = _verifyTicketAttestation(
            attestation
        );
    }

    function _verifyTicketAttestation(
        bytes memory attestation
    )
        internal
        view
        returns (
            address attestor,
            address ticketIssuer,
            address subject,
            bytes memory ticketId,
            bytes memory conferenceId,
            bool attestationValid
        )
    {
        uint256 decodeIndex = 0;
        uint256 length = 0;
        FullProofOfExponent memory pok;
        // Commitment to user identifier in Attestation
        bytes memory id_commitment;
        // Commitment to user identifier in Ticket
        bytes memory ticket_commitment;

        (length, decodeIndex, ) = decodeLength(attestation, 0); //852 (total length, primary header)

        (ticketIssuer, ticketId, conferenceId, ticket_commitment, decodeIndex) = recoverTicketSignatureAddress(
            attestation,
            decodeIndex
        );

        (attestor, subject, id_commitment, decodeIndex, attestationValid) = recoverSignedIdentifierAddress(
            attestation,
            decodeIndex
        );

        //now pull ZK (Zero-Knowledge) POK (Proof Of Knowledge) data
        (pok, decodeIndex) = recoverPOK(attestation, decodeIndex);

        if (!attestationValid || !verifyPOK(id_commitment, ticket_commitment, pok)) {
            attestor = address(0);
            ticketIssuer = address(0);
            subject = address(0);
            ticketId = EMPTY_BYTES;
            conferenceId = EMPTY_BYTES;
            attestationValid = false;
        }
    }

    function verifyEqualityProof(
        bytes memory com1,
        bytes memory com2,
        bytes memory proof,
        bytes memory entropy
    ) internal view returns (bool result) {
        FullProofOfExponent memory pok;
        bytes memory attestationData;
        uint256 decodeIndex = 0;
        uint256 length = 0;

        (length, decodeIndex, ) = decodeLength(proof, 0);

        (, attestationData, decodeIndex, ) = decodeElement(proof, decodeIndex);
        pok.challenge = bytesToUint(attestationData);
        (, pok.tPoint, decodeIndex, ) = decodeElement(proof, decodeIndex);
        pok.entropy = entropy;

        return verifyPOK(com1, com2, pok);
    }

    //////////////////////////////////////////////////////////////
    // DER Structure Decoding
    //////////////////////////////////////////////////////////////

    function recoverTicketSignatureAddress(
        bytes memory attestation,
        uint256 hashIndex
    )
        internal
        pure
        returns (
            address signer,
            bytes memory ticketId,
            bytes memory conferenceId,
            bytes memory commitment2,
            uint256 resultIndex
        )
    {
        uint256 length;
        uint256 decodeIndex;
        bytes memory sigData;

        (, decodeIndex, ) = decodeLength(attestation, hashIndex); //163 Ticket Data

        (length, hashIndex, ) = decodeLength(attestation, decodeIndex); //5D

        bytes memory preHash = copyDataBlock(attestation, decodeIndex, (length + hashIndex) - decodeIndex); // ticket

        (, conferenceId, decodeIndex, ) = decodeElement(attestation, hashIndex); //CONFERENCE_ID
        (, ticketId, decodeIndex, ) = decodeElement(attestation, decodeIndex); //TICKET_ID
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //Ticket Class

        (, commitment2, decodeIndex, ) = decodeElement(attestation, decodeIndex + length); // Commitment 2, generated by Ticket constructor
        // in class Ticket

        (, sigData, resultIndex) = decodeElementOffset(attestation, decodeIndex, 1); // Signature

        //ecrecover
        signer = recoverSigner(preHash, sigData);
    }

    function getAttestationTimestamp(
        bytes memory attestation
    ) public pure returns (string memory startTime, string memory endTime) {
        uint256 decodeIndex = 0;
        uint256 length = 0;

        (, decodeIndex, ) = decodeLength(attestation, 0); //852 (total length, primary header)
        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //Ticket (should be 163)
        (startTime, endTime) = getAttestationTimestamp(attestation, decodeIndex + length);
    }

    function getAttestationTimestamp(
        bytes memory attestation,
        uint256 decodeIndex
    ) internal pure returns (string memory startTime, string memory endTime) {
        uint256 length = 0;
        bytes memory timeData;

        (, decodeIndex, ) = decodeLength(attestation, decodeIndex); //576  (SignedIdentifierAttestation)
        (, decodeIndex, ) = decodeLength(attestation, decodeIndex); //493  (IdentifierAttestation)

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex); //read Version

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Serial

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Signature type (9) 1.2.840.10045.2.1

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Issuer Sequence (14) [[2.5.4.3, ALX]]], (Issuer: CN=ALX)

        (length, decodeIndex, ) = decodeLength(attestation, decodeIndex + length); // Validity time

        (, timeData, decodeIndex, ) = decodeElement(attestation, decodeIndex);
        startTime = copyStringBlock(timeData);
        (, timeData, decodeIndex, ) = decodeElement(attestation, decodeIndex);
        endTime = copyStringBlock(timeData);
    }

    function mapTo256BitInteger(bytes memory input) internal pure returns (uint256 res) {
        bytes32 idHash = keccak256(input);
        res = uint256(idHash);
    }
}
