// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Strings.sol";
import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/FixedPointMathLib.sol";

/**
 * @title SVGRenderer
 * @dev Generates fully on-chain, dynamic SVG artifacts for the Game Fingerprints project.
 * Utilizes Solady's DynamicBuffer and FixedPointMath to bypass EVM stack and gas limits.
 */
library SVGRenderer {
    using Strings for uint256;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    // @dev Stack-safe variables for path rendering to prevent EVM limits.
    struct PathVars {
        uint256 x1; uint256 y1; uint256 x2; uint256 y2;
        uint256 cx1; uint256 cy1; uint256 cx2; uint256 cy2;
        uint256 thickness; uint256 opacity; string colorUrl;
    }

    struct ShardVars {
        uint256 angle; uint256 length; uint256 width;
        uint256 safeY1; uint256 safeY2; uint256 safeX1;
    }

    // @dev Centralized configuration for dynamic themes, animations, and typography.
    struct RenderConfig {
        string bgHex; string cF1; string cF2; string cC1; string cC2;
        uint256 rotDur; uint256 pulseDur; uint256 anchorScale;
        uint256 theme; uint256 glyphType; uint256 forkIntens;
        string narrativeText; 
    }

    /**
     * @dev Builds dynamic parameters based on the game seed and current block timestamp.
     */
    function _buildConfig(uint256 seed) private view returns (RenderConfig memory cfg) {
        uint256 timeSeed = uint256(keccak256(abi.encodePacked(seed, block.timestamp)));
        
        cfg.theme = timeSeed % 4;
        
        if (cfg.theme == 0) { 
            // Theme 0: Cyberpunk Neon
            cfg.bgHex = "#04060d"; cfg.cF1 = "#00f2fe"; cfg.cF2 = "#4facfe"; cfg.cC1 = "#ff0844"; cfg.cC2 = "#ffb199"; 
        } else if (cfg.theme == 1) { 
            // Theme 1: Royal Renaissance
            cfg.bgHex = "#050510"; cfg.cF1 = "#cfb53b"; cfg.cF2 = "#ffdf73"; cfg.cC1 = "#e63946"; cfg.cC2 = "#a8dadc"; 
        } else if (cfg.theme == 2) { 
            // Theme 2: Monochrome Grind
            cfg.bgHex = "#111111"; cfg.cF1 = "#ffffff"; cfg.cF2 = "#cccccc"; cfg.cC1 = "#888888"; cfg.cC2 = "#444444"; 
        } else { 
            // Theme 3: Abyssal
            cfg.bgHex = "#001b2e"; cfg.cF1 = "#2980b9"; cfg.cF2 = "#6dd5fa"; cfg.cC1 = "#ff7e5f"; cfg.cC2 = "#feb47b"; 
        }

        cfg.rotDur = 10 + (timeSeed % 30); 
        cfg.pulseDur = 2 + (timeSeed % 5); 
        cfg.anchorScale = 10 + (timeSeed % 25); 
        cfg.forkIntens = 30 + (timeSeed % 60);  
        cfg.glyphType = (timeSeed >> 8) % 3;
        
        uint256 textType = (timeSeed >> 16) % 3;
        if(textType == 0) cfg.narrativeText = "MACHINE VICTORY : HUMAN BEWILDERMENT";
        else if(textType == 1) cfg.narrativeText = "SYSTEM OVERRIDE : CALCULATED SACRIFICE";
        else cfg.narrativeText = "INEVITABLE COLLAPSE : THE FINAL ALGORITHM";

        return cfg;
    }

    function _generateDefs(DynamicBufferLib.DynamicBuffer memory buffer, RenderConfig memory cfg) private pure {
        buffer.p(bytes("<defs><filter id='glowHeavy' x='-50%' y='-50%' width='200%' height='200%'><feGaussianBlur stdDeviation='12' result='blur'/><feComposite in='SourceGraphic' in2='blur' operator='over'/></filter>"));
        buffer.p(bytes("<filter id='glowLight'><feGaussianBlur stdDeviation='3' result='blur'/><feMerge><feMergeNode in='blur'/><feMergeNode in='SourceGraphic'/></feMerge></filter>"));
        buffer.p(bytes("<filter id='noiseSharp'><feTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/></filter>"));
        buffer.p(bytes("<pattern id='gridSolid' width='60' height='60' patternUnits='userSpaceOnUse'><path d='M 60 0 L 0 0 0 60' fill='none' stroke='#ffffff' stroke-width='0.5' opacity='0.15'/></pattern>"));
        
        buffer.p(abi.encodePacked("<linearGradient id='gradFlow' x1='0%' y1='0%' x2='100%' y2='100%'><stop offset='0%' stop-color='", cfg.cF1, "'/><stop offset='100%' stop-color='", cfg.cF2, "'/></linearGradient>"));
        buffer.p(abi.encodePacked("<linearGradient id='gradClash' x1='0%' y1='100%' x2='100%' y2='0%'><stop offset='0%' stop-color='", cfg.cC1, "'/><stop offset='100%' stop-color='", cfg.cC2, "'/></linearGradient>"));

        if (cfg.glyphType == 0) {
            buffer.p(bytes("<g id='gl1'><polygon points='0,-8 8,0 0,8 -8,0' fill='none' stroke='#fff' stroke-width='1.5'/></g>"));
            buffer.p(bytes("<g id='gl2'><path d='M -5,-5 L 5,5 M 5,-5 L -5,5' stroke='#fff' stroke-width='1.5'/></g>"));
        } else if (cfg.glyphType == 1) {
            buffer.p(bytes("<g id='gl1'><circle cx='0' cy='0' r='6' fill='none' stroke='#fff' stroke-width='1.5'/><circle cx='0' cy='0' r='2' fill='#fff'/></g>"));
            buffer.p(bytes("<g id='gl2'><polygon points='0,-8 7,4 -7,4' fill='none' stroke='#fff' stroke-width='1.5'/></g>"));
        } else {
            buffer.p(bytes("<g id='gl1'><path d='M -4,-8 L 4,-8 L 4,8 L -4,8' fill='none' stroke='#fff' stroke-width='1.5'/></g>"));
            buffer.p(bytes("<g id='gl2'><path d='M -6,0 Q 0,-8 6,0 Q 0,8 -6,0' fill='none' stroke='#fff' stroke-width='1.5'/></g>"));
        }
        buffer.p(bytes("</defs>"));
    }

    /**
     * @dev Renders the ambient background, including dynamic bokeh effects and tile corruption.
     */
    function _renderOpeningBackground(DynamicBufferLib.DynamicBuffer memory buffer, uint16[] memory moves, uint256 seed, RenderConfig memory cfg) private pure {
        uint256 openingHash = moves.length > 3 ? uint256(keccak256(abi.encodePacked(moves[0], moves[1], moves[2]))) : seed;
        buffer.p(abi.encodePacked("<rect width='1024' height='1024' fill='", cfg.bgHex, "'/>"));

        for(uint i=0; i<12; i++) {
            uint256 bx = (seed >> (i*2)) % 1024;
            uint256 by = (seed >> (i*2+1)) % 1024;
            uint256 br = 50 + (seed % 250);
            string memory bColor = i % 2 == 0 ? "url(#gradFlow)" : "url(#gradClash)";
            buffer.p(abi.encodePacked("<circle cx='", bx.toString(), "' cy='", by.toString(), "' r='", br.toString(), "' fill='", bColor, "' opacity='0.03'/>"));
        }

        if (openingHash % 2 == 0) { buffer.p(bytes("<rect width='1024' height='1024' fill='url(#gridSolid)'/>")); } 
        else { buffer.p(bytes("<rect width='1024' height='1024' filter='url(#noiseSharp)' opacity='0.08' style='mix-blend-mode: overlay;'/>")); }
    }

    /**
     * @dev Renders an individual game move as a curved path with trailing sketch effects.
     */
    function _renderSinglePath(DynamicBufferLib.DynamicBuffer memory buffer, uint16 move, uint256 i, uint256 total, uint256 seed, uint256[4] memory hotspots, RenderConfig memory cfg) private pure {
        PathVars memory v; 
        uint256 moveHash = uint256(keccak256(abi.encodePacked(seed, i)));
        
        /*
        (v.x1, v.y1) = _sqToCoord((move >> 6) & 0x3F);
        (v.x2, v.y2) = _sqToCoord(move & 0x3F);
        */

        (v.x1, v.y1) = _sqToCoord((move >> 10) & 0x3F);
        (v.x2, v.y2) = _sqToCoord((move >> 4) & 0x3F);

        {
            uint256 dx = v.x1 > v.x2 ? v.x1 - v.x2 : v.x2 - v.x1;
            uint256 dy = v.y1 > v.y2 ? v.y1 - v.y2 : v.y2 - v.y1;
            v.thickness = (FixedPointMathLib.sqrt((dx * dx) + (dy * dy)) / 50) + 1; 
        }

        uint256 warpPull = cfg.anchorScale * 2;
        v.cx1 = (i % 2 == 0) ? hotspots[0] : hotspots[2] + (moveHash % warpPull);
        v.cy1 = (i % 2 == 0) ? hotspots[1] : hotspots[3] - (moveHash % warpPull);
        v.cx2 = ((v.x1 + v.x2) / 2) + (moveHash % 120); 
        v.cy2 = ((v.y1 + v.y2) / 2) + ((moveHash >> 8) % 120);

        v.colorUrl = (i < total / 2) ? "url(#gradFlow)" : "url(#gradClash)";
        v.opacity = 20 + ((i * 80) / total);

        buffer.p(abi.encodePacked("<path d='M ", v.x1.toString(), " ", v.y1.toString(), " C ", v.cx1.toString()));
        buffer.p(abi.encodePacked(" ", v.cy1.toString(), " ", v.cx2.toString(), " ", v.cy2.toString(), " ", v.x2.toString()));
        buffer.p(abi.encodePacked(" ", v.y2.toString(), "' fill='none' stroke='", v.colorUrl, "' stroke-width='"));
        buffer.p(abi.encodePacked(v.thickness.toString(), "' opacity='0.", v.opacity.toString(), "' filter='url(#glowLight)' style='mix-blend-mode: screen;'/>"));

        buffer.p(abi.encodePacked("<path d='M ", (v.x1+10).toString(), " ", (v.y1+10).toString(), " C ", v.cx1.toString()));
        buffer.p(abi.encodePacked(" ", v.cy1.toString(), " ", v.cx2.toString(), " ", v.cy2.toString(), " ", (v.x2+10).toString()));
        buffer.p(abi.encodePacked(" ", (v.y2+10).toString(), "' fill='none' stroke='#ffffff' stroke-width='0.5' stroke-dasharray='2,6' opacity='0.3'/>"));

        buffer.p(abi.encodePacked("<circle cx='", v.cx2.toString(), "' cy='", v.cy2.toString(), "' r='1.5' fill='#ffffff' opacity='0.5'/>"));
    }

    /**
     * @dev Iterates through all moves to build the complete flow field and pulsing hotspots.
     */
    function _renderGameFlow(DynamicBufferLib.DynamicBuffer memory buffer, uint16[] memory moves, uint256 seed, RenderConfig memory cfg) private pure {
        uint256 total = moves.length;
        uint256[4] memory hotspots = [(seed % 600) + 200, ((seed >> 8) % 600) + 200, ((seed >> 16) % 600) + 200, ((seed >> 24) % 600) + 200];

        buffer.p(abi.encodePacked("<circle cx='", hotspots[0].toString(), "' cy='", hotspots[1].toString(), "' r='200' fill='url(#gradClash)' filter='url(#glowHeavy)'>"));
        buffer.p(abi.encodePacked("<animate attributeName='opacity' values='0.05;0.18;0.05' dur='", cfg.pulseDur.toString(), "s' repeatCount='indefinite'/></circle>"));
        
        buffer.p(abi.encodePacked("<circle cx='", hotspots[2].toString(), "' cy='", hotspots[3].toString(), "' r='150' fill='url(#gradFlow)' filter='url(#glowHeavy)'>"));
        buffer.p(abi.encodePacked("<animate attributeName='opacity' values='0.05;0.22;0.05' dur='", (cfg.pulseDur + 1).toString(), "s' repeatCount='indefinite'/></circle>"));

        for (uint256 i = 0; i < total - 1; i++) { _renderSinglePath(buffer, moves[i], i, total, seed, hotspots, cfg); }
    }

    /**
     * @dev Creates tactical anchors (representing pins/forks) and stamps glyphs onto the board.
     */
    function _renderSingleAnchor(DynamicBufferLib.DynamicBuffer memory buffer, uint256 seed, uint256 i, RenderConfig memory cfg) private pure {
        uint256 ax = (seed >> (i * 2)) % 900 + 50;
        uint256 ay = (seed >> (i * 2 + 1)) % 900 + 50;
        uint256 size = cfg.anchorScale + (seed % 10); 

        // Safe subtraction to prevent underflow errors at canvas edges.
        uint256 safeAx = ax > size ? ax - size : 0;
        uint256 f1 = cfg.forkIntens; uint256 f2 = cfg.forkIntens * 2;
        uint256 safeAy = ay > f1 ? ay - f1 : 0;

        buffer.p(abi.encodePacked("<polygon points='", ax.toString(), ",", ay.toString(), " ", (ax + size).toString()));
        buffer.p(abi.encodePacked(",", (ay + size * 2).toString(), " ", safeAx.toString(), ",", (ay + size * 2).toString()));
        buffer.p(bytes("' fill='none' stroke='#ffffff' stroke-width='1.5' opacity='0.3' filter='url(#glowLight)'/>"));
        
        buffer.p(abi.encodePacked("<path d='M ", ax.toString(), " ", ay.toString(), " Q ", (ax+f1).toString(), " ", safeAy.toString(), " ", (ax+f2).toString(), " ", ay.toString()));
        buffer.p(bytes("' fill='none' stroke='url(#gradFlow)' stroke-width='1' stroke-dasharray='4,6' opacity='0.5'/>"));

        string memory glyphId = i % 2 == 0 ? "#gl1" : "#gl2";
        buffer.p(abi.encodePacked("<use href='", glyphId, "' x='", ax.toString(), "' y='", ay.toString(), "' filter='url(#glowLight)'/>"));
    }

    function _renderPositionalAnchors(DynamicBufferLib.DynamicBuffer memory buffer, uint256 captures, uint256 checks, uint256 seed, RenderConfig memory cfg) private pure {
        uint256 totalAnchors = (captures + checks) % 8 + 3;
        for(uint i = 0; i < totalAnchors; i++) { _renderSingleAnchor(buffer, seed, i, cfg); }
    }

    function _renderSingleShard(DynamicBufferLib.DynamicBuffer memory buffer, uint256 seed, uint256 i, uint256 cx, uint256 cy) private pure {
        ShardVars memory v;
        uint256 shardHash = uint256(keccak256(abi.encodePacked(seed, i)));
        
        v.angle = (i * 360) / 24 + (shardHash % 25); v.length = 150 + (shardHash % 300); v.width = 8 + (shardHash % 25);    
        v.safeY1 = (cy > v.length / 2) ? cy - v.length / 2 : 0; v.safeY2 = (cy > v.length) ? cy - v.length : 0; v.safeX1 = (cx > v.width) ? cx - v.width : 0;

        buffer.p(abi.encodePacked("<polygon points='", cx.toString(), ",", cy.toString(), " ", (cx + v.width).toString()));
        buffer.p(abi.encodePacked(",", v.safeY1.toString(), " ", cx.toString(), ",", v.safeY2.toString(), " ", v.safeX1.toString()));
        buffer.p(abi.encodePacked(",", v.safeY1.toString(), "' fill='url(#gradClash)' opacity='0.8' filter='url(#glowLight)' transform='rotate("));
        buffer.p(abi.encodePacked(v.angle.toString(), " ", cx.toString(), " ", cy.toString(), ")'/>"));
    }

    /**
     * @dev Renders the final endgame blast, rotating shards, and narrative text.
     */
    function _renderCheckmateNarrative(DynamicBufferLib.DynamicBuffer memory buffer, uint16 lastMove, uint256 seed, RenderConfig memory cfg) private pure {
        (uint256 cx, uint256 cy) = _sqToCoord(lastMove & 0x3F);

        buffer.p(abi.encodePacked("<text x='", (cx > 150 ? cx - 150 : 0).toString(), "' y='", (cy > 100 ? cy - 100 : 0).toString()));
        buffer.p(abi.encodePacked("' fill='#ffffff' opacity='0.6' font-family='monospace' font-size='22' font-weight='bold' letter-spacing='2' transform='rotate(-35 ", cx.toString(), " ", cy.toString(), ")'>"));
        buffer.p(abi.encodePacked(cfg.narrativeText, "</text>"));

        buffer.p(abi.encodePacked("<circle cx='", cx.toString(), "' cy='", cy.toString(), "' r='280' fill='url(#gradClash)' filter='url(#glowHeavy)' opacity='0.35'/>"));
        buffer.p(abi.encodePacked("<circle cx='", cx.toString(), "' cy='", cy.toString(), "' r='140' fill='none' stroke='#ffffff' stroke-width='2' stroke-dasharray='5,30'/>"));

        buffer.p(abi.encodePacked("<g style='mix-blend-mode: screen;'><animateTransform attributeName='transform' type='rotate' from='0 ", cx.toString(), " ", cy.toString()));
        buffer.p(abi.encodePacked("' to='360 ", cx.toString(), " ", cy.toString(), "' dur='", cfg.rotDur.toString(), "s' repeatCount='indefinite'/>"));
        
        for(uint i = 0; i < 24; i++) { _renderSingleShard(buffer, seed, i, cx, cy); }
        buffer.p(bytes("</g>"));
        
        buffer.p(abi.encodePacked("<circle cx='", cx.toString(), "' cy='", cy.toString(), "' r='45' fill='#ffffff' filter='url(#glowHeavy)'/>"));
    }

    /**
     * @dev Embeds a permanent, 1-of-1 digital signature using the block timestamp and an internal UID.
     */
    function _renderSignature(DynamicBufferLib.DynamicBuffer memory buffer, uint256 seed) private view {
        uint256 uid = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.number))) % 1000000;

        buffer.p(bytes("<text x='1000' y='1000' text-anchor='end' font-family='monospace' font-size='9' fill='#ffffff' opacity='0.3' letter-spacing='1'>"));
        buffer.p(bytes("ARTISANS: J.YOON x G.LATHAM x R.POLCHIN"));
        buffer.p(abi.encodePacked("  |  EPOCH: ", block.timestamp.toString(), "  |  BLK: ", block.number.toString()));
        buffer.p(abi.encodePacked("  |  UID: ", uid.toString(), "</text>"));
    }

    function _sqToCoord(uint16 sq) private pure returns (uint256 x, uint256 y) {
        uint256 col = sq % 8; uint256 row = 7 - (sq / 8); 
        x = (col * 128) + 48; y = (row * 128) + 48;
    }

    /**
     * @dev Main entry point. Assembles all layers into a single DynamicBuffer to minimize gas usage.
     */
    function render(uint16[] memory moves, uint256 /* totalMoves */, uint256 captures, uint256 checks, uint256 mintTimestamp) internal view returns (string memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(moves, captures, checks, mintTimestamp)));
        DynamicBufferLib.DynamicBuffer memory buffer;
        RenderConfig memory cfg = _buildConfig(seed);

        buffer.p(bytes("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1024 1024' width='100%' height='100%'>"));
        
        _generateDefs(buffer, cfg); 
        _renderOpeningBackground(buffer, moves, seed, cfg);
        _renderGameFlow(buffer, moves, seed, cfg);
        _renderPositionalAnchors(buffer, captures, checks, seed, cfg);
        _renderCheckmateNarrative(buffer, moves[moves.length - 1], seed, cfg);
        
        _renderSignature(buffer, seed);

        buffer.p(bytes("</svg>"));
        return string(buffer.data);
    }
}