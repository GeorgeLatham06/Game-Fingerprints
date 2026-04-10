const { expect } = require("chai");
const hre = require("hardhat");

describe("GameFingerprint", function () {
  let contract;
  let owner;

  beforeEach(async function () {
    [owner] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory("GameFingerprint");
    contract = await factory.deploy();
  });

  it("minting works", async function () {
    const moveData = "0x3090c850"; // just some dummy bytes
    const metadata = '{"white":"Test","black":"Test","result":"1-0"}';

    await contract.mint(moveData, metadata);

    expect(await contract.ownerOf(0)).to.equal(owner.address);
    expect(await contract.getMoveData(0)).to.equal(moveData);
    // console.log("owner:", await contract.ownerOf(0));
  });

  it("tokenURI returns data uri", async function () {
    await contract.mint("0x3090c850", '{"white":"Test","black":"Test","result":"1-0"}');

    const uri = await contract.tokenURI(0);
    expect(uri).to.include("data:application/json;base64,");
  });

  // TODO: test that minting fails if you're not the owner
  // TODO: test with real parsed game data
});
