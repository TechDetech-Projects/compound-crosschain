var CEther = artifacts.require("CEther");
var InterestRateModel = artifacts.require("WhitePaperInterestRateModel");
var Comptroller = artifacts.require("Comptroller");

module.exports = async function (deployer, network, accounts) {
  const deployerAddress = accounts[0];

  await deployer.deploy(InterestRateModel,
    2n*BigInt(1e16),
    5n*BigInt(1e17)
    )

  const ComptrollerInstance = await Comptroller.deployed()

  await deployer.deploy(CEther,
    ComptrollerInstance.address,
    InterestRateModel.address,
    1n * BigInt(1e18),
    "Compound Ether",
    "cETH",
    8,
    deployerAddress
  )
  CEtherInstance = await CEther.deployed()

  await ComptrollerInstance._supportMarket(CEther.address)
  await ComptrollerInstance._setCollateralFactor(
    CEther.address,
    9n * BigInt(1e17)
  )

};