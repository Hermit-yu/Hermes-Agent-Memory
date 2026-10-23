"use strict";

const fs = require("fs");
const path = require("path");

const DEFAULT_PROFILE = {
  version: 1,
  updatedAt: null,
  source: "default",
  retrieval: {
    mode: "hybrid",
    fusion: "rrf",
    bm25Weight: 0.6,
    vectorWeight: 0.4,
    mmr: false,
    recencyHalfLifeDays: 30,
  },
};

function profilePath(workspaceRoot) {
  return path.join(workspaceRoot, "echodb-fusion/ours/memory-engine/mvp-bm25/config/retrieval-profile.json");
}

function loadProfile(workspaceRoot) {
  const file = profilePath(workspaceRoot);
  if (!fs.existsSync(file)) return { ...DEFAULT_PROFILE };
  try {
    const parsed = JSON.parse(fs.readFileSync(file, "utf8"));
    return {
      ...DEFAULT_PROFILE,
      ...parsed,
      retrieval: { ...DEFAULT_PROFILE.retrieval, ...(parsed.retrieval || {}) },
    };
  } catch {
    return { ...DEFAULT_PROFILE };
  }
}

function saveProfile(workspaceRoot, profile) {
  const file = profilePath(workspaceRoot);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(profile, null, 2), "utf8");
  return file;
}

module.exports = { DEFAULT_PROFILE, profilePath, loadProfile, saveProfile };
