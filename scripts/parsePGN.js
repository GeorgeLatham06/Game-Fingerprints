const fs = require("fs");
const path = require("path");
const { Chess } = require("chess.js");

// convert square like "e4" to number 0-63
// board is laid out a1=0, b1=1 ... h1=7, a2=8, etc
function squareToIndex(sq) {
  const file = sq.charCodeAt(0) - "a".charCodeAt(0);
  const rank = parseInt(sq[1]) - 1;
  return rank * 8 + file;
}

// how far did the piece move (manhattan distance)
function moveDistance(fromSq, toSq) {
  const f1 = fromSq.charCodeAt(0) - "a".charCodeAt(0);
  const r1 = parseInt(fromSq[1]) - 1;
  const f2 = toSq.charCodeAt(0) - "a".charCodeAt(0);
  const r2 = parseInt(toSq[1]) - 1;
  return Math.abs(r1 - r2) + Math.abs(f1 - f2);
}

// pack each move into 2 bytes so its cheap to store on chain
// byte 1: [from square (6 bits)][top 2 bits of to square]
// byte 2: [bottom 4 bits of to square][capture flag][check flag][00]
function encodeMoves(moves) {
  const buf = Buffer.alloc(moves.length * 2);

  for (let i = 0; i < moves.length; i++) {
    const m = moves[i];
    const from = squareToIndex(m.from);
    const to = squareToIndex(m.to);

    // chess.js uses 'c' for capture and 'e' for en passant
    const capture = (m.flags.includes("c") || m.flags.includes("e")) ? 1 : 0;
    // check/checkmate shows up in the san notation as + or #
    const check = (m.san.includes("+") || m.san.includes("#")) ? 1 : 0;

    const byte1 = (from << 2) | (to >> 4);
    const byte2 = ((to & 0x0f) << 4) | (capture << 3) | (check << 2);

    buf[i * 2] = byte1;
    buf[i * 2 + 1] = byte2;
  }

  return buf;
}

function main() {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.error("Usage: node scripts/parsePGN.js <path-to-pgn>");
    process.exit(1);
  }

  const pgnPath = path.resolve(args[0]);
  const pgn = fs.readFileSync(pgnPath, "utf-8");

  // chess.js does all the heavy lifting for parsing
  const chess = new Chess();
  chess.loadPgn(pgn);

  const moves = chess.history({ verbose: true });
  if (moves.length === 0) {
    console.error("no moves found in pgn file");
    process.exit(1);
  }

  const header = chess.header();
  const metadata = {
    white: header.White || "Unknown",
    black: header.Black || "Unknown",
    result: header.Result || "*",
    date: header.Date || "Unknown",
    event: header.Event || "Unknown",
    site: header.Site || "Unknown",
  };

  const encodedBytes = encodeMoves(moves);
  const hexBytes = "0x" + encodedBytes.toString("hex");

  // stats for the art engine later
  let captures = 0;
  let checks = 0;
  let totalDist = 0;
  let earlyCaptures = 0;

  for (let i = 0; i < moves.length; i++) {
    const m = moves[i];
    if (m.flags.includes("c") || m.flags.includes("e")) {
      captures++;
      if (i < 20) earlyCaptures++; // first 20 half-moves = opening
    }
    if (m.san.includes("+") || m.san.includes("#")) checks++;
    totalDist += moveDistance(m.from, m.to);
  }

  const output = {
    metadata,
    moveCount: moves.length,
    encodedBytes: hexBytes,
    byteLength: encodedBytes.length,
    stats: {
      totalMoves: moves.length,
      captureCount: captures,
      checkCount: checks,
      averageMoveDistance: Math.round((totalDist / moves.length) * 100) / 100,
      openingAggression: earlyCaptures,
    },
    moves: moves.map((m) => m.san),
  };

  console.log(JSON.stringify(output, null, 2));

  // save it so mint.js can use it later
  const outPath = path.join(path.dirname(pgnPath), "parsed_output.json");
  fs.writeFileSync(outPath, JSON.stringify(output, null, 2));
  console.error(`\nsaved to ${outPath}`);
}

main();
