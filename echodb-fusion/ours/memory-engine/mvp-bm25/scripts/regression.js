#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const { main } = require("../src/cli");

function argValue(args, key, fallback = "") {
  const i = args.indexOf(key);
  return i === -1 ? fallback : args[i + 1] || fallback;
}

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

function parseJsonFromText(text) {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  try { return JSON.parse(text.slice(start, end + 1)); } catch { return null; }
}

function ensureArray(v) { return Array.isArray(v) ? v : []; }

const datasetPath = argValue(process.argv.slice(2), "--dataset", path.join(__dirname, "../datasets/regression-zh.json"));
const dataset = JSON.parse(fs.readFileSync(datasetPath, "utf8"));
const workspaceRoot = path.resolve(__dirname, "../../../../..");
const reportPath = path.join(workspaceRoot, "memory-echoDB/indexes/regression-report.json");

runCli(["node", "echodb", "memory", "reindex"]);

const metrics = {
  total: dataset.length,
  evaluated: 0,
  hit: 0,
  top1: 0,
  top3: 0,
  skipTotal: 0,
  skipPass: 0,
};
const byType = {};

function touchType(type) {
  const k = type || "unknown";
  if (!byType[k]) byType[k] = { total: 0, evaluated: 0, hit: 0, top1: 0, top3: 0, skipTotal: 0, skipPass: 0 };
  return byType[k];
}

for (const item of dataset) {
  const typeStat = touchType(item.type || "unknown");
  typeStat.total += 1;

  const args = ["node", "echodb", "memory", "search", item.query, "--topK", "5", "--json"];
  if (item.scope) args.push("--scope", item.scope);
  const ret = runCli(args);
  const parsed = parseJsonFromText(ret.text) || {};

  if (item.shouldSkip) {
    metrics.skipTotal += 1;
    typeStat.skipTotal += 1;
    if (parsed.skipped) {
      metrics.skipPass += 1;
      typeStat.skipPass += 1;
    }
    continue;
  }

  metrics.evaluated += 1;
  typeStat.evaluated += 1;
  const expects = ensureArray(item.expects).map((x) => String(x).toLowerCase());
  const results = ensureArray(parsed.results);
  const lines = results.map((r) => `${r.source || ""} ${r.preview || ""}`.toLowerCase());
  const top1Line = lines[0] || "";
  const top3Lines = lines.slice(0, 3);

  const hit = expects.some((k) => lines.some((line) => line.includes(k)));
  const top1 = expects.some((k) => top1Line.includes(k));
  const top3 = expects.some((k) => top3Lines.some((line) => line.includes(k)));

  if (hit) { metrics.hit += 1; typeStat.hit += 1; }
  if (top1) { metrics.top1 += 1; typeStat.top1 += 1; }
  if (top3) { metrics.top3 += 1; typeStat.top3 += 1; }
}

const report = {
  generatedAt: new Date().toISOString(),
  dataset: path.relative(workspaceRoot, datasetPath).replace(/\\/g, "/"),
  total: metrics.total,
  evaluated: metrics.evaluated,
  hitRate: Number((metrics.hit / Math.max(1, metrics.evaluated)).toFixed(4)),
  top1Rate: Number((metrics.top1 / Math.max(1, metrics.evaluated)).toFixed(4)),
  top3Rate: Number((metrics.top3 / Math.max(1, metrics.evaluated)).toFixed(4)),
  adaptiveSkipPass: {
    passed: metrics.skipPass,
    total: metrics.skipTotal,
    rate: Number((metrics.skipPass / Math.max(1, metrics.skipTotal)).toFixed(4)),
  },
  byType: Object.fromEntries(Object.entries(byType).map(([k, v]) => [k, {
    total: v.total,
    evaluated: v.evaluated,
    hitRate: Number((v.hit / Math.max(1, v.evaluated)).toFixed(4)),
    top1Rate: Number((v.top1 / Math.max(1, v.evaluated)).toFixed(4)),
    top3Rate: Number((v.top3 / Math.max(1, v.evaluated)).toFixed(4)),
    adaptiveSkipPass: `${v.skipPass}/${v.skipTotal}`,
  }])),
};

fs.mkdirSync(path.dirname(reportPath), { recursive: true });
fs.writeFileSync(reportPath, JSON.stringify(report, null, 2), "utf8");

console.log("EchoDB Regression Report");
console.log(JSON.stringify(report, null, 2));
console.log(`Saved machine-readable report -> ${reportPath}`);
