"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

function resolveWorkspaceRoot(cliDir) {
  return path.resolve(cliDir, "../../../../..");
}

function getMemoryPaths(workspaceRoot) {
  const memoryRoot = path.join(workspaceRoot, "memory-echoDB");
  return {
    workspaceRoot,
    memoryRoot,
    dailyDir: path.join(memoryRoot, "daily"),
    longTermDir: path.join(memoryRoot, "long-term"),
    indexesDir: path.join(memoryRoot, "indexes"),
    indexFile: path.join(memoryRoot, "indexes", "bm25-index.json"),
    vectorIndexFile: path.join(memoryRoot, "indexes", "vector-index.json"),
    memoryItemsFile: path.join(memoryRoot, "indexes", "memory-items.jsonl"),
    tombstoneFile: path.join(memoryRoot, "indexes", "forget-tombstones.json"),
    auditLogFile: path.join(memoryRoot, "indexes", "audit-log.jsonl"),
  };
}

function ensureIndexesDir(paths) { fs.mkdirSync(paths.indexesDir, { recursive: true }); }

function toRelativeSource(workspaceRoot, filePath) { return path.relative(workspaceRoot, filePath).replace(/\\/g, "/"); }

function parseTitle(content, fallbackName) {
  const h1 = (content || "").split(/\r?\n/).find((line) => /^\s*#\s+/.test(line));
  return h1 ? h1.replace(/^\s*#\s+/, "").trim() : fallbackName;
}

function inferCreatedAt(fileName, stat) {
  const m = /^(\d{4})-(\d{2})-(\d{2})\.md$/i.exec(fileName);
  if (m) return new Date(`${m[1]}-${m[2]}-${m[3]}T00:00:00.000Z`).toISOString();
  return stat.birthtime ? stat.birthtime.toISOString() : stat.mtime.toISOString();
}

function makeId(sourcePath, content) {
  return crypto.createHash("sha1").update(`${sourcePath}\n${content || ""}`, "utf8").digest("hex");
}

function collectMarkdownFiles(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  return fs.readdirSync(dirPath).filter((f) => f.toLowerCase().endsWith(".md")).sort().map((f) => path.join(dirPath, f));
}

function cleanContent(content, opts = {}) {
  if (opts.noiseFilter === false) return content || "";
  const noiseRules = opts.noiseRegex || [/^\s*[-*_]{3,}\s*$/gm, /^\s*(todo|tbd|占位|模板)\s*[:：]?.*$/gim, /^\s*$/gm];
  let out = String(content || "");
  noiseRules.forEach((r) => { out = out.replace(r, "\n"); });
  out = out.replace(/\n{3,}/g, "\n\n").trim();
  return out;
}

function normalizeMemoryItems(paths, options = {}) {
  const files = [...collectMarkdownFiles(paths.dailyDir), ...collectMarkdownFiles(paths.longTermDir)];
  const dedup = new Set();
  const items = [];

  for (const fullPath of files) {
    const stat = fs.statSync(fullPath);
    const fileName = path.basename(fullPath);
    const raw = fs.readFileSync(fullPath, "utf8");
    const content = cleanContent(raw, options);
    if (!content) continue;

    const sourcePath = toRelativeSource(paths.workspaceRoot, fullPath);
    const isDaily = sourcePath.startsWith("memory-echoDB/daily/");
    const key = crypto.createHash("sha1").update(content.slice(0, 2000), "utf8").digest("hex");
    if (dedup.has(key)) continue;
    dedup.add(key);

    const createdAt = inferCreatedAt(fileName, stat);
    const updatedAt = stat.mtime?.toISOString();
    const item = {
      id: makeId(sourcePath, content),
      scope: isDaily ? "agent:main" : "global",
      type: isDaily ? "daily-note" : "long-term-note",
      title: parseTitle(content, fileName),
      content,
      sourcePath,
      createdAt,
      importance: 0.5,
    };
    if (updatedAt && updatedAt !== createdAt) item.updatedAt = updatedAt;
    items.push(item);
  }

  ensureIndexesDir(paths);
  const jsonl = items.map((i) => JSON.stringify(i)).join("\n");
  fs.writeFileSync(paths.memoryItemsFile, jsonl ? `${jsonl}\n` : "", "utf8");
  return items;
}

function readMemoryItems(paths) {
  if (!fs.existsSync(paths.memoryItemsFile)) return [];
  return fs.readFileSync(paths.memoryItemsFile, "utf8").split(/\r?\n/).map((l) => l.trim()).filter(Boolean).map((line) => JSON.parse(line));
}

function readTombstones(paths) {
  if (!fs.existsSync(paths.tombstoneFile)) return new Set();
  const raw = JSON.parse(fs.readFileSync(paths.tombstoneFile, "utf8"));
  return new Set(Array.isArray(raw.ids) ? raw.ids : []);
}

function writeTombstones(paths, set) {
  ensureIndexesDir(paths);
  fs.writeFileSync(paths.tombstoneFile, JSON.stringify({ ids: [...set], updatedAt: new Date().toISOString() }, null, 2), "utf8");
}

function appendAudit(paths, action, payload) {
  ensureIndexesDir(paths);
  fs.appendFileSync(paths.auditLogFile, `${JSON.stringify({ ts: new Date().toISOString(), action, ...payload })}\n`, "utf8");
}

function readDocumentsFromItems(paths, options = {}) {
  const items = readMemoryItems(paths);
  const tombstones = readTombstones(paths);
  return items
    .filter((item) => !(options.excludeForgotten !== false && tombstones.has(item.id)))
    .map((item) => ({
      id: item.id,
      source: item.sourcePath,
      title: item.title,
      scope: item.scope || "unknown",
      type: item.type || "unknown",
      content: item.content,
      createdAt: item.createdAt,
    }));
}

function hasIndexFile(pathsOrFile) {
  if (typeof pathsOrFile === "string") return fs.existsSync(pathsOrFile);
  return fs.existsSync(pathsOrFile.indexFile);
}
function hasMemoryItemsFile(paths) { return fs.existsSync(paths.memoryItemsFile); }

function saveIndex(file, index) { fs.writeFileSync(file, JSON.stringify(index, null, 2), "utf8"); }
function loadIndex(file) { if (!fs.existsSync(file)) return null; return JSON.parse(fs.readFileSync(file, "utf8")); }

module.exports = {
  resolveWorkspaceRoot,
  getMemoryPaths,
  normalizeMemoryItems,
  readMemoryItems,
  readDocumentsFromItems,
  hasIndexFile,
  hasMemoryItemsFile,
  saveIndex,
  loadIndex,
  readTombstones,
  writeTombstones,
  appendAudit,
};
