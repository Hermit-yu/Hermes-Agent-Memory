#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const { main } = require("../src/cli");

function runCli(argv) {
  const logs = [];
  const old = console.log;
  console.log = (...args) => logs.push(args.join(" "));
  try {
    const code = main(argv, path.join(__dirname, "../src"));
    return { code, text: logs.join("\n") };
  } finally {
    console.log = old;
  }
}

function argValue(args, key, fallback = "") {
  const i = args.indexOf(key);
  return i === -1 ? fallback : args[i + 1] || fallback;
}

const datasetPath = argValue(process.argv.slice(2), "--dataset", path.join(__dirname, "../datasets/regression-zh.json"));
const dataset = JSON.parse(fs.readFileSync(datasetPath, "utf8"));

runCli(["node", "echodb", "memory", "reindex"]);

let total = 0;
let hit = 0;
let top1 = 0;
let skippedOk = 0;

for (const item of dataset) {
  total++;
  const ret = runCli(["node", "echodb", "memory", "search", item.query, "--topK", "5", "--json"]);
  let parsed = {};
  try {
    const start = ret.text.indexOf("{");
    const end = ret.text.lastIndexOf("}");
    parsed = start >= 0 && end > start ? JSON.parse(ret.text.slice(start, end + 1)) : {};
  } catch {
    parsed = {};
  }
  if (item.shouldSkip) {
    if (parsed.skipped) skippedOk++;
    continue;
  }
  const results = parsed.results || [];
  const joined = results.map((r) => `${r.source || ""} ${r.preview || ""}`.toLowerCase());
  const ok = item.expects.some((k) => joined.some((line) => line.includes(String(k).toLowerCase())));
  if (ok) hit++;
  const top = joined[0] || "";
  if (item.expects.some((k) => top.includes(String(k).toLowerCase()))) top1++;
}

const report = {
  totalQueries: total,
  evaluatedQueries: total - dataset.filter((x) => x.shouldSkip).length,
  hitRate: Number((hit / Math.max(1, total - dataset.filter((x) => x.shouldSkip).length)).toFixed(3)),
  top1Rate: Number((top1 / Math.max(1, total - dataset.filter((x) => x.shouldSkip).length)).toFixed(3)),
  adaptiveSkipPass: `${skippedOk}/${dataset.filter((x) => x.shouldSkip).length}`,
};

console.log("EchoDB Regression Report");
console.log(JSON.stringify(report, null, 2));
