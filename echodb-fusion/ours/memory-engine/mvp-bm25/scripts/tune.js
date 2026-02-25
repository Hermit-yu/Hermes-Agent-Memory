#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const { main } = require("../src/cli");
const { loadProfile, saveProfile } = require("../src/profile");

function argValue(args, key, fallback = "") {
  const i = args.indexOf(key);
  return i === -1 ? fallback : args[i + 1] || fallback;
}
function hasFlag(args, key) { return args.includes(key); }

function runCli(argv) {
  const logs = [];
  const oldLog = console.log;
  const oldErr = console.error;
  console.log = (...args) => logs.push(args.join(" "));
  console.error = (...args) => logs.push(args.join(" "));
  try {
    const code = main(argv, path.join(__dirname, "../src"));
    return { code, text: logs.join("\n") };
  } finally {
    console.log = oldLog;
    console.error = oldErr;
  }
}

function parseJson(text) {
  const s = text.indexOf("{");
  const e = text.lastIndexOf("}");
  if (s < 0 || e <= s) return null;
  try { return JSON.parse(text.slice(s, e + 1)); } catch { return null; }
}

function readFeedback(workspaceRoot) {
  const file = path.join(workspaceRoot, "memory-echoDB/indexes/feedback-log.jsonl");
  if (!fs.existsSync(file)) return [];
  return fs.readFileSync(file, "utf8").split(/\r?\n/).filter(Boolean).map((line) => {
    try { return JSON.parse(line); } catch { return null; }
  }).filter(Boolean);
}

function evaluateConfig(dataset, conf, feedback = []) {
  const m = { evaluated: 0, hit: 0, top1: 0, top3: 0, skipTotal: 0, skipPass: 0, feedbackFit: 0, feedbackTotal: 0 };

  for (const item of dataset) {
    const args = ["node", "echodb", "memory", "search", item.query, "--topK", "5", "--json", "--mode", conf.mode, "--fusion", conf.fusion,
      "--bm25Weight", String(conf.bm25Weight), "--vectorWeight", String(conf.vectorWeight), "--halfLifeDays", String(conf.recencyHalfLifeDays)];
    if (conf.mmr) args.push("--mmr");
    if (item.scope) args.push("--scope", item.scope);
    const ret = runCli(args);
    const parsed = parseJson(ret.text) || {};

    if (item.shouldSkip) {
      m.skipTotal += 1;
      if (parsed.skipped) m.skipPass += 1;
      continue;
    }
    m.evaluated += 1;
    const expects = (item.expects || []).map((x) => String(x).toLowerCase());
    const lines = (parsed.results || []).map((r) => `${r.source || ""} ${r.preview || ""}`.toLowerCase());
    const t1 = lines[0] || "";
    const t3 = lines.slice(0, 3);
    if (expects.some((k) => lines.some((l) => l.includes(k)))) m.hit += 1;
    if (expects.some((k) => t1.includes(k))) m.top1 += 1;
    if (expects.some((k) => t3.some((l) => l.includes(k)))) m.top3 += 1;
  }

  for (const fb of feedback.slice(-80)) {
    const args = ["node", "echodb", "memory", "search", fb.query, "--topK", "5", "--json", "--mode", conf.mode, "--fusion", conf.fusion,
      "--bm25Weight", String(conf.bm25Weight), "--vectorWeight", String(conf.vectorWeight), "--halfLifeDays", String(conf.recencyHalfLifeDays)];
    if (conf.mmr) args.push("--mmr");
    if (fb.scope) args.push("--scope", fb.scope);
    const parsed = parseJson(runCli(args).text) || {};
    const ids = (parsed.results || []).map((x) => x.id);
    const pos = ids.indexOf(fb.id);
    m.feedbackTotal += 1;
    if (fb.label === "up" && pos >= 0 && pos < 3) m.feedbackFit += 1;
    if (fb.label === "down" && (pos === -1 || pos > 0)) m.feedbackFit += 1;
  }

  const top1Rate = m.top1 / Math.max(1, m.evaluated);
  const top3Rate = m.top3 / Math.max(1, m.evaluated);
  const hitRate = m.hit / Math.max(1, m.evaluated);
  const skipRate = m.skipPass / Math.max(1, m.skipTotal);
  const feedbackRate = m.feedbackFit / Math.max(1, m.feedbackTotal);
  const score = top1Rate * 0.45 + top3Rate * 0.35 + hitRate * 0.15 + skipRate * 0.03 + feedbackRate * 0.02;

  return {
    metrics: {
      top1Rate: Number(top1Rate.toFixed(4)),
      top3Rate: Number(top3Rate.toFixed(4)),
      hitRate: Number(hitRate.toFixed(4)),
      adaptiveSkipRate: Number(skipRate.toFixed(4)),
      feedbackFitRate: Number(feedbackRate.toFixed(4)),
    },
    score: Number(score.toFixed(6)),
  };
}

const args = process.argv.slice(2);
const workspaceRoot = path.resolve(__dirname, "../../../../..");
const datasetPath = argValue(args, "--dataset", path.join(__dirname, "../datasets/regression-zh.json"));
const apply = hasFlag(args, "--apply");
const dataset = JSON.parse(fs.readFileSync(datasetPath, "utf8"));
const feedback = readFeedback(workspaceRoot);

runCli(["node", "echodb", "memory", "reindex"]);

const grid = [];
for (const fusion of ["rrf", "weighted"]) {
  for (const bm25Weight of [0.4, 0.5, 0.6, 0.7]) {
    for (const mmr of [false, true]) {
      for (const recencyHalfLifeDays of [14, 30, 60]) {
        grid.push({ mode: "hybrid", fusion, bm25Weight, vectorWeight: Number((1 - bm25Weight).toFixed(2)), mmr, recencyHalfLifeDays });
      }
    }
  }
}

let best = null;
const leaderboard = [];
for (const conf of grid) {
  const result = evaluateConfig(dataset, conf, feedback);
  const row = { conf, ...result };
  leaderboard.push(row);
  if (!best || row.score > best.score) best = row;
}

leaderboard.sort((a, b) => b.score - a.score);
const output = {
  tunedAt: new Date().toISOString(),
  dataset: path.relative(workspaceRoot, datasetPath).replace(/\\/g, "/"),
  gridSize: grid.length,
  best,
  top5: leaderboard.slice(0, 5),
};

if (apply && best) {
  const old = loadProfile(workspaceRoot);
  const profile = {
    ...old,
    version: 1,
    updatedAt: new Date().toISOString(),
    source: "auto-tuned",
    retrieval: { ...old.retrieval, ...best.conf },
  };
  const p = saveProfile(workspaceRoot, profile);
  output.profileUpdated = p;
  output.profile = profile;
}

console.log("EchoDB Tune Report");
console.log(JSON.stringify(output, null, 2));
