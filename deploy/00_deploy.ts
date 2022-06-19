import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const erc20template = await deploy('ERC20Template', {
    from: deployer,
    args: ['Music ERC20 token', 'MTOKEN'],
    log: true
  });

  await deploy('CopyrightNFT', {
    from: deployer,
    args: ['Music NFT', 'MNFT', erc20template.address],
    log: true
  });
};

func.tags = ['CopyrightNFT'];
export default func;
