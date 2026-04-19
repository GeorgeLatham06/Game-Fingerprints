const { ethers } = require("hardhat");
const fs = require("fs");

/**
 * @dev Local testing script to preview the on-chain generative art.
 * This script automates: Local Deployment -> Minting -> TokenURI Retrieval -> SVG Extraction.
 */
async function main() {
    console.log("🚀 Starting local preview generator...");

    // 1. Deploy the contract to a local in-memory blockchain (Hardhat Network)
    const GameFingerprint = await ethers.getContractFactory("GameFingerprint");
    const contract = await GameFingerprint.deploy();
    
    // Handle asynchronous deployment based on ethers.js version (v5 vs v6)
    if (contract.waitForDeployment) {
        await contract.waitForDeployment();
    } else {
        await contract.deployed();
    }
    console.log("✅ Temporary contract deployed!");

    /**
     * 2. Prepare mock chess move data
     * This 0x... hex string represents encoded move data (2-byte encoding)
     * using the Kasparov vs. Deep Blue, Game 6 (1997) dataset.
     */
    const dummyMoveData = "0x31c0caa02db0ce3005208dc849c8e7307260fad01530d2c01950def09ac8ef401060d6c84ee4f3b009d0c6102180eb101440b6307560efa06218aa180d30c6a0ba50b2581348f74829a0"; 
    const dummyMetadata = JSON.stringify([
        { trait_type: "White", value: "Kasparov" },
        { trait_type: "Black", value: "Deep Blue" },
        { trait_type: "Result", value: "0-1" },
        { trait_type: "Date", value: "1997.05.11" },
        { trait_type: "Event", value: "IBM Kasparov vs. Deep Blue Rematch" }
    ]);

    // 3. Mint a test NFT with the provided move data
    console.log("🔨 Minting test NFT...");
    const tx = await contract.mint(dummyMoveData, dummyMetadata, 9, 1);
    await tx.wait();

    // 4. Retrieve the tokenURI (Base64 encoded JSON)
    console.log("🔍 Fetching tokenURI...");
    const uri = await contract.tokenURI(0);

    /**
     * 5. Decode the Base64 JSON and extract the SVG image data
     * Step 1: Parse the JSON from the Data URI.
     * Step 2: Extract and decode the SVG string from the "image" field.
     */
    const base64Json = uri.split(",")[1];
    const jsonStr = Buffer.from(base64Json, "base64").toString("utf-8");
    const json = JSON.parse(jsonStr);

    const base64Svg = json.image.split(",")[1];
    const svgStr = Buffer.from(base64Svg, "base64").toString("utf-8");

    // 6. Write the final SVG to a file for visual verification
    fs.writeFileSync("output.svg", svgStr);
    console.log("🎉 Success! Check the 'output.svg' file in your project root.");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });