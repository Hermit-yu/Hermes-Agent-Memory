"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");
const { buildBm25, searchBm25 } = require("./bm25");
const { buildVectorIndex, searchVector } = require("./vector");
const { shouldRetrieve, fuseResults, mmrSelect } = require("./retrieval");
const { loadProfile } = require("./profile");
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
  readTombstones,
  writeTombstones,
  appendAudit,
} = require("./memory-store");

const ALLOWED_SCOPES = new Set(["all", "global", "agent:main"]);

function printHelp() {
  console.log(`EchoDB MVP+ (BM25 + Vector + Hybrid)
Usage:
  echodb memory reindex [--disable-noise-filter]
  echodb memory search <query> [--topK 20] [--scope all|global|agent:main] [--mode hybrid|bm25|vector]
                      [--fusion rrf|weighted] [--bm25Weight 0.6] [--vectorWeight 0.4] [--halfLifeDays 30] [--force] [--json] [--mmr]
  echodb memory list [--scope ...] [--type ...] [--limit 20] [--json]
  echodb memory stats [--json]
  echodb memory export --out <file> [--scope ...] [--type ...]
  echodb memory forget --id <id>
  echodb memory regress [--dataset <file>]
  echodb memory tune [--dataset <file>] [--apply]
  echodb memory feedback --query "..." --id <id> --label up|down [--scope ...]
  echodb memory selflearn --once
`);
}

function argValue(args, key, fallback = undefined) {
  const i = args.findIndex((a) => a === key);
  if (i === -1) return fallback;
  return args[i + 1] ?? fallback;
}
function hasFlag(args, key) { return args.includes(key); }
function parseTopK(args) { return Math.max(1, Math.floor(Number(argValue(args, "--topK", argValue(args, "-k", 20))) || 20)); }
function parseLimit(args) { return Math.max(1, Math.floor(Number(argValue(args, "--limit", 20)) || 20)); }
function parseScope(args) {
  const value = (argValue(args, "--scope", "all") || "all").trim();
  if (!ALLOWED_SCOPES.has(value)) throw new Error(`Invalid --scope: ${value}. Allowed: all|global|agent:main`);
  return value;
}
function asJson(enabled, data, prettyFallback) {
  if (enabled) console.log(JSON.stringify(data, null, 2));
  else if (prettyFallback) prettyFallback();
}

function reindex(paths, args = []) {
  const items = normalizeMemoryItems(paths, { noiseFilter: !hasFlag(args, "--disable-noise-filter") });
  if (!items.length) {
    console.error("Reindex failed: no memory markdown found or all filtered as noise.");
    return 1;
  }
  const docs = readDocumentsFromItems(paths, { excludeForgotten: false });
  const bm25 = buildBm25(docs);
  const provider = process.env.ECHODB_EMBED_PROVIDER && process.env.ECHODB_EMBED_API_KEY ? process.env.ECHODB_EMBED_PROVIDER : "local-hash";
  const vector = buildVectorIndex(docs, { provider });
  saveIndex(paths.indexFile, bm25);
  saveIndex(paths.vectorIndexFile, vector);
  appendAudit(paths, "reindex", { docs: docs.length, provider });
  console.log(`Reindex done: memoryItems=${items.length}, docs=${docs.length}, bm25=${path.basename(paths.indexFile)}, vector=${path.basename(paths.vectorIndexFile)}, provider=${provider}`);
  return 0;
}

function filterScopeType(results, scope, type) {
  return results.filter((r) => (scope === "all" ? true : r.scope === scope) && (type ? r.type === type : true));
}

