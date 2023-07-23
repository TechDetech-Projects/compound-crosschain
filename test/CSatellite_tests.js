const BN = require('bn.js');
var chai = require('chai');
var bnChai = require('chai-bn');
chai.use(bnChai(BN));

var Comptroller = artifacts.require("Comptroller")
var SimplePriceOracle = artifacts.require("SimplePriceOracle");
var CEther = artifacts.require("CEther")

contract("CEther Initialization and Functionality Tests", (accounts) => {


})