const hre = require("hardhat");
const BigNumber = require("bignumber.js");
const { boolean } = require("hardhat/internal/core/params/argumentTypes");
const { helpers } = require("../helper");
const { waitSeconds } = require("../helper/helpers");
const exec = require("child_process").exec;

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const _countDest = 2; // Count of the destination wallets, default: 2
  const _bridge = "0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE";

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const gas = await ethers.provider.getGasPrice();
  console.log("Gas Price: ", gas);

  const hecBridgeSplitterFactory = await ethers.getContractFactory("HecBridgeSplitter");
  console.log("Deploying HecBridgeSplitter Contract...");

  const hecBridgeSplitterContract = await hre.upgrades.deployProxy(
    hecBridgeSplitterFactory,
    [_countDest, _bridge],
    {
      gas: gas,
      initializer: "initialize",
    }
  );
  console.log("HecBridgeSplitter contract deployed to:", hecBridgeSplitterContract.address);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