function getSearchParams(paths, args = []) {
  const profile = loadProfile(paths.workspaceRoot);
  return {
    topK: parseTopK(args),
    scope: parseScope(args),
    mode: (argValue(args, "--mode", profile.retrieval.mode) || "hybrid").toLowerCase(),
    fusion: (argValue(args, "--fusion", profile.retrieval.fusion) || "rrf").toLowerCase(),
    bm25Weight: Number(argValue(args, "--bm25Weight", profile.retrieval.bm25Weight)),
    vectorWeight: Number(argValue(args, "--vectorWeight", profile.retrieval.vectorWeight)),
    recencyHalfLifeDays: Number(argValue(args, "--halfLifeDays", profile.retrieval.recencyHalfLifeDays)),
    force: hasFlag(args, "--force"),
    json: hasFlag(args, "--json"),
    useMmr: hasFlag(args, "--mmr") || (!args.includes("--no-mmr") && !!profile.retrieval.mmr),
    profile,
  };
}

function search(paths, query, args = []) {
  const params = getSearchParams(paths, args);
  const { topK, scope, mode, fusion, bm25Weight, vectorWeight, recencyHalfLifeDays, force, json, useMmr } = params;

  const gate = shouldRetrieve(query, { forceRetrieve: force });
  if (!gate.retrieve) {
    return asJson(json, { query, skipped: true, reason: gate.reason, results: [] }, () => console.log(`Adaptive retrieval skipped: ${gate.reason}`)), 0;
  }

  let bm25 = loadIndex(paths.indexFile);
  let vector = loadIndex(paths.vectorIndexFile);
  if (!bm25 || !vector) {
    console.log("Index not complete, building now...");
    const code = reindex(paths, args);
    if (code) return code;
    bm25 = loadIndex(paths.indexFile);
    vector = loadIndex(paths.vectorIndexFile);
  }

  const tombstones = readTombstones(paths);
  let bResults = mode === "vector" ? [] : searchBm25(bm25, query, topK * 5).filter((x) => !tombstones.has(x.id));
  let vResults = mode === "bm25" ? [] : searchVector(vector, query, topK * 5).filter((x) => !tombstones.has(x.id));

  bResults = filterScopeType(bResults, scope);
  vResults = filterScopeType(vResults, scope);

  let results = mode === "bm25" ? bResults : mode === "vector" ? vResults : fuseResults({
    bm25: bResults,
    vector: vResults,
    strategy: fusion,
    bm25Weight,
    vectorWeight,
    recencyHalfLifeDays,
    topK: topK * 2,
  });
  if (mode !== "hybrid") results = results.map((r) => ({ ...r, finalScore: r.score, debug: { [mode]: r.score } }));
  if (useMmr) results = mmrSelect(results, 0.7, topK);
  results = results.slice(0, topK);

  const out = { query, mode, scope, fusion: mode === "hybrid" ? fusion : undefined, profileSource: params.profile.source, results: results.map((r) => ({
    id: r.id, score: Number((r.finalScore || r.score || 0).toFixed(6)), source: r.source, scope: r.scope, type: r.type, preview: r.preview, debug: r.debug,
  })) };

  asJson(json, out, () => {
    if (!results.length) return console.log(`No results for scope=${scope}.`);
    console.log(`Found ${results.length} result(s) (mode=${mode}, scope=${scope}, profile=${params.profile.source}):`);
    results.forEach((r, i) => {
      console.log(`\n#${i + 1} score=${(r.finalScore || r.score || 0).toFixed(4)} [scope=${r.scope}] ${r.source}`);
      console.log(`   id=${r.id}`);
      console.log(`   ${r.preview || ""}`);
      if (r.debug) console.log(`   debug=${JSON.stringify(r.debug)}`);
    });
  });
  return 0;
}

