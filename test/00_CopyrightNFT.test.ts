import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, waffle } from 'hardhat';
import chai from 'chai';
import { Contract } from 'ethers';

chai.use(waffle.solidity);
const { expect } = chai;

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const NFT_NAME = 'Music NFT';
const NFT_SYMBOL = 'MNFT';

describe('CopyrightNFT', () => {
  let copyrightNFT: Contract;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async () => {
    [owner, minter, user1, user2] = await ethers.getSigners();
    const CopyrightNFT = await ethers.getContractFactory('CopyrightNFT');
    copyrightNFT = await CopyrightNFT.deploy(NFT_NAME, NFT_SYMBOL);
    await copyrightNFT.deployed();
  });

  /**
   * Deployment
   */
  describe('Deployment', () => {
    it('CopyrightNFT contract deployed successfully', async () => {
      expect(copyrightNFT.address).to.not.be.undefined;
    });

    it('Check name and symbol', async () => {
      expect(await copyrightNFT.name()).to.be.equal(NFT_NAME);
      expect(await copyrightNFT.symbol()).to.be.equal(NFT_SYMBOL);
    });
  });

  /**
   * Ownership
   */
  describe('Ownership', () => {
    it('Check owner', async () => {
      expect(await copyrightNFT.owner()).to.be.equal(owner.address);
    });

    it("Non owner can't transfer ownership", async () => {
      await expect(
        copyrightNFT.connect(minter).transferOwnership(minter.address)
      ).to.be.reverted;
    });

    it('Owner can transfer ownership', async () => {
      expect(await copyrightNFT.owner()).to.be.equal(owner.address);
      await copyrightNFT.connect(owner).transferOwnership(minter.address);
      expect(await copyrightNFT.owner()).to.be.equal(minter.address);
    });
  });

  /**
   * Minter
   */
  describe('Minter', () => {
    it('Minter is ZERO ADDRESS befor we have set it', async () => {
      expect(await copyrightNFT.minter()).to.be.equal(ZERO_ADDRESS);
    });

    it("Non owner can't set minter", async () => {
      await expect(copyrightNFT.connect(minter).setMinter(minter.address)).to.be
        .reverted;
    });

    it('Owner can set minter', async () => {
      expect(await copyrightNFT.minter()).to.be.equal(ZERO_ADDRESS);
      await copyrightNFT.connect(owner).setMinter(minter.address);
      expect(await copyrightNFT.minter()).to.be.equal(minter.address);
    });
  });

  /**
   * Mint
   */
  describe('Mint', () => {
    beforeEach(async () => {
      await copyrightNFT.connect(owner).setMinter(minter.address);
    });

    it("Non minter can't mint", async () => {
      await expect(copyrightNFT.connect(user1).mint(user1.address)).to.be
        .reverted;
    });

    it('Minter can mint', async () => {
      // before minting, we have a balance of 0
      expect(await copyrightNFT.balanceOf(user1.address)).to.be.equal(0);
      // mint
      await copyrightNFT.connect(minter).mint(user1.address);
      // after minting, we have a balance of 1
      expect(await copyrightNFT.balanceOf(user1.address)).to.be.equal(1);
      expect(await copyrightNFT.ownerOf(1)).to.be.equal(user1.address);
    });
  });

  /**
   * Approval for all
   */
  describe('Approval for all', () => {
    it("You can't approve the owner", async () => {
      await expect(
        copyrightNFT.connect(user1).setApprovalForAll(user1.address, true)
      ).to.be.reverted;
    });

    it('Approve for all another user', async () => {
      // before approving, user2 is not approved for all user1
      expect(
        await copyrightNFT.isApprovedForAll(user1.address, user2.address)
      ).to.be.equal(false);
      // approve for all user2
      await copyrightNFT.connect(user1).setApprovalForAll(user2.address, true);
      // after approving, user2 is approved for all user1
      expect(
        await copyrightNFT.isApprovedForAll(user1.address, user2.address)
      ).to.be.equal(true);
    });
  });

  /**
   * Approve
   */
  describe('Approve', () => {
    beforeEach(async () => {
      await copyrightNFT.connect(owner).setMinter(minter.address);
      await copyrightNFT.connect(minter).mint(user1.address);
    });

    it("You can't approve the owner", async () => {
      await expect(copyrightNFT.connect(user1).approve(user1.address, 1)).to.be
        .reverted;
    });

    it("You can't approve if you aren't owner nor approved for all", async () => {
      await expect(copyrightNFT.connect(minter).approve(user1.address, 1)).to.be
        .reverted;
    });

    it('Approve another user', async () => {
      // before approving, user2 is not approved for token 1
      expect(await copyrightNFT.getApproved(1)).to.be.equal(ZERO_ADDRESS);
      // approve for all user2
      await copyrightNFT.connect(user1).approve(user2.address, 1);
      // after approving, user2 is approved for token 1
      expect(await copyrightNFT.getApproved(1)).to.be.equal(user2.address);
    });
  });

  /**
   * Transfer
   */
  describe('Transfer', () => {
    beforeEach(async () => {
      await copyrightNFT.connect(owner).setMinter(minter.address);
      await copyrightNFT.connect(minter).mint(user1.address);
    });

    it("You can't transfer if you aren't the owner nor approved", async () => {
      await expect(
        copyrightNFT
          .connect(minter)
          .transferFrom(user1.address, user2.address, 1)
      ).to.be.reverted;
      await expect(
        copyrightNFT
          .connect(minter)
          ['safeTransferFrom(address,address,uint256)'](
            user1.address,
            user2.address,
            1
          )
      ).to.be.reverted;
    });

    it('Transfer a token', async () => {
      // before transfer, we have a balance of 0
      expect(await copyrightNFT.balanceOf(user2.address)).to.be.equal(0);
      // transfer
      await copyrightNFT
        .connect(user1)
        .transferFrom(user1.address, user2.address, 1);
      // after transfer, we have a balance of 1
      expect(await copyrightNFT.balanceOf(user2.address)).to.be.equal(1);
      expect(await copyrightNFT.ownerOf(1)).to.be.equal(user2.address);
    });

    it('Safe transfer a token', async () => {
      // before transfer, we have a balance of 0
      expect(await copyrightNFT.balanceOf(user2.address)).to.be.equal(0);
      // transfer
      await copyrightNFT
        .connect(user1)
        ['safeTransferFrom(address,address,uint256)'](
          user1.address,
          user2.address,
          1
        );
      // after transfer, we have a balance of 1
      expect(await copyrightNFT.balanceOf(user2.address)).to.be.equal(1);
      expect(await copyrightNFT.ownerOf(1)).to.be.equal(user2.address);
    });
  });
});
