require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
//const { vars } = require("hardhat/config");
require("dotenv/config");

//  const ETHERSCAN_API_KEY = vars.get("OKLINK_AMOY_API");

/** @type import('hardhat/config').HardhatUserConfig */
require("dotenv").config();
const { POLYGON_AMOY_RPC, PRIVATE_KEY, API_URL } = process.env;

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    polygonAmoy: {
      url: `${POLYGON_AMOY_RPC}`,
      accounts: [`${PRIVATE_KEY}`],
    },
    sepolia: {
      url: process.env.API_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    customChains: [
      {
        network: "polygonAmoy",
        chainId: 80002,
        urls: {
          apiURL:
            "https://www.oklink.com/api/explorer/v1/contract/verify/async/api/polygonAmoy",
          browserURL: "https://www.oklink.com/Amoy",
        }
      }
    ]
  },

  sourcify: {
    enabled: true,
  },
};
