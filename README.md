# Game Fingerprints

Turning chess games into fully on-chain generative NFTs on Ethereum Sepolia.

The idea: you feed in a PGN file (a recorded chess game), and it gets minted as an NFT where the art is generated entirely by the smart contract. No IPFS, no external hosting the contract builds the SVG itself every time someone views the NFT.

## How it works

There are two sides to this:

**Off-chain (JavaScript)** - A parser reads the PGN file, validates the moves using chess.js, and compresses each move into 2 bytes using bit packing. This keeps the on-chain storage cost low. It also calculates game stats like capture count, check count, and average move distance.

**On-chain (Solidity)** - The smart contract stores the compressed move bytes when you mint. When anyone calls `tokenURI()`, the contract decodes the moves and generates an SVG image on the fly, returning it as a base64 data URI embedded in the JSON metadata. Fully self-contained.

## Project structure

```
contracts/
  GameFingerprint.sol  - main ERC-721 NFT contract
  MoveEncoder.sol      - library for encoding/decoding move bytes
  SVGRenderer.sol      - library that generates the SVG (placeholder rn)
scripts/
  parsePGN.js          - reads a .pgn file and outputs encoded move data
  mint.js              - mints an NFT using parsed game data
  preview.js           - fetches tokenURI and saves the SVG locally
test/
  GameFingerprint.test.js
games/
  sample.pgn           - test game (scholar's mate)
```

## Setup

```bash
git clone https://github.com/GeorgeLatham06/Game-Fingerprints.git
cd Game-Fingerprints
npm install
```

Copy `.env.example` to `.env` and fill in your values when ready to deploy (can wait till we write the art engine):
```
SEPOLIA_RPC_URL=your_alchemy_or_infura_url
PRIVATE_KEY=your_wallet_private_key
```

## Running it

Compile the contracts:
```bash
npx hardhat compile
```

Run tests:
```bash
npx hardhat test
```

Parse a chess game:
```bash
node scripts/parsePGN.js games/sample.pgn
```

## What's done

- Project scaffold with Hardhat, OpenZeppelin, chess.js
- PGN parser that compresses moves into 2-byte encoding with game stats
- ERC-721 contract that stores move data and returns on-chain metadata
- Basic tests passing
- tokenURI returns base64 encoded JSON with embedded SVG

## What's left

- [ ] Build the art engine in SVGRenderer.sol - needs to generate unique SVGs from the move data and stats
- [ ] Wire up tokenURI to use SVGRenderer.render() instead of the placeholder
- [ ] Write a deploy script for Sepolia
- [ ] Set up Alchemy/Infura for RPC access and get test ETH from a faucet
- [ ] Deploy, mint, and verify on OpenSea testnet

## Tech stack

- Solidity 0.8.28 / Hardhat
- OpenZeppelin contracts (ERC-721, Ownable, Base64)
- chess.js for PGN parsing
- Sepolia testnet