function listMemories(paths, args = []) {
  const scope = parseScope(args);
  const type = argValue(args, "--type", "").trim();
  const limit = parseLimit(args);
  const json = hasFlag(args, "--json");
  const tombstones = readTombstones(paths);
  const items = readMemoryItems(paths)
    .filter((x) => !tombstones.has(x.id))
    .filter((x) => (scope === "all" ? true : x.scope === scope))
    .filter((x) => (type ? x.type === type : true))
    .slice(0, limit)
    .map((x) => ({ id: x.id, title: x.title, scope: x.scope, type: x.type, sourcePath: x.sourcePath, createdAt: x.createdAt }));

  asJson(json, { total: items.length, items }, () => {
    if (!items.length) return console.log("No items.");
    items.forEach((x, i) => console.log(`#${i + 1} ${x.id} [${x.scope}/${x.type}] ${x.sourcePath}`));
  });
  return 0;
}

function stats(paths, args = []) {
  const json = hasFlag(args, "--json");
  const bm25 = loadIndex(paths.indexFile);
  const vector = loadIndex(paths.vectorIndexFile);
  if (!bm25) return console.error("Index not found. Run: echodb memory reindex"), 1;
  const docs = Array.isArray(bm25.docs) ? bm25.docs : [];
  const by = (k) => docs.reduce((m, d) => ((m[d[k] || "unknown"] = (m[d[k] || "unknown"] || 0) + 1), m), {});
  const tombstones = readTombstones(paths);
  const out = {
    docs: docs.length,
    terms: bm25.df ? Object.keys(bm25.df).length : 0,
    avgdl: Number((bm25.avgdl || 0).toFixed(2)),
    sources: new Set(docs.map((d) => d.source).filter(Boolean)).size,
    indexCreatedAt: bm25.createdAt,
    vectorIndexCreatedAt: vector?.createdAt || null,
    vectorProvider: vector?.provider || "local-hash",
    forgotten: tombstones.size,
    scopes: by("scope"),
    types: by("type"),
  };
  asJson(json, out, () => {
    console.log("EchoDB Memory Stats");
    Object.entries(out).forEach(([k, v]) => console.log(`${k}: ${typeof v === "object" ? JSON.stringify(v) : v}`));
  });
  return 0;
}

function exportMemories(paths, args = []) {
  const outFile = argValue(args, "--out", "");
  if (!outFile) return console.error("Error: export requires --out <file>"), 1;
  const scope = parseScope(args);
  const type = argValue(args, "--type", "").trim();
  const tombstones = readTombstones(paths);
  const data = readMemoryItems(paths).filter((x) => !tombstones.has(x.id)).filter((x) => (scope === "all" ? true : x.scope === scope)).filter((x) => (type ? x.type === type : true));
  const target = path.isAbsolute(outFile) ? outFile : path.join(paths.workspaceRoot, outFile);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, JSON.stringify({ exportedAt: new Date().toISOString(), count: data.length, items: data }, null, 2), "utf8");
  appendAudit(paths, "export", { out: path.relative(paths.workspaceRoot, target).replace(/\\/g, "/"), count: data.length });
  console.log(`Exported ${data.length} item(s) -> ${target}`);
  return 0;
}

function forget(paths, args = []) {
  const id = argValue(args, "--id", "").trim();
  if (!id) return console.error("Error: forget requires --id <id>"), 1;
  const exists = readMemoryItems(paths).some((x) => x.id === id);
  if (!exists) return console.error(`Error: id not found: ${id}`), 1;
  const tombstones = readTombstones(paths);
  tombstones.add(id);
  writeTombstones(paths, tombstones);
  appendAudit(paths, "forget", { id, tombstone: true });
  console.log(`Forgotten (tombstone): ${id}`);
  return 0;
}

function runRegression(paths, args = []) {
  const dataset = argValue(args, "--dataset", path.join(paths.workspaceRoot, "echodb-fusion/ours/memory-engine/mvp-bm25/datasets/regression-zh.json"));
  const script = path.join(paths.workspaceRoot, "echodb-fusion/ours/memory-engine/mvp-bm25/scripts/regression.js");
  if (!fs.existsSync(script) || !fs.existsSync(dataset)) return console.error("Regression assets missing."), 1;
  cp.execFileSync(process.execPath, [script, "--dataset", dataset], { stdio: "inherit" });
  return 0;
}

