var Comptroller = artifacts.require("Comptroller");
var ExampleERC20 = artifacts.require("ERC20");
var CCrosschainErc20 = artifacts.require("CCrosschainErc20");
var InterestRateModel = artifacts.require("ExampleERC20InterestRateModel")

module.exports = async function (deployer, network, accounts) {
    const ComptrollerInstance = await Comptroller.deployed()
    await deployer.deploy(InterestRateModel,
        2n * BigInt(1e16),
        5n * BigInt(1e17)
    )
    const InterestRateModelInstance = await InterestRateModel.deployed()
    
    const gatewayAddress = "0x9E404e6ff4F2a15C99365Bd6615fCE3FB9E9Cb76";
    const baseChainName = "Moonbeam"
    const secondaryChain = "Polygon"
    const underlyingSatellite = "0x0000000000000000000000000000000000000000"
    await deployer.deploy(CCrosschainErc20,
        gatewayAddress,
        secondaryChain,
        underlyingSatellite,
        ComptrollerInstance.address,
        InterestRateModelInstance.address,
        1n * BigInt(1e18),
        "Compound Crosschain Token",
        "CCToken",
        8
    )

    CCrosschainErc20Instance = await CCrosschainErc20.deployed()

    await ComptrollerInstance._supportMarket(CCrosschainErc20Instance.address)
    await ComptrollerInstance._setCollateralFactor(
        CCrosschainErc20Instance.address,
        9n * BigInt(1e17)
    )


}