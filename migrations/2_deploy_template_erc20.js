const BN = require('bn.js');

var ExampleERC20 = artifacts.require("ERC20");

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(ExampleERC20)
    const ExampleERC20Instance = await ExampleERC20.deployed()
    const ERC20MintAmount = new BN("1000000000000000000")
    await ExampleERC20Instance.mint(ERC20MintAmount)
}