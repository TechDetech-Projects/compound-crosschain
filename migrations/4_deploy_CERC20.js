var Comptroller = artifacts.require("Comptroller");
var ExampleERC20 = artifacts.require("ERC20");
var CErc20 = artifacts.require("CErc20");
var InterestRateModel = artifacts.require("ExampleERC20InterestRateModel")

module.exports = async function (deployer, network, accounts) {
    const ComptrollerInstance = await Comptroller.deployed()
    const ExampleERC20Instance = await ExampleERC20.deployed()

    await deployer.deploy(InterestRateModel,
        2n * BigInt(1e16),
        5n * BigInt(1e17)
    )
    const InterestRateModelInstance = await InterestRateModel.deployed()

    await deployer.deploy(CErc20,
        ExampleERC20Instance.address,
        ComptrollerInstance.address,
        InterestRateModelInstance.address,
        1n * BigInt(1e18),
        "Compound SOLBYEX",
        "CSOLBYEX",
        8
    )

    CErc20Instance = await CErc20.deployed()

    await ComptrollerInstance._supportMarket(CErc20Instance.address)
    await ComptrollerInstance._setCollateralFactor(
        CErc20Instance.address,
        9n * BigInt(1e17)
    )


}