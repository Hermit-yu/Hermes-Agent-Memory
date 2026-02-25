# EchoDB Memory Engine · MVP+（BM25 + Vector + Hybrid）

本版本在原 BM25 MVP 基础上补齐 Phase B/C/D 的可运行能力：

- B3 向量检索 + 本地优雅降级（local-hash embedding）
- B4 Hybrid 融合排序（RRF / weighted）
- C1 Adaptive Retrieval（寒暄默认跳过，可 `--force`）
- C2 Noise Filter（清洗、去重，可关闭）
- C3 打分治理（recency + length norm + 可选 MMR）
- C4 评估集与回归脚本
- D1 CLI 补全（list + JSON）
- D2 forget/export + audit-log
- D3 灾备流程（reindex 一键重建）

详见：`docs/USAGE.md`
