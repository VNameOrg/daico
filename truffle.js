module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!

  networks: {
    development: {
      host: "192.168.1.113",
      port: 7545,
      network_id: "5777"
    },
    local: {
      host: "localhost",
      port: 9545,
      network_id: "*"
    },
    rinkeby: {
      host: "localhost", // Connect to geth on the specified
      port: 8545,
      from: "0xb5ae340f37064B04613762DFF5D20831aB1C103B", // default address to use for any transaction Truffle makes during migrations
      network_id: 4,
      gas: 4612388 // Gas limit used for deploys
    },
    rinkeby2: {
      provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/QtnQ6cr8S78wSz3fdDz3"),
      //from: "0xb5ae340f37064B04613762DFF5D20831aB1C103B", // default address to use for any transaction Truffle makes during migrations
      network_id: 4,
      gas: 4612388, // Gas limit used for deploys
      gasPrice: 5000000000
    }
  },
};
