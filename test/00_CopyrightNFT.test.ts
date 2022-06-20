import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, waffle } from 'hardhat';
import chai from 'chai';
import { Contract } from 'ethers';

chai.use(waffle.solidity);
const { expect } = chai;

interface Metadata {
  songName: string;
  artist: string;
  album: string;
  songURL: string;
}

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const NFT_NAME = 'Music NFT';
const NFT_SYMBOL = 'MNFT';
const BASE_URI = 'https://example.com/nft';
const PRICE = ethers.utils.parseUnits('1'); // 1 ETH
const METADATA: Metadata = {
  songName: 'Tangled up in Blue',
  artist: 'Bob Dylan',
  album: 'Blood On The Tracks',
  songURL:
    'https://open.spotify.com/track/6Vcwr9tb3ZLO63F8DL8cqu?si=d779b9bcaff64406'
};
const METADATA2: Metadata = {
  songName: 'Hey You',
  artist: 'Pink Floyd',
  album: 'The Wall',
  songURL:
    'https://open.spotify.com/track/7F02x6EKYIQV3VcTaTm7oN?si=ee5483d7b1fe42bf'
};

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
      await expect(copyrightNFT.connect(user1).mint(user1.address, METADATA)).to
        .be.reverted;
    });

    it('Minter can mint', async () => {
      // before minting, we have a balance of 0
      expect(await copyrightNFT.balanceOf(user1.address)).to.be.equal(0);
      // mint
      await copyrightNFT.connect(minter).mint(user1.address, METADATA);
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
      await copyrightNFT.connect(minter).mint(user1.address, METADATA);
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
      await copyrightNFT.connect(minter).mint(user1.address, METADATA);
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

  /**
   * BaseURI and TokenURI
   */
  describe('BaseURI and TokenURI', () => {
    beforeEach(async () => {
      await copyrightNFT.connect(owner).setMinter(minter.address);
      await copyrightNFT.connect(minter).mint(user1.address, METADATA);
    });

    it("Non owner can't set BaseURI", async () => {
      await expect(copyrightNFT.connect(user1).setBaseURI(BASE_URI)).to.be
        .reverted;
    });

    it('Owner can set BaseURI', async () => {
      await copyrightNFT.connect(owner).setBaseURI(BASE_URI);
      expect(await copyrightNFT.baseURI()).to.be.equal(BASE_URI);
    });

    it("Non owner of NFT can't set TokenURI", async () => {
      await expect(copyrightNFT.connect(user2).setTokenURI(BASE_URI)).to.be
        .reverted;
    });

    it('Owner of NFT can set TokenURI', async () => {
      await copyrightNFT.connect(user1).setTokenURI(1, BASE_URI);
      expect(await copyrightNFT.tokenURI(1)).to.be.equal(BASE_URI);
    });
  });

  /**
   * Metadata
   */
  describe('Metadata', () => {
    beforeEach(async () => {
      await copyrightNFT.connect(owner).setMinter(minter.address);
      await copyrightNFT.connect(minter).mint(user1.address, METADATA);
    });

    it("Non owner of NFT can't set metadata", async () => {
      await expect(copyrightNFT.connect(user2).setMetadata(1, METADATA)).to.be
        .reverted;
    });

    it('Owner of NFT can set metadata', async () => {
      let metadata = await copyrightNFT.getMetadata(1);
      expect(metadata.songName).to.be.equal(METADATA.songName);
      expect(metadata.artist).to.be.equal(METADATA.artist);
      expect(metadata.album).to.be.equal(METADATA.album);
      expect(metadata.songURL).to.be.equal(METADATA.songURL);

      await copyrightNFT.connect(user1).setMetadata(1, METADATA2);

      metadata = await copyrightNFT.getMetadata(1);
      expect(metadata.songName).to.be.equal(METADATA2.songName);
      expect(metadata.artist).to.be.equal(METADATA2.artist);
      expect(metadata.album).to.be.equal(METADATA2.album);
      expect(metadata.songURL).to.be.equal(METADATA2.songURL);
    });
  });

  /**
   * Buy a song
   */
  describe('Buy a song', () => {
    beforeEach(async () => {
      await copyrightNFT.connect(owner).setMinter(minter.address);
      await copyrightNFT.connect(minter).mint(user1.address, METADATA);
    });

    it("Buyer haven't sent the minimum price to buy the song", async () => {
      await expect(copyrightNFT.connect(user2).buySong(1)).to.be.reverted;
      await expect(copyrightNFT.connect(user2).buySong(1, { value: 50 })).to.be
        .reverted;
    });

    it('Buyer can buy a song', async () => {
      const erc20tokenAddress = await copyrightNFT.getErc20Token(1);
      const ERC20Token = await ethers.getContractFactory('ERC20Template');
      const erc20token = await ERC20Token.attach(erc20tokenAddress);
      
      // before buy, the buyer have a balance of 0 tokens to buy the song
      expect(await erc20token.balanceOf(user2.address)).to.be.equal(0);

      // buy the song
      await copyrightNFT.connect(user2).buySong(1, { value: PRICE });

      // after buy, the buyer have a balance of 1 tokens to buy the song
      expect(await erc20token.balanceOf(user2.address)).to.be.equal(1);
      // after buy, the seller have a balance of 1 ETH
      expect(await copyrightNFT.getCopyrightBalance(user1.address)).to.be.equal(
        PRICE
      );
    });
  });

  /**
   * Collect copyright gains
   */
  describe('Collect copyright gains', () => {
    beforeEach(async () => {
      await copyrightNFT.connect(owner).setMinter(minter.address);
      await copyrightNFT.connect(minter).mint(user1.address, METADATA);
      await copyrightNFT.connect(user2).buySong(1, { value: PRICE });
    });

    it("Owner without copyright gains doesn't receive funds", async () => {
      expect(await copyrightNFT.getCopyrightBalance(user2.address)).to.be.equal(
        0
      );
      const balanceBefore = await user2.getBalance();

      // collect copyright gains
      await copyrightNFT.connect(user2).collectCopyrightGains();

      // the seller has the same balance, 0 ETH
      const balanceAfter = await user2.getBalance();
      expect(
        +ethers.utils.formatUnits(balanceAfter.sub(balanceBefore).toString())
      ).to.be.closeTo(0, 0.001);
    });

    it('Owner with copyright gains does receive funds', async () => {
      expect(await copyrightNFT.getCopyrightBalance(user1.address)).to.be.equal(
        PRICE
      );
      const balanceBefore = await user1.getBalance();

      // collect copyright gains
      await copyrightNFT.connect(user1).collectCopyrightGains();

      // the seller has a balance of 1 ETH
      expect(await copyrightNFT.getCopyrightBalance(user1.address)).to.be.equal(
        0
      );
      const balanceAfter = await user1.getBalance();
      expect(
        +ethers.utils.formatUnits(balanceAfter.sub(balanceBefore).toString())
      ).to.be.closeTo(1, 0.001);
    });
  });

  /**
   * Redeem
   */
  describe('Redeem', () => {
    beforeEach(async () => {
      await copyrightNFT.connect(owner).setMinter(minter.address);
    });

    it('Redeem using ERC712 signature checker fails if signed by non-minter', async () => {
      // minter creates signature
      const signature = await user1._signTypedData(
        // Domain
        {
          name: NFT_NAME,
          version: '1.0.0',
          chainId: await minter.getChainId(),
          verifyingContract: copyrightNFT.address
        },
        // Types
        {
          NFT: [
            { name: 'songName', type: 'string' },
            { name: 'artist', type: 'string' },
            { name: 'album', type: 'string' },
            { name: 'songURL', type: 'string' },
            { name: 'account', type: 'address' }
          ]
        },
        // Value
        {
          songName: METADATA.songName,
          artist: METADATA.artist,
          album: METADATA.album,
          songURL: METADATA.songURL,
          account: user1.address
        }
      );
      // a non-minter tries to redeem and fails
      await expect(
        copyrightNFT.connect(user1).redeem(user1.address, METADATA, signature)
      ).to.be.reverted;
    });

    it('Redeem using ERC712 signature checker works if signed by minter', async () => {
      // minter creates signature
      const signature = await minter._signTypedData(
        // Domain
        {
          name: NFT_NAME,
          version: '1.0.0',
          chainId: await minter.getChainId(),
          verifyingContract: copyrightNFT.address
        },
        // Types
        {
          NFT: [
            { name: 'songName', type: 'string' },
            { name: 'artist', type: 'string' },
            { name: 'album', type: 'string' },
            { name: 'songURL', type: 'string' },
            { name: 'account', type: 'address' }
          ]
        },
        // Value
        {
          songName: METADATA.songName,
          artist: METADATA.artist,
          album: METADATA.album,
          songURL: METADATA.songURL,
          account: user1.address
        }
      );
      // redeem
      await copyrightNFT
        .connect(user1)
        .redeem(user1.address, METADATA, signature);
      // after minting, we have a balance of 1
      expect(await copyrightNFT.balanceOf(user1.address)).to.be.equal(1);
      expect(await copyrightNFT.ownerOf(1)).to.be.equal(user1.address);
      // check metadata
      const metadata = await copyrightNFT.getMetadata(1);
      expect(metadata.songName).to.be.equal(METADATA.songName);
      expect(metadata.artist).to.be.equal(METADATA.artist);
      expect(metadata.album).to.be.equal(METADATA.album);
      expect(metadata.songURL).to.be.equal(METADATA.songURL);
    });
  });
});
