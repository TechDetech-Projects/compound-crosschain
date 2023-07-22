const BN = require('bn.js');
var chai = require('chai');
var bnChai = require('chai-bn');
chai.use(bnChai(BN));

var Comptroller = artifacts.require("Comptroller")
var SimplePriceOracle = artifacts.require("SimplePriceOracle");
var CEther = artifacts.require("CEther")

contract("CEther Initialization and Functionality Tests", (accounts) => {
    const adminAddress = accounts[0];

    it("Get CEther underlying price.", async () => {
        const CEtherInstance = await CEther.deployed();
        const SimplePriceOracleInstance = await SimplePriceOracle.deployed();

        CEtherUnderlyingPriceResult = await SimplePriceOracleInstance.getUnderlyingPrice(CEtherInstance.address)

        chai.expect(CEtherUnderlyingPriceResult).to.be.a.bignumber;
    });

    it("Set CEther underlying price.", async () => {
        const CEtherInstance = await CEther.deployed();
        const SimplePriceOracleInstance = await SimplePriceOracle.deployed();

        var newPrice = new BN("1" + 18 * "0")
        await SimplePriceOracleInstance.setUnderlyingPrice(CEtherInstance.address, newPrice)

        CEtherUnderlyingPriceResult = await SimplePriceOracleInstance.getUnderlyingPrice(CEtherInstance.address)

        chai.expect(CEtherUnderlyingPriceResult).to.be.a.bignumber.equal(newPrice);
    })

    it("Check non-membership of CEther market.", async () => {
        const ComptrollerInstance = await Comptroller.deployed()
        const CEtherInstance = await CEther.deployed();
        var CEtherMembership = await ComptrollerInstance.checkMembership(adminAddress, CEtherInstance.address)

        chai.expect(CEtherMembership).to.be.false;
    })

    var mintValue = new BN("1" + "0".repeat(18))
    it("Mint CEther tokens and deposit ether.", async () => {
        const CEtherInstance = await CEther.deployed();

        await CEtherInstance.mint({ value: mintValue })

        var mintedTokens = await CEtherInstance.balanceOf(adminAddress)

        chai.expect(mintedTokens).to.be.a.bignumber.equal(mintValue);
    })


    var borrowValue = new BN("1" + "0".repeat(15)) // Further research on the max borrow value calculation is needed.
    it("Borrow ether.", async () => {
        const CEtherInstance = await CEther.deployed();
        const ComptrollerInstance = await Comptroller.deployed();
        var accountLiquidity = await ComptrollerInstance.getAccountLiquidity(adminAddress)
        console.log(Number(accountLiquidity[0]),Number(accountLiquidity[1]),Number(accountLiquidity[2]))

        var originalEtherBalance = await web3.eth.getBalance(adminAddress);
        await CEtherInstance.borrow(borrowValue)
        var newEtherBalance = await web3.eth.getBalance(adminAddress);
        var borrowedEther = new BN(newEtherBalance - originalEtherBalance)
        chai.expect(borrowedEther).to.not.be.a.bignumber.that.is.zero;


        var accountLiquidity = await ComptrollerInstance.getAccountLiquidity(adminAddress)
        console.log(Number(accountLiquidity[0]),Number(accountLiquidity[1]),Number(accountLiquidity[2]))

        var borrowBalance = await CEtherInstance.borrowBalanceStored(adminAddress)
        console.log({borrowBalance:Number(borrowedEther)})

    })

    it("Check membership of CEther market.", async () => {
        const ComptrollerInstance = await Comptroller.deployed()
        const CEtherInstance = await CEther.deployed();
        var CEtherMembership = await ComptrollerInstance.checkMembership(adminAddress, CEtherInstance.address)

        chai.expect(CEtherMembership).to.be.true;
    })

    it("Repay ether.", async () => {
        const CEtherInstance = await CEther.deployed();
        await CEtherInstance.repayBorrow({ value: borrowValue })
    })

    var redeemValue = new BN("9")
    it("Redeem CEther tokens for ether.", async () => {
        const CEtherInstance = await CEther.deployed();

        var tokenBalance = await CEtherInstance.balanceOf(adminAddress)
        console.log(Number(tokenBalance))

        await CEtherInstance.redeem(redeemValue)

        var tokenBalance = await CEtherInstance.balanceOf(adminAddress)
        console.log(Number(tokenBalance))
    })
})