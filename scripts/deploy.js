const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    //get teh deployer wallet for gas payment
    const [deployer] = await hre.ethers.getSigners();
    console.log("deploying with:", deployer.address);

    //deploy contract
    const factory = await hre.ethers.getContractFactory("GameFingerprint");
    const contract = await factory.deploy();
    await contract.waitForDeployment();

    //log contract address
    const address = await contract.getAddress();
    console.log("contract deployed to:", address);

    // automatically save the address to .env so mint.js can use it
    const envPath = path.join(__dirname, "../.env");
    const envLine = `CONTRACT_ADDRESS=${address}\n`;

    //writing contract address to the .env file
    if (fs.existsSync(envPath)) {
        const existing = fs.readFileSync(envPath, "utf-8");
        if (existing.includes("CONTRACT_ADDRESS=")) {
            const updated = existing.replace(/CONTRACT_ADDRESS=.*\n/, envLine);
            fs.writeFileSync(envPath, updated);
        } else {
            fs.appendFileSync(envPath, envLine);
        }
    } else {
        fs.writeFileSync(envPath, envLine);
    }

    console.log("CONTRACT_ADDRESS saved to .env");
}

//print error code if any error occurs
main().catch((err) => {
    console.error(err);
    process.exitCode = 1;
});