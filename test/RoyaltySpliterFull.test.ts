const { ethers } = require("hardhat");

import { expect } from "chai";

describe("Derived Contracts Test", function () {
  async function setup() {
    const [owner, user, user2, user3, user4] = await ethers.getSigners();

    const RoyaltySpliterFull = (
      await ethers.getContractFactory("RoyaltySpliterFull")
    ).connect(owner);
    let contract = await RoyaltySpliterFull.connect(owner).deploy();
    await contract.deployed();

    return { owner, user, user2, user3, user4, contract };
  }

  it("split mint", async function () {
    const { contract, user, user2, user3, owner } = await setup();

    let initUserBalance2 = await ethers.provider.getBalance(user2.address);
    let initUserBalance3 = await ethers.provider.getBalance(user3.address);

    let user2Rate = 20;
    let user3Rate = 80;

    await owner.sendTransaction({
      to: contract.address,
      value: ethers.utils.parseEther("3.0"),
    });

    let initContractBalance = await ethers.provider.getBalance(
      contract.address
    );

    await expect(contract.withdrawETH()).to.revertedWith("No receivers");

    await expect(
      contract.updateRecievers([
        [user2.address, 5000],
        [user3.address, 5001],
      ])
    ).to.revertedWith("Total revenue must be 10000");

    await contract.updateRecievers([
      [user2.address, user2Rate * 100],
      [user3.address, user3Rate * 100],
    ]);

    await expect(contract.withdrawETH()).to.emit(contract, "RoyaltyPaid");

    let resultUserBalance2 = await ethers.provider.getBalance(user2.address);
    let resultUserBalance3 = await ethers.provider.getBalance(user3.address);
    let resultContractBalance = await ethers.provider.getBalance(
      contract.address
    );

    expect(resultUserBalance2.sub(initUserBalance2)).to.eq(
      initContractBalance.mul(user2Rate).div(100)
    );
    expect(resultUserBalance3.sub(initUserBalance3)).to.eq(
      initContractBalance.mul(user3Rate).div(100)
    );

    expect(resultContractBalance).to.eq(0);
  });

  it("split mint ERC20", async function () {
    const { contract, user, user2, user3, owner } = await setup();

    const ExampleERC20 = (
      await ethers.getContractFactory("ExampleERC20")
    ).connect(owner);

    let erc20_1 = await ExampleERC20.connect(owner).deploy("N", "S");
    await erc20_1.deployed();

    let erc20_2 = await ExampleERC20.deploy("N", "S");
    await erc20_2.deployed();

    const erc20_1_amount = 100 * 1000;
    const erc20_2_amount = 200 * 1000;
    await erc20_1.connect(owner).mint(contract.address, erc20_1_amount);
    await erc20_2.connect(owner).mint(contract.address, erc20_2_amount);

    let user1Rate = 20;
    let user2Rate = 80;
    await expect(
      contract.connect(owner).updateRecievers([
        [user2.address, user1Rate * 100],
        [user3.address, user2Rate * 100],
      ])
    ).to.not.reverted;

    await expect(
      contract.withdrawERC20([erc20_1.address, erc20_2.address])
    ).to.emit(contract, "RoyaltyPaidERC20");

    expect(await erc20_1.balanceOf(user2.address)).to.eq(
      (erc20_1_amount / 100) * user1Rate
    );
    expect(await erc20_1.balanceOf(user3.address)).to.eq(
      (erc20_1_amount / 100) * user2Rate
    );

    expect(await erc20_2.balanceOf(user2.address)).to.eq(
      (erc20_2_amount / 100) * user1Rate
    );
    expect(await erc20_2.balanceOf(user3.address)).to.eq(
      (erc20_2_amount / 100) * user2Rate
    );
  });
});
