# EVIDENCE_CHAIN_INDEX (R06 Fusion Closeout)

## 目的
把分散在各轮次的证据聚合为可审计闭环，确保“结论可追溯、封版可复核”。

## 证据主链
1. 轮次证据
   - `reports/rounds/R05-*.md`
   - `reports/rounds/R06-*.md`（含 `R06-30` 封版记录）
2. 指标证据
   - `reports/metrics/round-metrics-*.json`
   - `reports/metrics/strict-gate-check-*.json`
   - `reports/metrics/weekly-diff-evidence-check-*.json`
3. 周报证据
   - `reports/weekly/W*.md`
4. 收官控制证据
   - `reports/closeout/CLOSEOUT_STATUS.json`
   - `reports/closeout/RISK_AND_COMPRESSION.md`

## 复核规则（精简版）
- 每条关键结论至少绑定两类证据：机器结果 + 文档说明。
- 证据定位采用“双键”：轮次 + 日期（示例：`R05-29` + `2026-02-26`）。
- 封版前必须完成“指标 → 证据 → 回滚”三跳互链检查。

## 封版结论
- `R06-30` 已完成链路抽检，收官包引用路径可回溯。
