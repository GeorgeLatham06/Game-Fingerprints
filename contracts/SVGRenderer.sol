// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title SVGRenderer
 * @dev Master engine for the "Macro-Cosmos" generative art series.
 * Transforms chess move data into a high-fidelity, chaotic on-chain visual.
 */
library SVGRenderer {
    using Strings for uint256;

    /**
     * @dev Defines SVG filters, gradients, and CSS animations.
     * Includes Heavy Glow for blooming effects and Film Grain for analog texture.
     */
    function _generateDefs() private pure returns (string memory) {
        return string(abi.encodePacked(
            "<defs>",
            "<filter id='glowHeavy' x='-50%' y='-50%' width='200%' height='200%'><feGaussianBlur stdDeviation='15' result='blur'/><feComposite in='SourceGraphic' in2='blur' operator='over'/></filter>",
            "<filter id='glowLight'><feGaussianBlur stdDeviation='3' result='blur'/><feMerge><feMergeNode in='blur'/><feMergeNode in='SourceGraphic'/></feMerge></filter>",
            "<filter id='filmGrain'><feTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='3' stitchTiles='stitch'/></filter>",
            
            // Narrative-driven gradients: Early game (Cool) -> Mid game (Vibrant) -> Late game (Heat)
            "<linearGradient id='earlyGrad' x1='0%' y1='0%' x2='100%' y2='100%'><stop offset='0%' stop-color='#00c6ff'/><stop offset='100%' stop-color='#0072ff'/></linearGradient>",
            "<linearGradient id='midGrad' x1='0%' y1='100%' x2='100%' y2='0%'><stop offset='0%' stop-color='#f77062'/><stop offset='100%' stop-color='#fe5196'/></linearGradient>",
            "<linearGradient id='lateGrad' x1='50%' y1='50%' r='50%'><stop offset='0%' stop-color='#f9d423'/><stop offset='100%' stop-color='#ff4e50'/></linearGradient>",
            "</defs>",
            "<style>",
            "@keyframes pulse { 0%, 100% { opacity: 0.7; } 50% { opacity: 1; } } ",
            ".pulse { animation: pulse 3s ease-in-out infinite; }",
            "</style>"
        ));
    }

    /**
     * @dev Generates a massive ambient background with light orbs and macro orbits.
     * Fills the canvas void with bold yet soft geometric structures.
     */
    function _generateMacroBackground(uint256 seed) private pure returns (string memory) {
        // Base color: Deep Midnight Blue for enhanced contrast
        string memory bg = "<rect width='1024' height='1024' fill='#050814'/>";

        // Massive Light Blooms: 3 super-sized orbs derived from seed
        for (uint i = 0; i < 3; i++) {
            uint256 cx = (seed >> (i * 4)) % 1024;
            uint256 cy = (seed >> (i * 4 + 8)) % 1024;
            uint256 r = 400 + ((seed >> (i * 4 + 16)) % 500);
            
            string memory colorUrl = (i == 0) ? "url(#earlyGrad)" : ((i == 1) ? "url(#midGrad)" : "url(#lateGrad)");
            
            bg = string(abi.encodePacked(
                bg,
                "<circle cx='", cx.toString(), "' cy='", cy.toString(), "' r='", r.toString(), "' fill='", colorUrl, "' opacity='0.15' filter='url(#glowHeavy)' style='mix-blend-mode: screen;'/>"
            ));
        }

        // Macro-Orbits: Gigantic elliptical frames to provide spatial depth
        uint256 angle = seed % 360;
        uint256 rx = 300 + (seed % 300);
        uint256 ry = 200 + ((seed >> 8) % 300);
        
        bg = string(abi.encodePacked(
            bg,
            "<ellipse cx='512' cy='512' rx='", rx.toString(), "' ry='", ry.toString(), "' fill='none' stroke='#ffffff' stroke-width='1' stroke-dasharray='5, 30' opacity='0.15' transform='rotate(", angle.toString(), " 512 512)'/>",
            "<ellipse cx='512' cy='512' rx='", ry.toString(), "' ry='", rx.toString(), "' fill='none' stroke='url(#earlyGrad)' stroke-width='2' opacity='0.1' transform='rotate(", (360 - angle).toString(), " 512 512)'/>"
        ));

        // Background diagonal framing
        uint256 y1 = (seed % 500);
        uint256 y2 = ((seed >> 8) % 500) + 500;
        bg = string(abi.encodePacked(
            bg,
            "<line x1='0' y1='", y1.toString(), "' x2='1024' y2='", (y1 + 300).toString(), "' stroke='#ffffff' stroke-width='2' opacity='0.08'/>",
            "<line x1='0' y1='", y2.toString(), "' x2='1024' y2='", (y2 - 300).toString(), "' stroke='url(#midGrad)' stroke-width='4' opacity='0.05'/>",
            "<rect width='1024' height='1024' filter='url(#filmGrain)' opacity='0.08' style='mix-blend-mode: overlay; pointer-events:none;'/>"
        ));

        return bg;
    }

    /**
     * @dev Renders subtle starfield particles across the global arena.
     */
    function _generateGlobalArena(uint256 seed) private pure returns (string memory) {
        string memory arena = "";
        for (uint i = 0; i < 50; i++) {
            uint256 x = (seed >> i) % 1024;
            uint256 y = (seed >> (i+1)) % 1024;
            uint256 r = ((seed >> (i+2)) % 4) + 1;
            uint256 op = ((seed >> (i+3)) % 40) + 15;
            arena = string(abi.encodePacked(
                arena,
                "<circle cx='", x.toString(), "' cy='", y.toString(), "' r='", r.toString(), "' fill='#ffffff' opacity='0.", op.toString(), "'/>"
            ));
        }
        return arena;
    }

    /**
     * @dev Chaos Flow: Visualizes move history using randomized Cubic Bezier curves.
     * Line weight and opacity scale as the game progresses (Crescendo effect).
     */
    function _generateGameFlow(uint16[] memory moves, uint256 seed) private pure returns (string memory) {
        string memory elements = "";
        uint256 total = moves.length;

        for (uint256 i = 0; i < total; i++) {
            uint256 moveHash = uint256(keccak256(abi.encodePacked(seed, i)));
            (uint256 x1, uint256 y1) = _sqToCoord((moves[i] >> 6) & 0x3F);
            (uint256 x2, uint256 y2) = _sqToCoord(moves[i] & 0x3F);

            // Control points calculated to swing wide across the canvas
            uint256 cx1 = (moveHash % 800) + ((x1 > 400) ? 0 : 200); 
            uint256 cy1 = ((moveHash >> 8) % 800) + ((y1 > 400) ? 0 : 200);
            uint256 cx2 = ((moveHash >> 16) % 800) + ((x2 > 400) ? 0 : 200);
            uint256 cy2 = ((moveHash >> 24) % 800) + ((y2 > 400) ? 0 : 200);

            uint256 prog = (i * 100) / total;
            uint256 thickness = (prog / 8) + 1 + (moveHash % 5); 
            uint256 opacity = 20 + (prog * 80 / 100) + (moveHash % 10); 
            
            string memory colorUrl = (prog < 30) ? "url(#earlyGrad)" : (prog < 70 ? "url(#midGrad)" : "url(#lateGrad)");

            elements = string(abi.encodePacked(
                elements,
                "<path d='M ", x1.toString(), " ", y1.toString(), " C ", cx1.toString(), " ", cy1.toString(), " ", cx2.toString(), " ", cy2.toString(), " ", x2.toString(), " ", y2.toString(), 
                "' fill='none' stroke='", colorUrl, "' stroke-width='", thickness.toString(), "' opacity='0.", opacity.toString(), "' filter='url(#glowLight)' style='mix-blend-mode: screen;'/>"
            ));

            uint256 r = 2 + (prog / 12) + (moveHash % 3);
            elements = string(abi.encodePacked(
                elements,
                "<circle cx='", x2.toString(), "' cy='", y2.toString(), "' r='", r.toString(), "' fill='#ffffff' opacity='0.", opacity.toString(), "' filter='url(#glowLight)'/>"
            ));
        }
        return elements;
    }

    /**
     * @dev Checkmate Nova: Dramatic explosion effect at the final move coordinates.
     * Generates randomized neon shards using chaotic seed values.
     */
    function _generateCheckmateNova(uint16 lastMove, uint256 seed) private pure returns (string memory) {
        (uint256 cx, uint256 cy) = _sqToCoord(lastMove & 0x3F);
        string memory nova = "";

        nova = string(abi.encodePacked(
            "<circle cx='", cx.toString(), "' cy='", cy.toString(), "' r='300' fill='url(#lateGrad)' filter='url(#glowHeavy)' opacity='0.3'/>",
            "<circle cx='", cx.toString(), "' cy='", cy.toString(), "' r='150' fill='none' stroke='#ffffff' stroke-width='4' stroke-dasharray='10,50' class='pulse'/>"
        ));

        // Chaos Fragment Explosion: 32 randomized polygonal shards
        for(uint i = 0; i < 32; i++) {
            uint256 shardHash = uint256(keccak256(abi.encodePacked(seed, i)));
            uint256 angle = (i * 360) / 32 + (shardHash % 25); 
            
            uint256 length = 200 + (shardHash % 280); 
            uint256 width = 12 + (shardHash % 35);    
            uint256 tipWidth = (shardHash % width) + 1; 

            string memory colorUrl = (shardHash % 2 == 0) ? "url(#lateGrad)" : "url(#midGrad)");

            // Safe subtraction logic to prevent uint256 underflow at canvas edges
            uint256 safeY1 = (cy > length / 2) ? cy - length / 2 : 0;
            uint256 safeY2 = (cy > length) ? cy - length : 0;
            uint256 safeX1 = (cx > tipWidth) ? cx - tipWidth : 0;

            string memory points = string(abi.encodePacked(
                cx.toString(), ",", cy.toString(), " ",
                (cx + width).toString(), ",", safeY1.toString(), " ",
                cx.toString(), ",", safeY2.toString(), " ",
                safeX1.toString(), ",", safeY1.toString()
            ));

            nova = string(abi.encodePacked(
                nova,
                "<polygon points='", points, 
                "' fill='", colorUrl, "' opacity='0.85' filter='url(#glowLight)' transform='rotate(", angle.toString(), " ", cx.toString(), " ", cy.toString(), ")'/>"
            ));
        }

        nova = string(abi.encodePacked(
            nova,
            "<circle cx='", cx.toString(), "' cy='", cy.toString(), "' r='60' fill='#ffffff' filter='url(#glowHeavy)' class='pulse'/>"
        ));

        return string(abi.encodePacked("<g style='mix-blend-mode: screen;'>", nova, "</g>"));
    }

    /**
     * @dev Maps chess square indices to 1024x1024 coordinate space.
     */
    function _sqToCoord(uint16 sq) private pure returns (uint256 x, uint256 y) {
        uint256 col = sq % 8;
        uint256 row = 7 - (sq / 8); 
        x = (col * 115) + 110; 
        y = (row * 115) + 110;
    }

    /**
     * @dev Main entry point for the on-chain SVG generation.
     */
    function render(
        uint16[] memory moves,
        uint256 /* totalMoves */, 
        uint256 captures,
        uint256 checks
    ) internal pure returns (string memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(moves, captures, checks)));

        return string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1024 1024' width='100%' height='100%'>",
                _generateDefs(),
                _generateMacroBackground(seed),
                _generateGlobalArena(seed),
                _generateGameFlow(moves, seed),
                _generateCheckmateNova(moves[moves.length - 1], seed),
                "</svg>"
            )
        );
    }
}