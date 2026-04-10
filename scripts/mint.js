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

  const tx = await contract.mint(
    parsed.encodedBytes,
    JSON.stringify(parsed.metadata)
  );
  const receipt = await tx.wait();
  console.log("minted! tx:", receipt.hash);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
