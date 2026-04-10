const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const tokenId = process.argv[2] || "0";

  const contractAddress = process.env.CONTRACT_ADDRESS;
  if (!contractAddress) {
    console.error("set CONTRACT_ADDRESS in .env first");
    process.exit(1);
  }

  const contract = await hre.ethers.getContractAt("GameFingerprint", contractAddress);
  const uri = await contract.tokenURI(tokenId);

  // tokenURI returns: data:application/json;base64,<stuff>
  // so we split on the comma and decode the base64 part
  const jsonBase64 = uri.split(",")[1];
  const metadata = JSON.parse(Buffer.from(jsonBase64, "base64").toString());

  console.log("metadata:", JSON.stringify(metadata, null, 2));

  // the image field is ALSO a data uri, decode that too to get the svg
  if (metadata.image) {
    const svgBase64 = metadata.image.split(",")[1];
    const svg = Buffer.from(svgBase64, "base64").toString();
    const outPath = path.join(__dirname, "../games/preview.svg");
    fs.writeFileSync(outPath, svg);
    console.log("svg saved to", outPath);
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
