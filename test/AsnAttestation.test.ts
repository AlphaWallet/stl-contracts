const { ethers, upgrades } = require("hardhat");

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";

import { KeyPair } from "@tokenscript/attestation/dist/libs/KeyPair";
import { AttestationCrypto } from "@tokenscript/attestation/dist/libs/AttestationCrypto";
import { hexStringToUint8, hexStringToBase64, base64ToUint8array, uint8tohex } from "@tokenscript/attestation/dist/libs/utils";
import { SignedIdentifierAttestation } from "@tokenscript/attestation/dist/libs/SignedIdentifierAttestation";
import { IdentifierAttestation } from "@tokenscript/attestation/dist/libs/IdentifierAttestation";
import { Issuer } from "@tokenscript/attestation/dist/libs/Issuer";
import { Asn1Der } from "@tokenscript/attestation/dist/libs/DerUtility";

import { ProofOfExponentInterface } from "@tokenscript/attestation/dist/libs/ProofOfExponentInterface";
import { AttestedObject } from "@tokenscript/attestation/dist/libs/AttestedObject";
import { Ticket } from "@tokenscript/attestation/dist/Ticket";
import { ATTESTATION_TYPE } from "@tokenscript/attestation/dist/libs/interfaces";

let userKey = KeyPair.fromPrivateUint8(hexStringToUint8(AttestationCrypto.generateRandomHexString(32)), "secp256k1");
let attestorKey = KeyPair.fromPrivateUint8(hexStringToUint8(AttestationCrypto.generateRandomHexString(32)), "secp256k1");

const issuerPrivKey = KeyPair.privateFromPEM(
  "MIICSwIBADCB7AYHKoZIzj0CATCB4AIBATAsBgcqhkjOPQEBAiEA/////////////////////////////////////v///C8wRAQgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHBEEEeb5mfvncu6xVoGKVzocLBwKb/NstzijZWfKBWxb4F5hIOtp3JqPEZV2k+/wOEQio/Re0SKaFVBmcR9CP+xDUuAIhAP////////////////////66rtzmr0igO7/SXozQNkFBAgEBBIIBVTCCAVECAQEEIM/T+SzcXcdtcNIqo6ck0nJTYzKL5ywYBFNSpI7R8AuBoIHjMIHgAgEBMCwGByqGSM49AQECIQD////////////////////////////////////+///8LzBEBCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAcEQQR5vmZ++dy7rFWgYpXOhwsHApv82y3OKNlZ8oFbFvgXmEg62ncmo8RlXaT7/A4RCKj9F7RIpoVUGZxH0I/7ENS4AiEA/////////////////////rqu3OavSKA7v9JejNA2QUECAQGhRANCAARjMR62qoIK9pHk17MyHHIU42Ix+Vl6Q2gTmIF72vNpinBpyoBkTkV0pnI1jdrLlAjJC0I91DZWQhVhddMCK65c"
);

const issuerWalletEthers = new ethers.Wallet(issuerPrivKey.getPrivateAsHexString(), ethers.provider);

async function createAsnAttestation(email1 = "mail@mail", email2 = "mail@mail") {
  // MagicLink params

  let crypto = new AttestationCrypto();

  let devconID = "7";
  let ticketID = "33";
  let ticketClass = 1;
  let ticketSecret: bigint = crypto.makeSecret();
  let keys: any = {};
  keys[devconID] = issuerPrivKey;
  let ticket: Ticket = Ticket.createWithMail(email1, devconID, ticketID, ticketClass, keys, ticketSecret);

  let idSecret: bigint = crypto.makeSecret();
  let att: IdentifierAttestation = IdentifierAttestation.fromData(email2, ATTESTATION_TYPE.mail, userKey, idSecret);
  att.setSerialNumber(1);
  att.setIssuer("CN=attestation.id");
  let signedAtt = SignedIdentifierAttestation.fromData(att, attestorKey);

  let attCom: Uint8Array = att.getCommitment();
  let objCom: Uint8Array = ticket.getCommitment();
  let pok: ProofOfExponentInterface = crypto.computeEqualityProof(uint8tohex(attCom), uint8tohex(objCom), idSecret, ticketSecret);

  let preSignEncoded = ticket.getDerEncoding() + signedAtt.getDerEncoding() + pok.getDerEncoding();

  let unSigned = Asn1Der.encode("SEQUENCE_30", preSignEncoded);
  return "0x" + unSigned;
}

describe("ASN Attestation", function () {
  let verifyAttestation: Contract;

  it("deploy contract", async function () {
    const VerifyAttestation = await ethers.getContractFactory("VerifyAttestation");
    verifyAttestation = await VerifyAttestation.deploy();
    await verifyAttestation.deployed();
  });

  it("Validate Attestation", async function () {
    let att = await createAsnAttestation();
    let verifyRes = await verifyAttestation["verifyTicketAttestation(bytes)"](att);
    expect(verifyRes.attestationValid).true;
  });

  it("Wrong Proof", async function () {
    let att = await createAsnAttestation("1", "2");
    let verifyRes = await verifyAttestation["verifyTicketAttestation(bytes)"](att);
    expect(verifyRes.attestationValid).false;

  });
});
