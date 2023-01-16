const { waffle, ethers } = require("hardhat");
const { provider, deployContract, solidity, link, deployMockContract, createFixtureLoader, loadFixture } = waffle;

const { expect } = require("chai");

describe("ERC5169", () => {
  async function setup() {
    const [owner, user, user2] = await provider.getWallets();

    const ExampleERC5169 = await ethers.getContractFactory("ExampleERC5169");
    const contract = await ExampleERC5169.connect(owner).deploy();
    return { owner, user, user2, contract };
  }

  it("setScriptURI", async () => {
    const { contract, user, user2, owner } = await setup();

    expect(await contract.scriptURI()).to.eql([]);

    await expect(contract.connect(user).setScriptURI([])).to.revertedWith("Ownable: caller is not the owner");

    const scriptURI = ["uri1", "uri2", "uri3"];

    await expect(contract.connect(owner).setScriptURI(scriptURI)).to.emit(contract, "ScriptUpdate").withArgs(scriptURI);

    expect(await contract.scriptURI()).to.eql(scriptURI);
  });

  it("supportsInterface", async function () {
    const { contract } = await setup();

    const ERC5169InterfaceId = "0xa86517a1";

    expect(await contract.supportsInterface(ERC5169InterfaceId)).to.eq(true);
  });
});
