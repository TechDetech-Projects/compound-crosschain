var Comptroller = artifacts.require("Comptroller");
var CEther = artifacts.require("CEther");
var InterestRateModel = artifacts.require("WhitePaperInterestRateModel");

module.exports = function(deployer) {
  deployer.deploy(Comptroller);
  deployer.deploy(InterestRateModel,
    )
  deployer.deploy(CEther,
    Comptroller.address,
    InterestRateModel.address,
    
    )

};