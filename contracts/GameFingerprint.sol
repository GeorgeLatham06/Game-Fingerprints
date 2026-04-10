// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MoveEncoder.sol";
import "./SVGRenderer.sol";

contract GameFingerprint is ERC721, Ownable {
    using MoveEncoder for bytes;
    using Strings for uint256;

    uint256 private _nextTokenId;

    struct GameData {
        bytes moveData;
        string metadata;
    }

    // tokenId => game data
    mapping(uint256 => GameData) private _games;

    constructor() ERC721("Game Fingerprint", "GFPR") Ownable(msg.sender) {}

    function mint(bytes calldata moveData, string calldata metadata) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _games[tokenId] = GameData({moveData: moveData, metadata: metadata});
        return tokenId;
    }

    // TODO: hook up SVGRenderer.render() once the art engine is done
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        GameData storage game = _games[tokenId];
        uint256 moveCount = game.moveData.getMoveCount();

        // build the json metadata with the svg embedded as base64
        string memory json = string(
            abi.encodePacked(
                '{"name":"Game Fingerprint #',
                tokenId.toString(),
                '","description":"On-chain chess game fingerprint (',
                moveCount.toString(),
                ' moves)","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes("<svg xmlns='http://www.w3.org/2000/svg' width='512' height='512'><rect width='512' height='512' fill='#1a1a2e'/><text x='256' y='256' text-anchor='middle' fill='white' font-size='24'>Game Fingerprint</text></svg>")),
                '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function getMoveData(uint256 tokenId) external view returns (bytes memory) {
        _requireOwned(tokenId);
        return _games[tokenId].moveData;
    }

    function getMetadata(uint256 tokenId) external view returns (string memory) {
        _requireOwned(tokenId);
        return _games[tokenId].metadata;
    }
}
