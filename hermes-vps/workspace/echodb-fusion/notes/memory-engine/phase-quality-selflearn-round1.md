# Phase Quality+SelfLearn Round1 收尾记录

日期：2026-02-25

## 目标
在既有改动基础上完成 EchoDB「质量强化 + 后台自学习」闭环，并执行 8 步验收。

## 关键补齐
- 修正 `echodb memory tune` 行为：仅在显式 `--apply` 时写入 profile（CLI 参数仍可覆盖 profile）。
- 补齐中文操作手册示例：`tune --apply`。
- 验收全流程执行并记录输出（见下）。

## 验收执行输出（按顺序）
1) `echodb memory reindex`
- `Reindex done: memoryItems=5, docs=5, bm25=bm25-index.json, vector=vector-index.json, provider=local-hash`

2) `echodb memory regress`
- total=26, evaluated=22
- hitRate=0.3182, top1Rate=0.2727, top3Rate=0.3182
- adaptiveSkipPass=4/4(rate=1)
- 报告落盘：`memory-echoDB/indexes/regression-report.json`

3) `echodb memory tune --apply`
- gridSize=48
- best=`hybrid + rrf + bm25:0.4/vector:0.6 + mmr:false + halfLife:14`
- profile 已写入：`mvp-bm25/config/retrieval-profile.json`

4) `echodb memory search "EchoDB" --topK 20`
- 输出包含：`Found 1 result(s) (mode=hybrid, scope=all, profile=auto-tuned)`
- 说明默认 profile 生效（未显式传 mode/fusion/weights）。

5) `echodb memory list --limit 5`
- 列表返回 2 条（含 long-term MEMORY.md）。

6) feedback 示例
- `echodb memory feedback --query "EchoDB" --id 67e09aa... --label up --scope global`
- 输出：`Feedback saved: up id=67e09aa...`

7) `echodb memory selflearn --once`
- 输入：dataset + feedback-log + regression-report
- 输出 summary：profileBefore/profileAfter + metricsBefore/metricsAfter
- 审计写入：`memory-echoDB/indexes/audit-log.jsonl`

8) `echodb memory stats`
- docs=5, terms=2070, avgdl=553.8, vectorProvider=local-hash

## 指标前后对比（regress 前 vs selflearn 后）
- hitRate: **0.3182 -> 0.3182**
- top1Rate: **0.2727 -> 0.2727**
- top3Rate: **0.3182 -> 0.3182**
- adaptiveSkipRate: **1.0000 -> 1.0000**

说明：当前数据规模很小（docs=5），本轮反馈量低，参数保持最优组合未变。

## 自学习输入/输出说明
- 输入：
  - `memory-echoDB/indexes/feedback-log.jsonl`
  - `datasets/regression-zh.json`
  - `memory-echoDB/indexes/regression-report.json`
- 过程：
  - 触发轻量网格调参（fusion/weights/mmr/halfLifeDays）
  - 以回归指标+反馈拟合综合打分选最优
- 输出：
  - 更新 `mvp-bm25/config/retrieval-profile.json`（仅 `--apply`）
  - 刷新 `regression-report.json`
  - 追加 `audit-log.jsonl` 审计记录
