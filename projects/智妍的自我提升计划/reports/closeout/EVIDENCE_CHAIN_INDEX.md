# EVIDENCE_CHAIN_INDEX (R06 Fusion Closeout)

## Purpose
将历史轮次分散证据聚合为收官可验链路，避免碎片化验收。

## Chain Map
1. Round Evidence
   - `reports/rounds/R05-*.md`
   - `reports/rounds/R06-*.md`
2. Metrics Evidence
   - `reports/metrics/round-metrics-*.json`
   - `reports/metrics/strict-gate-check-*.json`
   - `reports/metrics/weekly-diff-evidence-check-*.json`
3. Weekly Evidence
   - `reports/weekly/W*.md`
4. Closeout Control
   - `reports/closeout/CLOSEOUT_STATUS.json`
   - `reports/closeout/RISK_AND_COMPRESSION.md`

## Verification Stitching Rules
- 每条“结论”必须至少挂2个证据：机器结果 + 文档叙述。
- 证据命名按日期和轮次双键定位（例：R05-29 + 2026-02-26）。
- 封版前完成“指标→证据→回滚”三跳互链检查。

## R06-26 Increment
- 证据链索引主骨架完成，进入条目化补全阶段。
