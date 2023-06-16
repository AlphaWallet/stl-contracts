const { ethers } = require("hardhat");
// import { loadFixture } from 'ethereum-waffle';

import { expect, use } from "chai";
import { BigNumber, Contract } from "ethers";
import { KeyPair } from "@tokenscript/attestation/dist/libs/KeyPair";
import { AttestationCrypto } from "@tokenscript/attestation/dist/libs/AttestationCrypto";
import {
	hexStringToUint8,
	hexStringToBase64,
	base64ToUint8array,
	uint8tohex,
} from "@tokenscript/attestation/dist/libs/utils";
import { SignedIdentifierAttestation } from "@tokenscript/attestation/dist/libs/SignedIdentifierAttestation";
import { IdentifierAttestation } from "@tokenscript/attestation/dist/libs/IdentifierAttestation";
import { ATTESTATION_TYPE } from "@tokenscript/attestation/dist/libs/interfaces";

import { EasTicketAttestation } from "@tokenscript/attestation/dist/eas/EasTicketAttestation";
import { EasZkProof } from "@tokenscript/attestation/dist/eas/EasZkProof";

let tx: any;

let easVerify: Contract, eas: Contract;

const email = "some@email";
const SEPOLIA_RPC = "https://rpc.sepolia.org/";

const EAS_CONFIG = {
	// name: 'EAS Attestation',
	address: "0xC2679fBD37d54388Ce493F1DB75320D236e1815e",
	version: "0.26",
	chainId: 11155111,
};

const EAS_TICKET_SCHEMA = {
	fields: [
		{ name: "devconId", type: "string" },
		{ name: "ticketIdString", type: "string" },
		{ name: "ticketClass", type: "uint8" },
		{ name: "commitment", type: "bytes", isCommitment: true },
	],
};

let userKey = KeyPair.fromPrivateUint8(
	hexStringToUint8(AttestationCrypto.generateRandomHexString(32)),
	"secp256k1"
);
let attestorKey = KeyPair.fromPrivateUint8(
	hexStringToUint8(AttestationCrypto.generateRandomHexString(32)),
	"secp256k1"
);

const issuerPrivKey = KeyPair.privateFromPEM(
	"MIICSwIBADCB7AYHKoZIzj0CATCB4AIBATAsBgcqhkjOPQEBAiEA/////////////////////////////////////v///C8wRAQgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHBEEEeb5mfvncu6xVoGKVzocLBwKb/NstzijZWfKBWxb4F5hIOtp3JqPEZV2k+/wOEQio/Re0SKaFVBmcR9CP+xDUuAIhAP////////////////////66rtzmr0igO7/SXozQNkFBAgEBBIIBVTCCAVECAQEEIM/T+SzcXcdtcNIqo6ck0nJTYzKL5ywYBFNSpI7R8AuBoIHjMIHgAgEBMCwGByqGSM49AQECIQD////////////////////////////////////+///8LzBEBCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAcEQQR5vmZ++dy7rFWgYpXOhwsHApv82y3OKNlZ8oFbFvgXmEg62ncmo8RlXaT7/A4RCKj9F7RIpoVUGZxH0I/7ENS4AiEA/////////////////////rqu3OavSKA7v9JejNA2QUECAQGhRANCAARjMR62qoIK9pHk17MyHHIU42Ix+Vl6Q2gTmIF72vNpinBpyoBkTkV0pnI1jdrLlAjJC0I91DZWQhVhddMCK65c"
);

const providerSepolia = new ethers.providers.JsonRpcProvider(SEPOLIA_RPC);
const wallet = new ethers.Wallet(
	issuerPrivKey.getPrivateAsHexString(),
	providerSepolia
);
const issuerWalletTestnet = new ethers.Wallet(
	issuerPrivKey.getPrivateAsHexString(),
	ethers.provider
);

// will be replaced in tests
let attestationManager = new EasTicketAttestation(
	EAS_TICKET_SCHEMA,
	{
		EASconfig:EAS_CONFIG,
		signer:wallet
	}
);
const pubKeyConfig = { "6": issuerPrivKey };

const ticketRequestData = {
	devconId: "6",
	ticketIdString: "12345",
	ticketClass: 2,
	commitment: email,
};

function getIdAttest(email: string, idSecret: bigint) {
	let att: IdentifierAttestation = IdentifierAttestation.fromData(
		email,
		ATTESTATION_TYPE.mail,
		userKey,
		idSecret
	);
	att.setSerialNumber(1);
	att.setIssuer("CN=attestation.id");
	expect(att.checkValidity()).equal(true);
	return hexStringToBase64(
		SignedIdentifierAttestation.fromData(att, attestorKey).getDerEncoding()
	);
}

