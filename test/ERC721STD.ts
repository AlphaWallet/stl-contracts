import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress, parseGwei } from "viem";

describe("ERC721STD", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const erc721 = await hre.viem.deployContract("ERC721STD", ["name", "symbol"]);

    const publicClient = await hre.viem.getPublicClient();

    return {
      erc721,
      owner,
      otherAccount,
      publicClient,
    };
  }

  describe("Mint", function () {
    it("Mint succesful", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      let hash = await erc721.write.mint([otherAccount.account.address, ""]);
      await publicClient.waitForTransactionReceipt({ hash });        
      const withdrawalEvents = await erc721.getEvents.Transfer()
      expect(withdrawalEvents).to.have.lengthOf(1);
    });

    it("Mint: reject unauthorized ", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      await expect(otherAccount.writeContract({
        address: erc721.address,
        abi: erc721.abi,
        functionName: 'mint',
        args: [otherAccount.account.address, ""],
      })).to.be.rejectedWith("AccessControlUnauthorizedAccount")

    });

    it("Mint: mint by owner ", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      let hash = await owner.writeContract({
        address: erc721.address,
        abi: erc721.abi,
        functionName: 'mint',
        args: [owner.account.address, ""],
      })
      await publicClient.waitForTransactionReceipt({ hash });  

    });

    it("Royalty data", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      let hash = await erc721.write.mint([otherAccount.account.address, ""]);
      await publicClient.waitForTransactionReceipt({ hash });    
      
      expect(await erc721.read.royaltyInfo([0n, 100n])).to.deep.eq([getAddress(owner.account.address), 5n])
      hash = await erc721.write.setRoyaltyData([otherAccount.account.address, 22n*100n]);
      await publicClient.waitForTransactionReceipt({ hash });    
      
      expect(await erc721.read.royaltyInfo([0n, 100n])).to.deep.eq([getAddress(otherAccount.account.address), 22n])
    });

    it("Burn", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      let hash = await erc721.write.mint([otherAccount.account.address, ""]);
      await publicClient.waitForTransactionReceipt({ hash });    

      expect (await erc721.read.totalSupply()).to.eq( 1n )

      hash = await otherAccount.writeContract({
        address: erc721.address,
        abi: erc721.abi,
        functionName: 'burn',
        args: [0n],
      })
      await publicClient.waitForTransactionReceipt({ hash }); 

      expect (await erc721.read.totalSupply()).to.eq( 0n )

    });

    it("ERC5169", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      let hash = await erc721.write.setScriptURI([["1","2"]]);
      await publicClient.waitForTransactionReceipt({ hash });    

      expect (await erc721.read.scriptURI()).to.deep.eq( ["1","2"] )

      await expect(otherAccount.writeContract({
        address: erc721.address,
        abi: erc721.abi,
        functionName: 'setScriptURI',
        args: [["2","2"]],
      })).to.rejectedWith("AccessControlUnauthorizedAccount")
      
    });

    it("support interface", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);
      expect(await erc721.read.supportsInterface(["0x2a55205a"])).to.eq(true);
			expect(await erc721.read.supportsInterface(["0x2a55205b"])).to.eq(false);
      const ERC5169InterfaceId = "0xa86517a1";
      expect(await erc721.read.supportsInterface([ERC5169InterfaceId])).to.eq(true);
      const IAccessControlEnumerable = "0x5a05180f"
      expect(await erc721.read.supportsInterface([IAccessControlEnumerable])).to.eq(true);
      const IAccessControl = "0x7965db0b"
      expect(await erc721.read.supportsInterface([IAccessControl])).to.eq(true);
      const IERC721URIStorage = "0x49064906"
      expect(await erc721.read.supportsInterface([IERC721URIStorage])).to.eq(true);
      const IERC721Enumerable = "0x780e9d63"
      expect(await erc721.read.supportsInterface([IERC721Enumerable])).to.eq(true);
      const IERC721 = "0x80ac58cd"
      expect(await erc721.read.supportsInterface([IERC721])).to.eq(true);

    });

    it("owner", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      expect((await erc721.read.owner()).toLowerCase()).to.eq(owner.account.address)
    });

    it("setTokenURI", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      let hash = await erc721.write.mint([otherAccount.account.address, "123.json"]);
      await publicClient.waitForTransactionReceipt({ hash });

      expect((await erc721.read.tokenURI([0n]))).to.eq("123.json")

      hash = await erc721.write.mint([otherAccount.account.address, "234.json"]);
      await publicClient.waitForTransactionReceipt({ hash });
      hash = await erc721.write.setTokenURI([1n, "234.json"]);
      hash = await erc721.write.setTokenURI([0n, "345.json"]);

      expect((await erc721.read.tokenURI([0n]))).to.eq("345.json")
      expect((await erc721.read.tokenURI([1n]))).to.eq("234.json")

      await expect(otherAccount.writeContract({
        address: erc721.address,
        abi: erc721.abi,
        functionName: 'setTokenURI',
        args: [1n, "any.json"],
      })).to.rejectedWith("AccessControlUnauthorizedAccount")

    });
    
    it("setBaseURI", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      let hash = await erc721.write.mint([otherAccount.account.address, "123.json"]);
      hash = await erc721.write.mint([otherAccount.account.address, "234.json"]);

      await publicClient.waitForTransactionReceipt({ hash });
      hash = await erc721.write.setBaseURI(["hosting.root/"]);

      await expect(otherAccount.writeContract({
        address: erc721.address,
        abi: erc721.abi,
        functionName: 'setBaseURI',
        args: ["any"],
      })).to.rejectedWith("AccessControlUnauthorizedAccount")

      expect((await erc721.read.tokenURI([0n]))).to.eq("hosting.root/123.json")
      expect((await erc721.read.tokenURI([1n]))).to.eq("hosting.root/234.json")
      
    });

    

    it("setContractURI", async function () {
      const { erc721, owner, otherAccount, publicClient } = await loadFixture(deployFixture);

      expect((await erc721.read.contractURI())).to.eq("")
      
      let hash = await erc721.write.setContractURI(["some.json"]);
      
      expect((await erc721.read.contractURI())).to.eq("some.json")

      await expect(otherAccount.writeContract({
        address: erc721.address,
        abi: erc721.abi,
        functionName: 'setContractURI',
        args: ["any"],
      })).to.rejectedWith("AccessControlUnauthorizedAccount")
    });

  });

});

