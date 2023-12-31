require('dotenv').config();
const { MNEMONIC } = process.env;

// const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: 5777,       // Any network (default: none)
    },
    dev_moonbeam: {
      host: "127.0.0.1:8500/0",
      network_id: 2500
    },
    dev_polygon: {
      host: "127.0.0.1:8500/4",
      network_id: 2504
    }
  },

  // Set default mocha options here, use special reporters, etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.10",
      settings: {
        optimizer: {
          enabled: true,
          runs: 1500
        }
      }
    }
  },
};
