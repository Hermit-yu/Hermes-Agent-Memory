#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");
const { loadProfile } = require("../src/profile");

const workspaceRoot = path.resolve(__dirname, "../../../../..");
const tuneScript = path.join(workspaceRoot, "echodb-fusion/ours/memory-engine/mvp-bm25/scripts/tune.js");
const regressScript = path.join(workspaceRoot, "echodb-fusion/ours/memory-engine/mvp-bm25/scripts/regression.js");
const dataset = path.join(workspaceRoot, "echodb-fusion/ours/memory-engine/mvp-bm25/datasets/regression-zh.json");
const indexesDir = path.join(workspaceRoot, "memory-echoDB/indexes");
const reportPath = path.join(indexesDir, "regression-report.json");
const feedbackPath = path.join(indexesDir, "feedback-log.jsonl");
const auditPath = path.join(indexesDir, "audit-log.jsonl");

function readJson(file) {
  if (!fs.existsSync(file)) return null;
  try { return JSON.parse(fs.readFileSync(file, "utf8")); } catch { return null; }
}

function runNode(script, args = []) {
  return cp.execFileSync(process.execPath, [script, ...args], { encoding: "utf8" });
}

const beforeProfile = loadProfile(workspaceRoot);
let beforeMetrics = readJson(reportPath);
if (!beforeMetrics) {
  runNode(regressScript, ["--dataset", dataset]);
  beforeMetrics = readJson(reportPath);
}

runNode(tuneScript, ["--dataset", dataset, "--apply"]);
runNode(regressScript, ["--dataset", dataset]);

const afterProfile = loadProfile(workspaceRoot);
const afterMetrics = readJson(reportPath);
const feedbackCount = fs.existsSync(feedbackPath)
  ? fs.readFileSync(feedbackPath, "utf8").split(/\r?\n/).filter(Boolean).length
  : 0;

const summary = {
  ts: new Date().toISOString(),
  action: "selflearn",
  trigger: "manual-once",
  inputs: {
    dataset: path.relative(workspaceRoot, dataset).replace(/\\/g, "/"),
    feedbackLog: path.relative(workspaceRoot, feedbackPath).replace(/\\/g, "/"),
    feedbackCount,
    regressionReport: path.relative(workspaceRoot, reportPath).replace(/\\/g, "/"),
  },
  profileBefore: beforeProfile.retrieval,
  profileAfter: afterProfile.retrieval,
  metricsBefore: beforeMetrics ? {
    hitRate: beforeMetrics.hitRate,
    top1Rate: beforeMetrics.top1Rate,
    top3Rate: beforeMetrics.top3Rate,
    adaptiveSkipRate: beforeMetrics.adaptiveSkipPass?.rate,
  } : null,
  metricsAfter: afterMetrics ? {
    hitRate: afterMetrics.hitRate,
    top1Rate: afterMetrics.top1Rate,
    top3Rate: afterMetrics.top3Rate,
    adaptiveSkipRate: afterMetrics.adaptiveSkipPass?.rate,
  } : null,
};

fs.mkdirSync(indexesDir, { recursive: true });
fs.appendFileSync(auditPath, `${JSON.stringify(summary)}\n`, "utf8");

console.log("EchoDB SelfLearn Summary");
console.log(JSON.stringify(summary, null, 2));
