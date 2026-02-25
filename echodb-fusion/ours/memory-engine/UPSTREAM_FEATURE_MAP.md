# Upstream 能力映射（memory-lancedb-pro → EchoDB MVP）

## 范围

- 上游：`win4r/memory-lancedb-pro`（commit `3df1fef`）
- 我方基线：文件型真相源（`memory-echoDB/daily` + `memory-echoDB/long-term`）+ `mvp-bm25`

## 能力映射总览

| 上游能力 | 我方现状 | 结论 | 说明 |
|---|---|---|---|
| Hybrid Retrieval（Vector + BM25） | MVP 已有 BM25 骨架，Vector 未接入 | 待完成 | 先保 BM25 可用，再引入向量检索与融合打分 |
| Cross-Encoder Rerank | 未实现 | 待完成 | 作为可选增强，默认可关闭 |
| Multi-scope isolation（global/agent/project/user） | 仅有基础 scope 规划 | 待完成 | 需要写入、检索、权限过滤全链路一致 |
| Adaptive Retrieval（是否触发检索） | 未实现 | 待完成 | 可减少寒暄类无效检索 |
| Noise Filter（写入前降噪） | 未实现 | 待完成 | 需防重复、空洞、系统噪声入库 |
| Recency/Decay/LengthNorm | 未实现 | 待完成 | 先做可开关参数，再校准权重 |
| Management CLI（list/search/stats/forget/export/reindex） | 无统一 CLI | 待完成 | 先做 search/stats/reindex，再补 forget/export |
| Auto capture / auto recall | 仅人工流程 | 不做（当前阶段） | 当前阶段优先可控性，避免自动写入污染真相源 |
| Session memory hook | 未实现 | 不做（当前阶段） | 先把离线索引链路稳定后再评估 |

## 我方已完成（可复用）

1. 融合目录骨架（upstream / ours / notes）
2. `memory-echoDB/schema` 与 `indexes` 基础规划
3. `mvp-bm25` 目录与文档骨架

## 当前建议

- 近期优先级：`BM25稳定化 > scope贯通 > 检索治理 > rerank`。
- 约束不变：`memory-echoDB` 真相源不被索引流程反向污染。
