import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('CopyrightNFT', {
    from: deployer,
    args: ['Music NFT', 'MNFT'],
    log: true
  });
};

func.tags = ['CopyrightNFT'];
export default func;
