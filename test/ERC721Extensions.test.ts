const { ethers, waffle } = require("hardhat");
import { expect } from "chai";

const SampleERC721Json = require("../artifacts/contracts/package/tokens/OptimizedEnumerable.sol/OptimizedEnumerable.json");

describe("ERC20 extensions", function () {
	async function setup() {
		const [owner, user, user2, user3, user4] = await ethers.getSigners();

		const ExampleERC721 = await ethers.getContractFactory("ExampleERC721");
		let contract = await ExampleERC721.connect(owner).deploy("", "");
		await contract.deployed();

		return { owner, user, user2, user3, user4, contract };
	}

	it("Minter", async function () {
		const { contract, user, user2, user3, owner } = await setup();

		await owner.sendTransaction({
			to: user2.address,
			value: ethers.utils.parseEther("3.0"),
		});

		await expect(contract.connect(owner).mint(user2.address)).to.emit(
			contract,
			"Transfer"
		);
		expect(await contract.ownerOf(0)).to.eq(user2.address);
		expect(await contract.getMinter(0)).to.eq(user2.address);

		await contract.connect(user2).transferFrom(user2.address, user3.address, 0);
		expect(await contract.getMinter(0)).to.eq(user2.address);
	});

	it("ParentContracts", async function () {
		const { contract, user, user2, user3, owner } = await setup();

		const mockERC721 = await waffle.deployMockContract(
			owner,
			SampleERC721Json.abi
		);
		await mockERC721.mock.supportsInterface.returns(false);
		await expect(
			contract.connect(owner).addParent(mockERC721.address)
		).to.revertedWith("Must be ERC721 contract");
		await expect(
			contract.connect(user2).addParent(mockERC721.address)
		).to.revertedWith("Ownable: caller is not the owner");

		await mockERC721.mock.supportsInterface.returns(true);
		await expect(contract.connect(owner).addParent(mockERC721.address)).to.emit(
			contract,
			"ParentAdded"
		);

		expect(await contract.getParents()).to.eql([mockERC721.address]);
	});

	it("Enumerable", async function () {
		const { contract, user, user2, user3, owner } = await setup();

		await expect(contract.connect(owner).mint(user2.address)).to.emit(
			contract,
			"Transfer"
		);

		expect(await contract.balanceOf(user2.address)).to.eq(1);
		expect(await contract.totalSupply()).to.eq(1);
		expect(await contract.tokenByIndex(0)).to.eq(0);
		expect(await contract.tokenOfOwnerByIndex(user2.address, 0)).to.eq(0);
	});

	it("Enumerable + Burn", async function () {
		const { contract, user, user2, user3, owner } = await setup();

		await expect(contract.connect(owner).mint(user2.address)).to.emit(
			contract,
			"Transfer"
		);
		await expect(contract.connect(owner).mint(user2.address)).to.emit(
			contract,
			"Transfer"
		);
		await expect(contract.connect(owner).mint(user3.address)).to.emit(
			contract,
			"Transfer"
		);
		await expect(contract.connect(owner).mint(user2.address)).to.emit(
			contract,
			"Transfer"
		);
		await expect(contract.connect(user2).burn(1)).to.emit(contract, "Transfer");

		expect(await contract.balanceOf(user2.address)).to.eq(2);
		expect(await contract.totalSupply()).to.eq(3);
		expect(await contract.tokenByIndex(1)).to.eq(2);
		expect(await contract.tokenOfOwnerByIndex(user2.address, 1)).to.eq(3);
	});

	it("ERC721 supportInterface", async function () {
		const { contract, user, user2, user3, owner } = await setup();

		const ERC721InterfaceId = "0x80ac58cd";
		expect(await contract.supportsInterface(ERC721InterfaceId)).to.eq(true);
	});

	it("SharedHolders", async function () {
		const { contract, user, user2, user3, owner } = await setup();

		await expect(contract.connect(owner).mint(user3.address)).to.emit(
			contract,
			"Transfer"
		);

		expect(await contract.isSharedHolderTokenOwner(contract.address, 0)).to.eq(
			false
		);

		await expect(
			contract.connect(owner).setSharedTokenHolders([user2.address])
		).to.emit(contract, "SharedTokenHoldersUpdated");

		expect(await contract.isSharedHolderTokenOwner(contract.address, 0)).to.eq(
			false
		);

		await expect(
			contract
				.connect(owner)
				.setSharedTokenHolders([user2.address, user3.address])
		).to.emit(contract, "SharedTokenHoldersUpdated");

		expect(await contract.isSharedHolderTokenOwner(contract.address, 0)).to.eq(
			true
		);
	});
});
