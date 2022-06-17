import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, waffle } from 'hardhat';
import chai from 'chai';
import { Contract } from 'ethers';

chai.use(waffle.solidity);
const { expect } = chai;

describe('CopyrightNFT', () => {
  let copyrightNFT: Contract;
  let owner: SignerWithAddress;

  beforeEach(async () => {
    [ owner ] = await ethers.getSigners();
    const CopyrightNFT = await ethers.getContractFactory('CopyrightNFT');
    copyrightNFT = await CopyrightNFT.deploy();
    await copyrightNFT.deployed();
  });

  /**
   * Deployment
   */
  describe('Deployment', () => {
    it('CopyrightNFT contract deployed successfully', async () => {
      expect(copyrightNFT.address).to.not.be.undefined;
    });
  });
});
