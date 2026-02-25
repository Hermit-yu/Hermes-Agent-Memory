"use strict";

const fs = require("fs");
const path = require("path");

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
    longTermFile: path.join(memoryRoot, "long-term", "MEMORY.md"),
    indexesDir: path.join(memoryRoot, "indexes"),
    indexFile: path.join(memoryRoot, "indexes", "bm25-index.json"),
  };
}

function readDocuments(paths) {
  const docs = [];

  if (fs.existsSync(paths.dailyDir)) {
    const dailyFiles = fs
      .readdirSync(paths.dailyDir)
      .filter((f) => f.toLowerCase().endsWith(".md"))
      .sort();

    for (const file of dailyFiles) {
      const full = path.join(paths.dailyDir, file);
      const content = fs.readFileSync(full, "utf8");
      docs.push({
        id: `daily:${file}`,
        source: `memory-echoDB/daily/${file}`,
        title: file,
        content,
      });
    }
  }

  if (fs.existsSync(paths.longTermFile)) {
    const content = fs.readFileSync(paths.longTermFile, "utf8");
    docs.push({
      id: "long-term:MEMORY.md",
      source: "memory-echoDB/long-term/MEMORY.md",
      title: "MEMORY.md",
      content,
    });
  }

  return docs;
}

function ensureIndexesDir(paths) {
  fs.mkdirSync(paths.indexesDir, { recursive: true });
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
  readDocuments,
  saveIndex,
  loadIndex,
};
