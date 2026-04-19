const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  // read the parsed game data
  const parsedPath = process.argv[2] || path.join(__dirname, "../games/parsed_output.json");
  const parsed = JSON.parse(fs.readFileSync(parsedPath, "utf-8"));

  const [deployer] = await hre.ethers.getSigners();
  console.log("minting with:", deployer.address);

  const contractAddress = process.env.CONTRACT_ADDRESS;
  if (!contractAddress) {
    console.error("set CONTRACT_ADDRESS in .env first");
    process.exit(1);
  }

  const contract = await hre.ethers.getContractAt("GameFingerprint", contractAddress);

  const attributes = JSON.stringify([ // Build an attributes string in js before sending to the contract since solidity cant parse json. Used to return the metadata in the output of tokenURI
    { trait_type: "White", value: parsed.metadata.white },
    { trait_type: "Black", value: parsed.metadata.black },
    { trait_type: "Result", value: parsed.metadata.result },
    { trait_type: "Date", value: parsed.metadata.date },
    { trait_type: "Event", value: parsed.metadata.event },
    { trait_type: "Captures", value: parsed.stats.captureCount },
    { trait_type: "Checks", value: parsed.stats.checkCount },
    { trait_type: "Move Count", value: parsed.stats.totalMoves },
]);

  const tx = await contract.mint(
    parsed.encodedBytes,
    attributes,
    parsed.stats.captureCount,
    parsed.stats.checkCount
  );
  const receipt = await tx.wait();
  console.log("minted! tx:", receipt.hash);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
