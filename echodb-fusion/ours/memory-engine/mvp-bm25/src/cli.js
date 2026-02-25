"use strict";

const { buildBm25, searchBm25 } = require("./bm25");
const {
  resolveWorkspaceRoot,
  getMemoryPaths,
  normalizeMemoryItems,
  readDocumentsFromItems,
  readMemoryItems,
  hasIndexFile,
  hasMemoryItemsFile,
  saveIndex,
  loadIndex,
} = require("./memory-store");

const ALLOWED_SCOPES = new Set(["all", "global", "agent:main"]);

function printHelp() {
  console.log(`EchoDB MVP (BM25)

Usage:
  echodb memory reindex
  echodb memory search <query> [--topK 20] [--scope all|global|agent:main]
  echodb memory stats

Node invocation:
  node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory reindex
  node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory search "query" --topK 20 --scope all
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

function parseScope(args) {
  const i = args.findIndex((a) => a === "--scope");
  if (i === -1) return "all";
  const value = (args[i + 1] || "").trim();
  if (!value) return "all";
  if (!ALLOWED_SCOPES.has(value)) {
    throw new Error(`Invalid --scope value: ${value}. Allowed: all | global | agent:main`);
  }
  return value;
}

function reindex(paths) {
  const items = normalizeMemoryItems(paths);
  if (items.length === 0) {
    console.error("Reindex failed: no memory markdown found under memory-echoDB/daily or memory-echoDB/long-term.");
    console.error("Please add at least one .md file, then run: echodb memory reindex");
    return 1;
  }

  const docs = readDocumentsFromItems(paths);
  if (docs.length === 0) {
    console.error(`Reindex failed: ${paths.memoryItemsFile} is empty or unreadable.`);
    console.error("Please verify source markdown files and run: echodb memory reindex");
    return 1;
  }

  const index = buildBm25(docs);
  saveIndex(paths, index);
  console.log(
    `Reindex done: memoryItems=${items.length}, docs=${index.docs.length}, avgdl=${index.avgdl.toFixed(2)}, files=[${paths.memoryItemsFile}, ${paths.indexFile}]`
  );
  return 0;
}

function filterByScope(results, scope) {
  if (scope === "all") return results;
  return results.filter((r) => r.scope === scope);
}

function search(paths, query, topK, scope) {
  let index = loadIndex(paths);
  if (!index) {
    console.log("Index not found, building now...");
    const code = reindex(paths);
    if (code !== 0) return code;
    index = loadIndex(paths);
  }

  if (!index || !Array.isArray(index.docs) || index.docs.length === 0) {
    console.error("Search failed: index is missing or empty.");
    console.error("Please prepare memory markdown and run: echodb memory reindex");
    return 1;
  }

  const rawResults = searchBm25(index, query, topK * 3);
  const results = filterByScope(rawResults, scope).slice(0, topK);
  if (results.length === 0) {
    console.log(`No results for scope=${scope}.`);
    return 0;
  }

  console.log(`Found ${results.length} result(s) (scope=${scope}):`);
  results.forEach((r, idx) => {
    console.log(`\n#${idx + 1} score=${r.score.toFixed(4)}  [scope=${r.scope}]  ${r.source}`);
    console.log(`   ${r.preview}`);
  });
  return 0;
}

function countBy(docs, key, fallback = "unknown") {
  const grouped = {};
  for (const d of docs) {
    const name = d?.[key] || fallback;
    grouped[name] = (grouped[name] || 0) + 1;
  }
  return grouped;
}

function stats(paths) {
  if (!hasIndexFile(paths)) {
    console.error(`Index not found: ${paths.indexFile}`);
    console.error("Please run: echodb memory reindex");
    return 1;
  }

  const index = loadIndex(paths);
  if (!index) {
    console.error("Index file exists but cannot be parsed.");
    console.error("Please run: echodb memory reindex");
    return 1;
  }

  const docs = Array.isArray(index.docs) ? index.docs : [];
  const terms = index.df ? Object.keys(index.df).length : 0;
  const sources = new Set(docs.map((d) => d.source).filter(Boolean)).size;
  const scopes = countBy(docs, "scope");
  const types = countBy(docs, "type");

  console.log("EchoDB Memory Stats");
  console.log(`docs: ${docs.length}`);
  console.log(`terms: ${terms}`);
  console.log(`avgdl: ${(index.avgdl || 0).toFixed(2)}`);
  console.log(`sources: ${sources}`);
  console.log(`indexCreatedAt: ${index.createdAt || "unknown"}`);
  console.log(`scopes: ${JSON.stringify(scopes)}`);
  console.log(`types: ${JSON.stringify(types)}`);
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
    return reindex(paths);
  }

  if (cmd === "search") {
    const queryParts = [];
    for (let i = 0; i < rest.length; i++) {
      const token = rest[i];
      if (token === "--topK" || token === "-k" || token === "--scope") {
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
    let scopeFilter = "all";
    try {
      scopeFilter = parseScope(rest);
    } catch (err) {
      console.error(err.message);
      return 1;
    }
    return search(paths, query, topK, scopeFilter);
  }

  if (cmd === "stats") {
    if (!hasMemoryItemsFile(paths)) {
      console.error(`Memory items not found: ${paths.memoryItemsFile}`);
      console.error("Please run: echodb memory reindex");
      return 1;
    }
    const items = readMemoryItems(paths);
    if (items.length === 0) {
      console.error(`Memory items are empty: ${paths.memoryItemsFile}`);
      console.error("Please ensure source markdown exists, then run: echodb memory reindex");
      return 1;
    }
    return stats(paths);
  }

  printHelp();
  return 1;
}

module.exports = { main };
