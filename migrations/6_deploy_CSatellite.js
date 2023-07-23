var CSatellite = artifacts.require("CSatellite");
module.exports = async function (deployer, network, accounts) {
    const gatewayAddress = "0xc7B788E88BAaB770A6d4936cdcCcd5250E1bbAd8";
    const baseChainName = "Moonbeam"
    const baseContractAddress = "0xf50549238fd5638F141C7711aa55F151BcA2b3b3"
    const underlyingToken = "0x7D27f1D0EE644aE25ce2F27F0d6a41574dea14F5"
    await deployer.deploy(
        CSatellite,
        gatewayAddress,
        baseChainName,
        baseContractAddress,
        underlyingToken
    )
}