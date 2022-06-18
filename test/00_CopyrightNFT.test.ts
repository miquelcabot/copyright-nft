import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, waffle } from 'hardhat';
import chai from 'chai';
import { Contract } from 'ethers';

chai.use(waffle.solidity);
const { expect } = chai;

const NFT_NAME = 'Music NFT';
const NFT_SYMBOL = 'MNFT';

describe('CopyrightNFT', () => {
  let copyrightNFT: Contract;
  let owner: SignerWithAddress;

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
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
});
