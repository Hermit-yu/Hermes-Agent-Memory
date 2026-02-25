"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

function resolveWorkspaceRoot(cliDir) {
  // mvp-bm25/bin -> mvp-bm25 -> memory-engine -> ours -> echodb-fusion -> workspace
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
    memoryItemsFile: path.join(memoryRoot, "indexes", "memory-items.jsonl"),
  };
}

function ensureIndexesDir(paths) {
  fs.mkdirSync(paths.indexesDir, { recursive: true });
}

function toRelativeSource(workspaceRoot, filePath) {
  return path.relative(workspaceRoot, filePath).replace(/\\/g, "/");
}

function parseTitle(content, fallbackName) {
  const lines = (content || "").split(/\r?\n/);
  const h1 = lines.find((line) => /^\s*#\s+/.test(line));
  if (h1) return h1.replace(/^\s*#\s+/, "").trim();
  return fallbackName;
}

function inferCreatedAt(fileName, stat) {
  const m = /^(\d{4})-(\d{2})-(\d{2})\.md$/i.exec(fileName);
  if (m) {
    return new Date(`${m[1]}-${m[2]}-${m[3]}T00:00:00.000Z`).toISOString();
  }
  return stat.birthtime ? stat.birthtime.toISOString() : stat.mtime.toISOString();
}

function makeId(sourcePath, content) {
  return crypto
    .createHash("sha1")
    .update(`${sourcePath}\n${content || ""}`, "utf8")
    .digest("hex");
}

function collectMarkdownFiles(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  return fs
    .readdirSync(dirPath)
    .filter((f) => f.toLowerCase().endsWith(".md"))
    .sort()
    .map((f) => path.join(dirPath, f));
}

function normalizeMemoryItems(paths) {
  const files = [
    ...collectMarkdownFiles(paths.dailyDir),
    ...collectMarkdownFiles(paths.longTermDir),
  ];

  const items = files.map((fullPath) => {
    const stat = fs.statSync(fullPath);
    const fileName = path.basename(fullPath);
    const content = fs.readFileSync(fullPath, "utf8");
    const sourcePath = toRelativeSource(paths.workspaceRoot, fullPath);
    const isDaily = sourcePath.startsWith("memory-echoDB/daily/");

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

    if (updatedAt && updatedAt !== createdAt) {
      item.updatedAt = updatedAt;
    }

    return item;
  });

  ensureIndexesDir(paths);
  const jsonl = items.map((i) => JSON.stringify(i)).join("\n");
  fs.writeFileSync(paths.memoryItemsFile, jsonl ? `${jsonl}\n` : "", "utf8");
  return items;
}

function readMemoryItems(paths) {
  if (!fs.existsSync(paths.memoryItemsFile)) return [];
  const lines = fs
    .readFileSync(paths.memoryItemsFile, "utf8")
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean);

  return lines.map((line) => JSON.parse(line));
}

function readDocumentsFromItems(paths) {
  const items = readMemoryItems(paths);
  return items.map((item) => ({
    id: item.id,
    source: item.sourcePath,
    title: item.title,
    content: item.content,
  }));
}

function saveIndex(paths, index) {
  ensureIndexesDir(paths);
  fs.writeFileSync(paths.indexFile, JSON.stringify(index, null, 2), "utf8");
}

function loadIndex(paths) {
  if (!fs.existsSync(paths.indexFile)) return null;
  return JSON.parse(fs.readFileSync(paths.indexFile, "utf8"));
}

module.exports = {
  resolveWorkspaceRoot,
  getMemoryPaths,
  normalizeMemoryItems,
  readMemoryItems,
  readDocumentsFromItems,
  saveIndex,
  loadIndex,
};
