var Comptroller = artifacts.require("Comptroller");
var CEther = artifacts.require("CEther");
var SimplePriceOracle = artifacts.require("SimplePriceOracle");
var InterestRateModel = artifacts.require("WhitePaperInterestRateModel");

module.exports = async function (deployer, network, accounts) {
  const deployerAddress = accounts[0];

  await deployer.deploy(Comptroller);
  ComptrollerInstance = await Comptroller.deployed();
  await deployer.deploy(SimplePriceOracle)

  await ComptrollerInstance._setPriceOracle(SimplePriceOracle.address);
  await ComptrollerInstance._setCloseFactor(5n * BigInt(1e17))
  await ComptrollerInstance._setLiquidationIncentive(
    105n * BigInt(1e16)
  )

  await deployer.deploy(InterestRateModel,
    2n*BigInt(1e16),
    5n*BigInt(1e17)
    )
  await deployer.deploy(CEther,
    Comptroller.address,
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