function runTune(paths, args = []) {
  const dataset = argValue(args, "--dataset", path.join(paths.workspaceRoot, "echodb-fusion/ours/memory-engine/mvp-bm25/datasets/regression-zh.json"));
  const script = path.join(paths.workspaceRoot, "echodb-fusion/ours/memory-engine/mvp-bm25/scripts/tune.js");
  if (!fs.existsSync(script) || !fs.existsSync(dataset)) return console.error("Tune assets missing."), 1;
  const cliArgs = [script, "--dataset", dataset, "--apply"];
  cp.execFileSync(process.execPath, cliArgs, { stdio: "inherit" });
  return 0;
}

function feedback(paths, args = []) {
  const query = argValue(args, "--query", "").trim();
  const id = argValue(args, "--id", "").trim();
  const label = argValue(args, "--label", "").trim().toLowerCase();
  const scope = parseScope(args);
  if (!query || !id || !["up", "down"].includes(label)) {
    console.error("Usage: echodb memory feedback --query \"...\" --id <id> --label up|down [--scope ...]");
    return 1;
  }
  fs.mkdirSync(paths.indexesDir, { recursive: true });
  const file = path.join(paths.indexesDir, "feedback-log.jsonl");
  const row = { ts: new Date().toISOString(), query, id, label, scope };
  fs.appendFileSync(file, `${JSON.stringify(row)}\n`, "utf8");
  appendAudit(paths, "feedback", { query, id, label, scope });
  console.log(`Feedback saved: ${label} id=${id}`);
  return 0;
}

function selflearn(paths, args = []) {
  if (!hasFlag(args, "--once")) {
    console.error("Usage: echodb memory selflearn --once");
    return 1;
  }
  const script = path.join(paths.workspaceRoot, "echodb-fusion/ours/memory-engine/mvp-bm25/scripts/selflearn.js");
  cp.execFileSync(process.execPath, [script], { stdio: "inherit" });
  return 0;
}

function main(argv, cliDir = __dirname) {
  const args = argv.slice(2);
  if (!args.length || args.includes("-h") || args.includes("--help")) return printHelp(), 0;

  const workspaceRoot = resolveWorkspaceRoot(cliDir);
  const paths = getMemoryPaths(workspaceRoot);
  const [scope, cmd, ...rest] = args;
  if (scope !== "memory") return printHelp(), 1;

  try {
    if (cmd === "reindex") return reindex(paths, rest);
    if (cmd === "search") {
      const takesValue = new Set(["--topK", "-k", "--scope", "--mode", "--fusion", "--bm25Weight", "--vectorWeight", "--halfLifeDays"]);
      const queryParts = [];
      for (let i = 0; i < rest.length; i++) {
        const t = rest[i];
        if (takesValue.has(t)) { i += 1; continue; }
        if (t.startsWith("--")) continue;
        queryParts.push(t);
      }
      const query = queryParts.join(" ").trim();
      if (!query) return console.error("Error: query is empty."), 1;
      return search(paths, query, rest);
    }
    if (cmd === "list") return listMemories(paths, rest);
    if (cmd === "stats") {
      if (!hasMemoryItemsFile(paths) || !hasIndexFile(paths.indexFile)) return console.error("Index missing. Run: echodb memory reindex"), 1;
      return stats(paths, rest);
    }
    if (cmd === "export") return exportMemories(paths, rest);
    if (cmd === "forget") return forget(paths, rest);
    if (cmd === "regress") return runRegression(paths, rest);
    if (cmd === "tune") return runTune(paths, rest);
    if (cmd === "feedback") return feedback(paths, rest);
    if (cmd === "selflearn") return selflearn(paths, rest);
    return printHelp(), 1;
  } catch (err) {
    console.error(`Error: ${err.message}`);
    return 1;
  }
}

module.exports = { main };
