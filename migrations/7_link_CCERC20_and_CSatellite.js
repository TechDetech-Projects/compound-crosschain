var CCrosschainErc20 = artifacts.require("CCrosschainErc20");
module.exports = async function (deployer, network, accounts) {
    const CSatelliteAddress = "0x1775191B8A664F29a64F89680991d262E63AB3a4"
    var CCrosschainErc20Instance = await CCrosschainErc20.deployed()
    await CCrosschainErc20Instance._setUnderlyingSatellite(CSatelliteAddress)
}