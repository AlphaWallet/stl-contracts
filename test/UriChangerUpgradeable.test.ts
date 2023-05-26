const {waffle, ethers, upgrades} = require('hardhat');
const {provider} = waffle;

/* eslint-disable */
import {solidity} from 'ethereum-waffle';
/* eslint-enable */
import {expect} from 'chai';

describe('UriChangerUpgradeable', () => {
  async function setup() {
    const [owner, user, user2] = await provider.getWallets();

    const ExampleUriChangerFactory = (
      await ethers.getContractFactory('ExampleUriChangerUpgradeable')
    ).connect(owner);

    const contract = await upgrades.deployProxy(ExampleUriChangerFactory, [], {
      kind: 'uups',
    });
    await contract.deployed();

    return {owner, user, user2, contract};
  }

  it('modifier', async () => {
    const {contract, user, owner} = await setup();
    expect(await contract.getValue()).to.be.equal(1);
    await expect(contract.connect(user).setValue(2)).to.be.rejectedWith(
      'UriChanger: caller is not allowed'
    );

    await expect(contract.connect(owner).setValue(3)).to.not.rejected;

    expect(await contract.getValue()).to.eq(3);
  });

  it('updateUriChanger', async () => {
    const {contract, user, user2, owner} = await setup();
    expect(await contract.getValue()).to.be.equal(1);
    await expect(
      contract.connect(user).updateUriChanger(user2.address)
    ).to.rejectedWith('Ownable: caller is not the owner');

    await expect(
      contract.connect(owner).updateUriChanger(ethers.constants.AddressZero)
    ).to.rejectedWith('UriChanger: Address required');

    await expect(
      contract.connect(owner).updateUriChanger(user.address)
    ).to.emit(contract, 'UriChangerUpdated');

    await expect(contract.connect(owner).setValue(2)).to.rejectedWith(
      'UriChanger: caller is not allowed'
    );

    await expect(contract.connect(user).setValue(4)).to.not.rejected;

    expect(await contract.getValue()).to.eq(4);
  });
});
