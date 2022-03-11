/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 require("@nomiclabs/hardhat-waffle")
 require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan");
 // require("solidity-coverage");
 
 // require('hardhat-spdx-license-identifier');
 // require("hardhat-gas-reporter");
 const CONFIG = require("./credentials.js");
 
 module.exports = {
     solidity: {
         compilers: [
            {
                version: "0.8.0",
                settings: {
                    optimizer: {
                        enabled: false,
                        runs: 200,
                    },
                },
            }
         ],
     },
     spdxLicenseIdentifier: {
         overwrite: true,
         runOnCompile: true,
     },
     // gasReporter: {
     //     currency: 'USD',
     //     gasPrice: 1
     // },
     defaultNetwork: "hardhat",
     mocha: {
         timeout: 1000000000000,
     },
 
     networks: {
         hardhat: {
             blockGasLimit: 10000000000000,
             allowUnlimitedContractSize: true,
             timeout: 1000000000000,
             accounts: {
                 accountsBalance: "100000000000000000000000",
                 count: 20,
             },
         },
         bscTestnet: {
             url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
             accounts: [CONFIG.wallet.PKEY],
             gasPrice: 30000000000,
         },
         bscMainnet: {
            url: `https://bsc-dataseed.binance.org/`,
            accounts: [CONFIG.wallet.PKEY],
            gasPrice: 30000000000,
        },
         polygonTestnet: {
            url: CONFIG.polygonTestnet.url,
            accounts: [CONFIG.wallet.PKEY],
            gasPrice: 1000000000,
         },
         ftmTestnet: {
            url: `https://rpc.testnet.fantom.network/`,
            accounts: [CONFIG.wallet.PKEY],
         },
         rinkeby: {
            url: "https://rinkeby.infura.io/v3/ad9cef41c9c844a7b54d10be24d416e5",
            accounts: [CONFIG.wallet.PKEY],
            // gasPrice: 30000000000,
        },
        kovan: {
            url: "https://kovan.infura.io/v3/ad9cef41c9c844a7b54d10be24d416e5",
            accounts: [CONFIG.wallet.PKEY],
            // gasPrice: 30000000000,
        },
     },
 
     contractSizer: {
         alphaSort: false,
         runOnCompile: true,
         disambiguatePaths: false,
     },
     etherscan: {
        apiKey: {
            ftmTestnet: `${CONFIG.ftmscan.KEY}`
        }
    }
 };
 