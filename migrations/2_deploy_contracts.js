var Comptroller = artifacts.require("Comptroller");

module.exports = function(deployer) {
  deployer.deploy(Comptroller);
};