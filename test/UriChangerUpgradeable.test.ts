const { waffle, ethers, upgrades } = require("hardhat");
const {
	provider,
	deployContract,
	solidity,
	link,
	deployMockContract,
	createFixtureLoader,
	loadFixture,
} = waffle;

import { expect } from "chai";

describe("UriChangerUpgradeable", () => {
	async function setup() {
		const [owner, user, user2] = await provider.getWallets();

		const ExampleUriChangerFactory = (
			await ethers.getContractFactory("ExampleUriChangerUpgradeable")
		).connect(owner);

		let contract = await upgrades.deployProxy(ExampleUriChangerFactory, [], {
			kind: "uups",
		});
		await contract.deployed();

		return { owner, user, user2, contract };
	}

	it("modifier", async () => {
		const { contract, user, owner } = await setup();
		expect(await contract.getValue()).to.be.equal(1);
		await expect(contract.connect(user).setValue(2)).to.revertedWith(
			"UriChanger: caller is not allowed"
		);

		await expect(contract.connect(owner).setValue(3)).to.not.reverted;

		expect(await contract.getValue()).to.eq(3);
	});

	it("updateUriChanger", async () => {
		const { contract, user, user2, owner } = await setup();
		expect(await contract.getValue()).to.be.equal(1);
		await expect(
			contract.connect(user).updateUriChanger(user2.address)
		).to.revertedWith("Ownable: caller is not the owner");

		await expect(
			contract.connect(owner).updateUriChanger(ethers.constants.AddressZero)
		).to.revertedWith("UriChanger: Address required");

		await expect(
			contract.connect(owner).updateUriChanger(user.address)
		).to.emit(contract, "UriChangerUpdated");

		await expect(contract.connect(owner).setValue(2)).to.revertedWith(
			"UriChanger: caller is not allowed"
		);

		await expect(contract.connect(user).setValue(4)).to.not.reverted;

		expect(await contract.getValue()).to.eq(4);
	});
});
