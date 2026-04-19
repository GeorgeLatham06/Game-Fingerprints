# Game Fingerprints

Chess games turned into fully on-chain generative NFTs on Ethereum Sepolia.

You upload a PGN file, and it gets minted as an NFT where the art is generated entirely by the smart contract. No IPFS, no external hosting - the contract builds the SVG itself every time someone views the NFT.

**Live contract on Sepolia:** `0xB0546C402ffC32485d1749bFa3D8395Cea3Db894`

## How to mint

Contract is already deployed, so just run the website locally and mint.

1. Clone the repo:
   ```bash
   git clone https://github.com/GeorgeLatham06/Game-Fingerprints.git
   cd Game-Fingerprints
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the website:
   ```bash
   cd frontend
   python3 -m http.server 8080
   ```

4. Open `http://localhost:8080` in your browser.

5. Connect your MetaMask, grab some Sepolia test ETH from the faucet link on the site, drag in a `.pgn` file, and hit mint.

That's it - you'll see a link to Etherscan once the transaction goes through.

## How it works

**Off-chain (JavaScript)** - A parser reads the PGN file, validates the moves using chess.js, and compresses each move into 2 bytes using bit packing. It also calculates game stats like capture count, check count, and average move distance.

**On-chain (Solidity)** - The smart contract stores the compressed move bytes when you mint. When anyone calls `tokenURI()`, the contract decodes the moves and generates an SVG image on the fly, returning it as a base64 data URI embedded in the JSON metadata. The art uses the block timestamp at mint as part of the seed, so every NFT looks unique.

## Project structure

```
contracts/
  GameFingerprint.sol  - main ERC-721 NFT contract
  MoveEncoder.sol      - library for decoding move bytes on-chain
  SVGRenderer.sol      - library that generates the SVG art
scripts/
  parsePGN.js          - reads a .pgn file and outputs encoded move data
  mint.js              - mints an NFT using parsed game data
  preview.js           - deploys locally and generates an SVG preview
  deploy.js            - deploys the contract to sepolia
frontend/
  index.html           - the minting website (single file, no build needed)
test/
  GameFingerprint.test.js
games/
  sample.pgn           - scholar's mate test game
  deepblue.pgn         - kasparov vs deep blue (1997)
```

## Developing locally

Compile the contracts:
```bash
npx hardhat compile
```

Run tests:
```bash
npx hardhat test
```

Preview the art locally without deploying:
```bash
node scripts/parsePGN.js games/sample.pgn
npx hardhat run scripts/preview.js
open output.svg
```

## Tech stack

- Solidity 0.8.28 / Hardhat
- OpenZeppelin (ERC-721, Ownable, Base64)
- Solady (DynamicBufferLib, FixedPointMathLib) for gas-efficient SVG building
- chess.js for PGN parsing
- ethers.js v6 for the frontend
- Sepolia testnet