async function createEasAttestation(
	validity?: { from: number; to: number },
	request = ticketRequestData,
	config = EAS_CONFIG,
	issuerWallet = wallet
) {
	let localAttestationManager = new EasTicketAttestation(
		EAS_TICKET_SCHEMA,
		{
			EASconfig:config,
			signer: issuerWallet
		}
	);

	let attestJson = await localAttestationManager.createEasAttestation(request, {
		validity,
	});

	// const easZkProof = new EasZkProof(EAS_TICKET_SCHEMA, config, issuerWallet);
	const easZkProof = new EasZkProof(EAS_TICKET_SCHEMA, {
		'31337': eas.address
	});
	// Generate identifier attestation
	const idSecret = new AttestationCrypto().makeSecret();

	// Create ZKProof attestation
	let base64UseTicketAttestation = easZkProof.getUseTicket(
		BigInt(<string>localAttestationManager.getEasJson().secret),
		BigInt(idSecret),
		localAttestationManager.getEncoded(),
		getIdAttest(email, idSecret),
		hexStringToBase64(attestorKey.getAsnDerPublic()),
		pubKeyConfig
	);

	let hexUseTicket =
		"0x" + uint8tohex(base64ToUint8array(base64UseTicketAttestation));

	// dont verify, because schema for local chain
	// await easZkProof.validateUseTicket(base64UseTicketAttestation, attestationIdPublic, pubKeyConfig, userKey.getAddress());

	return {
		attestJson,
		hexUseTicket,
	};
}

describe("EAS verify", function () {
	const ganacheChainId = 31337;
	let localEasConfig: any;

	it("Init", async function () {
		const [_addr1, _addr2, _addr3, _addr4, _addr5, _addr6] =
			await ethers.getSigners();

		const SchemaRegistry = await ethers.getContractFactory("SchemaRegistry");
		let schemaRegistry = await SchemaRegistry.connect(_addr1).deploy();
		await schemaRegistry.deployed();

		const EAS = await ethers.getContractFactory("EAS");
		eas = await EAS.connect(_addr1).deploy(schemaRegistry.address);
		await eas.deployed();

		const EASverify = await ethers.getContractFactory("EASverify");
		easVerify = await EASverify.connect(_addr1).deploy();
		await easVerify.deployed();

		let tx = await _addr1.sendTransaction({
			to: issuerWalletTestnet.address,
			value: ethers.utils.parseEther("1.0"),
		});
		await tx.wait();

		localEasConfig = Object.assign({}, EAS_CONFIG);
		localEasConfig.chainId = 31337;
		localEasConfig.address = eas.address;
	});

	it("validate attestation, test revoked", async function () {
		// hardhat local data
		let attest = await createEasAttestation(
			undefined,
			undefined,
			localEasConfig
		);

		let attestResponce = await easVerify.verifyEAS(attest.hexUseTicket, true);

		// default responce data
		expect(attestResponce.ticketIssuer).to.equal(issuerWalletTestnet.address);
		expect(attestResponce.ticket.conferenceId).to.equal(
			ticketRequestData.devconId
		);
		expect(attestResponce.ticket.ticketIdString).to.equal(
			ticketRequestData.ticketIdString
		);
		expect(attestResponce.ticket.ticketClass).to.equal(
			ticketRequestData.ticketClass
		);
		expect(attestResponce.attestationValid).to.equal(true);
		expect(attestResponce.revoke.time).to.equal(0);
		expect(attestResponce.revoke.uid).to.equal(attest.attestJson.sig.uid);
		expect(attestResponce.activeByTimestamp).to.equal(true);
	});

	it("revoked", async function () {

		let attest = await createEasAttestation(
			undefined,
			undefined,
			localEasConfig
		);

		let tx = await eas
			.connect(issuerWalletTestnet)
			.revokeOffchain(attest.attestJson.sig.uid);
		await tx.wait();

		let attestResponce = await easVerify.verifyEAS(attest.hexUseTicket, true);

		expect(attestResponce.attestationValid).false;
		expect(attestResponce.revoke.time > 0).true;
	});

    it("timestamp not active jet", async function () {

		let attest = await createEasAttestation(
			{from: Math.round(Date.now()/1000) + 1000, to: 0},
			undefined,
			localEasConfig
		);

		let attestResponce = await easVerify.verifyEAS(attest.hexUseTicket, false);

		expect(attestResponce.attestationValid).false;
		expect(attestResponce.activeByTimestamp).false;
	});

    it("timestamp expired", async function () {

		let attest = await createEasAttestation(
			{to: Math.round(Date.now()/1000) - 1000, from: 0},
			undefined,
			localEasConfig
		);

		let attestResponce = await easVerify.verifyEAS(attest.hexUseTicket, false);

		expect(attestResponce.attestationValid).false;
		expect(attestResponce.activeByTimestamp).false;
	});

	it("wrong chainId", async function () {

        localEasConfig = Object.assign({}, EAS_CONFIG);
		localEasConfig.chainId = 3133711;
		localEasConfig.address = eas.address;

		let attest = await createEasAttestation(
			undefined,
			undefined,
			localEasConfig
		);

		await expect(easVerify.verifyEAS(attest.hexUseTicket, true)).to.revertedWith("Attestation for different chain")
	});
});
