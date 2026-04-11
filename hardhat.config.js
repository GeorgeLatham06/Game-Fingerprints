require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** * @type import('hardhat/config').HardhatUserConfig 
 * @dev Hardhat configuration for the Game Fingerprint project.
 */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      /**
       * @dev Use 'cancun' EVM version to support the latest Ethereum opcodes.
       * viaIR: true is required to handle complex stack operations in the 
       * SVGRenderer (prevents "Stack too deep" errors).
       */
      evmVersion: "cancun", 
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200, // Optimize for deployment cost and execution efficiency
      },
    },
  },
};