// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./VerifyAttestation.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/eip712/EIP712Verifier.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/EAS.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/SchemaRegistry.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract EASverify is VerifyAttestation {
    using ECDSA for bytes32;

    bytes32 constant EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // add some time gap to avoid problems with clock sync
    uint constant timeGap = 20;

    string constant name = "EAS Attestation";

    // EAS lib hardcoded schema, be carefull if you are going to change it
    bytes32 constant ATTEST_TYPEHASH =
        keccak256(
            "Attest(bytes32 schema,address recipient,uint64 time,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data)"
        );

    struct CustomAttestationRequestData {
        address recipient; // The recipient of the attestation.
        uint64 time; // The time when the attestation expires (Unix timestamp).
        uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
        bool revocable; // Whether the attestation is revocable.
        bytes32 refUID; // The UID of the related attestation.
        bytes data; // Custom attestation data.
        uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
        bytes32 schema;
    }

    struct EasTicketData {
        string conferenceId;
        string ticketIdString;
        uint8 ticketClass;
        bytes commitment;
    }

    struct DecodedDomainData {
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct RevokeData {
        bytes32 uid;
        uint64 time;
    }

    function hashTyped(
        CustomAttestationRequestData memory data,
        DecodedDomainData memory domainData
    ) public view returns (bytes32 hash) {
        if (domainData.chainId != block.chainid) {
            revert("Attestation for different chain");
        }

        hash = keccak256(
            abi.encodePacked(
                "\x19\x01", // backslash is needed to escape the character
                keccak256(
                    abi.encode(
                        EIP712_DOMAIN_TYPE_HASH,
                        keccak256(abi.encodePacked(name)),
                        keccak256(abi.encodePacked(domainData.version)),
                        domainData.chainId,
                        domainData.verifyingContract
                    )
                ),
                keccak256(
                    abi.encode(
                        ATTEST_TYPEHASH,
                        data.schema,
                        data.recipient,
                        data.time,
                        data.expirationTime,
                        data.revocable,
                        data.refUID,
                        keccak256(data.data)
                    )
                )
            )
        );
    }

    function recoverEasSigner(
        CustomAttestationRequestData memory data,
        bytes memory _signature,
        DecodedDomainData memory domainData
    ) public view returns (address) {
        // EIP721 domain type
        bytes32 hash = hashTyped(data, domainData);

        // split signature
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65) {
            return address(0);
        }
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            // verify
            return ecrecover(hash, v, r, s);
        }
    }

    function bytesToHex(
        bytes memory buffer
    ) public pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }

    function decodeEasTicketData(
        bytes memory attestation,
        uint256 hashIndex,
        bool testRevoked
    )
        internal
        view
        returns (
            address signer,
            EasTicketData memory ticket,
            uint256 resultIndex,
            RevokeData memory revoke,
            bool activeByTimestamp
        )
    {
        uint256 length;
        uint256 decodeIndex;
        bytes memory sigData;
        CustomAttestationRequestData memory payloadObjectData;

        // total ticket content start
        (, decodeIndex, ) = decodeLength(attestation, hashIndex); // Ticket Data

        // ticket payload dimensions
        (length, hashIndex, ) = decodeLength(attestation, decodeIndex); 

        // get only payload
        bytes memory contentBlock = copyDataBlock(
            attestation,
            hashIndex,
            length
        ); 

        // get signature data
        (, sigData, resultIndex) = decodeElementOffset(
            attestation,
            hashIndex + length,
            1
        );

        (
            payloadObjectData.schema,
            payloadObjectData.recipient,
            payloadObjectData.time,
            payloadObjectData.expirationTime,
            payloadObjectData.revocable,
            payloadObjectData.refUID,
            payloadObjectData.data
        ) = abi.decode(
            contentBlock,
            (bytes32, address, uint64, uint64, bool, bytes32, bytes)
        );

        // get Domain Data object position
        (length, hashIndex, ) = decodeLength(attestation, resultIndex); //5D

        // get only payload of Domain Data
        contentBlock = copyDataBlock(attestation, hashIndex, length); // ticket
        resultIndex = hashIndex + length;

        activeByTimestamp = validateTicketTimestamps(payloadObjectData);

        (
            ticket.conferenceId,
            ticket.ticketIdString,
            ticket.ticketClass,
            ticket.commitment
        ) = abi.decode(payloadObjectData.data, (string, string, uint8, bytes));

        DecodedDomainData memory domain;
        (domain.version, domain.verifyingContract, domain.chainId) = abi.decode(
            contentBlock,
            (string, address, uint256)
        );

        //ecrecover
        signer = recoverEasSigner(payloadObjectData, sigData, domain);

        if (testRevoked) {
            revoke = verifyEasRevoked(
                payloadObjectData,
                signer,
                domain.verifyingContract
            );
        }
    }

    function validateTicketTimestamps(
        CustomAttestationRequestData memory payloadObjectData
    ) internal view returns (bool){
        if (
            payloadObjectData.time > 0 &&
            payloadObjectData.time > (block.timestamp + timeGap)
        ) {
            // revert("Attestation not active yet");
            return false;
        }
        if (
            payloadObjectData.expirationTime > 0 &&
            payloadObjectData.expirationTime < block.timestamp
        ) {
            // revert("Attestation expired");
            return false;
        }
        return true;
    }

    function verifyEAS(
        bytes memory attestation,
        bool testRevoked
    )
        public
        view
        returns (
            address attestor,
            address ticketIssuer,
            address subject,
            EasTicketData memory ticket,
            bool attestationValid,
            RevokeData memory revoke,
            bool activeByTimestamp
        )
    {
        FullProofOfExponent memory pok;
        uint256 decodeIndex = 0;

        // Commitment to user identifier in Attestation
        bytes memory commitment1;
        // Commitment to user identifier in Ticket under var ticket.commitment

        // get full attestation content start
        (, decodeIndex, ) = decodeLength(attestation, 0); //852 (total length, primary header)

        (ticketIssuer, ticket, decodeIndex, revoke, activeByTimestamp) = decodeEasTicketData(
            attestation,
            decodeIndex,
            testRevoked
        );

        (
            attestor,
            subject,
            commitment1,
            decodeIndex,
            attestationValid
        ) = recoverSignedIdentifierAddress(attestation, decodeIndex);

        (pok, ) = recoverPOK(attestation, decodeIndex);

        if (attestationValid){ 
            // no need to check if revoke.time < currentTime because EAS revoke set current time when revoked
            if (revoke.time > 0 || !activeByTimestamp) {
                attestationValid = false;
            } else {
                attestationValid = verifyPOK(commitment1, ticket.commitment, pok);
            }
        }
    }

    function verifyEasRevoked(
        CustomAttestationRequestData memory payloadObjectData,
        address issuer,
        address verifyingContract
    ) internal view returns (RevokeData memory revoke) {
        uint32 nonce = 0;

        // generate Attestation UID
        bytes memory pack = abi.encodePacked(
            bytesToHex(abi.encodePacked(payloadObjectData.schema)),
            payloadObjectData.recipient,
            address(0),
            payloadObjectData.time,
            payloadObjectData.expirationTime,
            payloadObjectData.revocable,
            payloadObjectData.refUID,
            payloadObjectData.data,
            nonce
        );

        revoke.uid = keccak256(pack);
        IEAS eas = IEAS(verifyingContract);

        revoke.time = eas.getRevokeOffchain(issuer, revoke.uid);
    }
}