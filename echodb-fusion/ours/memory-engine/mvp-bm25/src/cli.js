"use strict";

const { buildBm25, searchBm25 } = require("./bm25");
const {
  resolveWorkspaceRoot,
  getMemoryPaths,
  normalizeMemoryItems,
  readDocumentsFromItems,
  saveIndex,
  loadIndex,
} = require("./memory-store");

function printHelp() {
  console.log(`EchoDB MVP (BM25)

Usage:
  echodb memory reindex
  echodb memory search <query> [--topK 20]
  echodb memory stats

Node invocation:
  node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory reindex
  node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory search "query" --topK 20
  node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory stats
`);
}

function parseTopK(args) {
  const i = args.findIndex((a) => a === "--topK" || a === "-k");
  if (i === -1) return 20;
  const v = Number(args[i + 1]);
  if (!Number.isFinite(v) || v <= 0) return 20;
  return Math.floor(v);
}

function reindex(paths) {
  const items = normalizeMemoryItems(paths);
  const docs = readDocumentsFromItems(paths);
  const index = buildBm25(docs);
  saveIndex(paths, index);
  console.log(
    `Reindex done: memoryItems=${items.length}, docs=${index.docs.length}, avgdl=${index.avgdl.toFixed(2)}, files=[${paths.memoryItemsFile}, ${paths.indexFile}]`
  );
}

function search(paths, query, topK) {
  let index = loadIndex(paths);
  if (!index) {
    console.log("Index not found, building now...");
    reindex(paths);
    index = loadIndex(paths);
  }

  const results = searchBm25(index, query, topK);
  if (results.length === 0) {
    console.log("No results.");
    return;
  }

  console.log(`Found ${results.length} result(s):`);
  results.forEach((r, idx) => {
    console.log(`\n#${idx + 1} score=${r.score.toFixed(4)}  ${r.source}`);
    console.log(`   ${r.preview}`);
  });
}

function stats(paths) {
  const index = loadIndex(paths);
  if (!index) {
    console.error("Index not found. Please run: echodb memory reindex");
    return 1;
  }

  const docs = Array.isArray(index.docs) ? index.docs : [];
  const terms = index.df ? Object.keys(index.df).length : 0;
  const sources = new Set(docs.map((d) => d.source).filter(Boolean)).size;

  console.log("EchoDB Memory Stats");
  console.log(`docs: ${docs.length}`);
  console.log(`terms: ${terms}`);
  console.log(`avgdl: ${(index.avgdl || 0).toFixed(2)}`);
  console.log(`sources: ${sources}`);
  console.log(`indexCreatedAt: ${index.createdAt || "unknown"}`);
  return 0;
}

function main(argv, cliDir = __dirname) {
  const args = argv.slice(2);
  if (args.length === 0 || args.includes("-h") || args.includes("--help")) {
    printHelp();
    return 0;
  }

  const workspaceRoot = resolveWorkspaceRoot(cliDir);
  const paths = getMemoryPaths(workspaceRoot);

  const [scope, cmd, ...rest] = args;
  if (scope !== "memory") {
    printHelp();
    return 1;
  }

  if (cmd === "reindex") {
    reindex(paths);
    return 0;
  }

  if (cmd === "search") {
    const queryParts = [];
    for (let i = 0; i < rest.length; i++) {
      const token = rest[i];
      if (token === "--topK" || token === "-k") {
        i += 1;
        continue;
      }
      queryParts.push(token);
    }

    const query = queryParts.join(" ").trim();
    if (!query) {
      console.error("Error: query is empty.");
      return 1;
    }

    const topK = parseTopK(rest);
    search(paths, query, topK);
    return 0;
  }

  if (cmd === "stats") {
    return stats(paths);
  }

  printHelp();
  return 1;
}

module.exports = { main };
