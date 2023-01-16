import "@nomiclabs/hardhat-waffle";

require("@openzeppelin/hardhat-upgrades");

require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

/// ENVVAR
// - CI:                output gas report to file instead of stdout
// - COVERAGE:          enable coverage report
// - ENABLE_GAS_REPORT: enable gas report
// - COMPILE_MODE:      production modes enables optimizations (default: development)
// - COMPILE_VERSION:   compiler version (default: 0.8.9)
// - COINMARKETCAP:     coinmarkercat api key for USD value in gas report

const argv = require("yargs/yargs")()
  .env("")
  .options({
    coverage: {
      type: "boolean",
      default: false,
    },
    gas: {
      alias: "enableGasReport",
      type: "boolean",
      default: false,
    },
    gasReport: {
      alias: "enableGasReportPath",
      type: "string",
      implies: "gas",
      default: undefined,
    },
    mode: {
      alias: "compileMode",
      type: "string",
      choices: ["production", "development"],
      default: "development",
    },
    ir: {
      alias: "enableIR",
      type: "boolean",
      default: false,
    },
    compiler: {
      alias: "compileVersion",
      type: "string",
      default: "0.8.13",
    },
    coinmarketcap: {
      alias: "coinmarketcapApiKey",
      type: "string",
    },
  }).argv;

const withOptimizations = argv.gas || argv.compileMode === "production";

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
let {
  PRIVATE_KEY,
  ALCHEMY_API_KEY,
  ALCHEMY_RINKEBY_API_KEY,
  ALCHEMY_ROPSTEN_API_KEY,
  ETHERSCAN_API_KEY,
  INFURA_API_KEY,
  ARBISCAN_API_KEY,
  POLYGONSCAN_API_KEY,
  OPTIMISM_API_KEY,
  ALCHEMY_ARBITRUM_API_KEY,
} = process.env;

PRIVATE_KEY = PRIVATE_KEY
  ? PRIVATE_KEY
  : "0x2222453C7891EDB92FE70662D5E45A453C7891EDB92FE70662D5E45A453C7891";

// if not defined .env then set empty API keys, we dont use it for tests
INFURA_API_KEY = INFURA_API_KEY ? INFURA_API_KEY : "";
ALCHEMY_API_KEY = ALCHEMY_API_KEY ? ALCHEMY_API_KEY : "";
ETHERSCAN_API_KEY = ETHERSCAN_API_KEY ? ETHERSCAN_API_KEY : "";
ALCHEMY_RINKEBY_API_KEY = ALCHEMY_RINKEBY_API_KEY
  ? ALCHEMY_RINKEBY_API_KEY
  : "";
ALCHEMY_ROPSTEN_API_KEY = ALCHEMY_ROPSTEN_API_KEY
  ? ALCHEMY_ROPSTEN_API_KEY
  : "";

ARBISCAN_API_KEY = ARBISCAN_API_KEY ? ARBISCAN_API_KEY : "";
POLYGONSCAN_API_KEY = POLYGONSCAN_API_KEY ? POLYGONSCAN_API_KEY : "";
OPTIMISM_API_KEY = OPTIMISM_API_KEY ? OPTIMISM_API_KEY : "";
ALCHEMY_ARBITRUM_API_KEY = ALCHEMY_ARBITRUM_API_KEY
  ? ALCHEMY_ARBITRUM_API_KEY
  : "";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
let config = {
  solidity: {
    compilers: [
      {
        version: "0.8.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      blockGasLimit: 10000000,
      initialBaseFeePerGas: 0,
      // allowUnlimitedContractSize: !withOptimizations,
    },

    goerli: {
      // url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      // url: `https://rpc.ankr.com/eth_goerli`,
      url: `https://eth-goerli.public.blastapi.io`,
      // url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
    },
    sepolia: {
      url: `https://rpc.sepolia.org`,
      // url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
    },
    rinkeby: {
      // url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_RINKEBY_API_KEY}`,
      url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
    },
    polygonMumbai: {
      url: `https://matic-mumbai.chainstacklabs.com`, //ths RPC seems to work more consistently
      accounts: [`${PRIVATE_KEY}`],
    },
    mainnet: {
      // url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
    },
    bsc: {
      url: `https://bsc-dataseed1.binance.org:443`,
      accounts: [`${PRIVATE_KEY}`],
    },
    xdai: {
      url: `https://rpc.xdaichain.com/`,
      accounts: [`${PRIVATE_KEY}`],
    },
    polygon: {
      // url: `https://polygon.infura.io/v3/${INFURA_API_KEY}`,
      // url: `https://polygon-rpc.com`,
      // url: `https://matic-mainnet.chainstacklabs.com`,
      url: `https://polygon-mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
    },
    arbitrumOne: {
      // url: `https://arbitrum.public-rpc.com`,
      // ALCHEMY_ARBITRUM_API_KEY
      // url: `https://arb-mainnet.g.alchemy.com/v2/${ALCHEMY_ARBITRUM_API_KEY}`,
      url: `https://arb1.arbitrum.io/rpc`,
      accounts: [`${PRIVATE_KEY}`],
    },
    arbitrumTestnet: {
      url: `https://rinkeby.arbitrum.io/rpc`,
      accounts: [`${PRIVATE_KEY}`],
    },
    optimisticEthereum: {
      url: `https://mainnet.optimism.io`,
      accounts: [`${PRIVATE_KEY}`],
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      mainnet: `${ETHERSCAN_API_KEY}`,
      goerli: `${ETHERSCAN_API_KEY}`,
      arbitrumTestnet: `${ARBISCAN_API_KEY}`,
      arbitrumOne: `${ARBISCAN_API_KEY}`,
      polygonMumbai: `${POLYGONSCAN_API_KEY}`,
      polygon: `${POLYGONSCAN_API_KEY}`,
      optimisticEthereum: `${OPTIMISM_API_KEY}`,
    },
  },
};

if (argv.gas) {
  require("hardhat-gas-reporter");
  module.exports.gasReporter = {
    showMethodSig: true,
    currency: "USD",
    outputFile: argv.gasReport,
    coinmarketcap: argv.coinmarketcap,
  };
}

if (argv.coverage) {
  require("solidity-coverage");
  // config.networks.hardhat["initialBaseFeePerGas"] = 0;
}

export default config;
