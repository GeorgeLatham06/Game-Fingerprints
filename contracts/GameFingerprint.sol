// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MoveEncoder.sol";
import "./SVGRenderer.sol";

/**
 * @title GameFingerprint
 * @dev On-chain Generative Art NFT representing chess game fingerprints.
 */
contract GameFingerprint is ERC721, Ownable {
    using MoveEncoder for bytes;
    using Strings for uint256;

    uint256 private _nextTokenId;

    struct GameData {
        bytes moveData;
        string metadata;
        uint256 captures;
        uint256 checks;
        uint256 mintTimestamp; //added so that the image is generated based on the time it was minted instead of when it's viewed
    }

    // Mapping from tokenId to game data storage
    mapping(uint256 => GameData) private _games;

    constructor() ERC721("Game Fingerprint", "GFPR") Ownable(msg.sender) {}

    /**
     * @dev Mints a new game fingerprint NFT.
     * @param moveData Encoded move data from the PGN parser.
     * @param metadata String containing game details (e.g., players, results).
     */
    function mint(bytes calldata moveData, string calldata metadata, uint256 captures, uint256 checks) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _games[tokenId] = GameData({moveData: moveData, metadata: metadata, captures: captures, checks: checks, mintTimestamp: block.timestamp});
        return tokenId;
    }

    /**
     * @dev Generates the token URI containing on-chain SVG and JSON metadata.
     * Note: Currently using hardcoded values for 'captures' and 'checks' for testing.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        GameData storage game = _games[tokenId];
        
        // Decoding the move data bytes into uint16 array for the renderer
        uint16[] memory moves = game.moveData.decodeMoves();
        
        // TODO: Dynamically parse capture/check counts from metadata.
        // Currently utilizing hardcoded values based on the Kasparov vs. Deep Blue (Game 6) test.
        string memory svg = SVGRenderer.render(
            moves, 
            moves.length,
            game.captures,
            game.checks,
            game.mintTimestamp


            /* 
            9, // TEMPORARY: Hardcoded capture count
            1  // TEMPORARY: Hardcoded check count
            */
        );

        // Building the JSON metadata
        string memory json = string(
            abi.encodePacked(
                '{"name":"Game Fingerprint #',
                tokenId.toString(),
                '","description":"On-chain chess game fingerprint","attributes":',
                game.metadata,
                ',"image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Returns raw move data for a given token.
     */
    function getMoveData(uint256 tokenId) external view returns (bytes memory) {
        _requireOwned(tokenId);
        return _games[tokenId].moveData;
    }

    /**
     * @dev Returns raw metadata string for a given token.
     */
    function getMetadata(uint256 tokenId) external view returns (string memory) {
        _requireOwned(tokenId);
        return _games[tokenId].metadata;
    }
}