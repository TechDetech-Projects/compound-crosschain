var Comptroller = artifacts.require("Comptroller");
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
};