// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library MoveEncoder {

    // unpack the raw bytes into uint16 array (each move = 2 bytes)
    function decodeMoves(bytes memory data) internal pure returns (uint16[] memory) {
        require(data.length % 2 == 0, "Invalid move data length");
        uint256 count = data.length / 2;
        uint16[] memory moves = new uint16[](count);
        for (uint256 i = 0; i < count; i++) {
            uint16 move = uint16(uint8(data[i * 2])) << 8 | uint16(uint8(data[i * 2 + 1]));
            moves[i] = move;
        }
        return moves;
    }

    // each move is 2 bytes so just divide
    function getMoveCount(bytes memory data) internal pure returns (uint256) {
        return data.length / 2;
    }
}
