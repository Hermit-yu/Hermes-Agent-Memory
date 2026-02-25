# Phase B/C/D Round3：MVP+ 落地记录

日期：2026-02-25

## 目标
在不改变 `memory-echoDB` 文件真相源习惯的前提下，补齐可运行的 B3/B4/C1/C2/C3/C4/D1/D2/D3/D4 最小能力。

## 本轮落地内容

### B-3 向量检索（可选 provider + 优雅降级）
- 新增 `src/vector.js`，默认使用 `local-hash` 向量（无密钥即可运行）。
- 新增向量索引产物：`memory-echoDB/indexes/vector-index.json`。
- 若环境变量存在 `ECHODB_EMBED_PROVIDER + ECHODB_EMBED_API_KEY`，当前版本记录 provider 标识（MVP）；未接第三方 API 调用。

### B-4 Hybrid 融合排序
- 新增 `src/retrieval.js`，支持：
  - `rrf`（默认）
  - `weighted`（`--bm25Weight` / `--vectorWeight`）
- 结果包含 `debug` 子分数（bm25/vector/rank/recency/lengthNorm），便于解释。

### C-1 Adaptive Retrieval
- 增加检索门控：短寒暄/确认句默认跳过（例如“你好”）。
- 可通过 `--force` 强制检索。

### C-2 Noise Filter
- 规范化阶段默认进行清洗：空行/模板噪声/粗去重。
- 可通过 `reindex --disable-noise-filter` 关闭。

### C-3 打分治理
- 融合后叠加 `recency` 与 `lengthNorm`。
- 提供 `--mmr` 可选简单去冗余。

### C-4 评估集与回归脚本
- 新增数据集：`datasets/regression-zh.json`。
- 新增回归脚本：`scripts/regression.js`。
- 运行方式：
  - `node echodb-fusion/ours/memory-engine/mvp-bm25/scripts/regression.js`
  - 或 `echodb memory regress`

### D-1 CLI 补全
- 新增命令：`echodb memory list`。
- `search/stats/list` 支持 `--json`。
- 兼容已有命令：`reindex/search/stats`。

### D-2 forget/export
- 新增：
  - `echodb memory export --out <file> [--scope] [--type]`
  - `echodb memory forget --id <id>`（tombstone 软删除）
- 新增审计：`memory-echoDB/indexes/audit-log.jsonl`。

### D-3 灾备
- 索引均可由 `echodb memory reindex` 一键重建。

### D-4 文档收敛
- 更新 `README.md`（仓库入口说明）
- 更新 `mvp-bm25/README.md`
- 更新 `mvp-bm25/docs/USAGE.md`
- 新增 `mvp-bm25/docs/操作手册-中文.md`

## 验收执行（本地）

1. `echodb memory reindex` ✅
2. `echodb memory search "EchoDB" --topK 20` ✅
3. `echodb memory search "EchoDB" --topK 20 --scope global` ✅
4. `echodb memory search "你好" --topK 20` ✅（Adaptive skip）
5. `echodb memory list --limit 5` ✅
6. `echodb memory stats` ✅
7. `echodb memory export --out memory-echoDB/indexes/export-sample.json --scope all` ✅
8. `echodb memory forget --id <id>` ✅
9. forget 后 `list` 不再返回被 tombstone 的 id ✅
10. `node .../scripts/regression.js` ✅（输出 hitRate/top1Rate/adaptiveSkipPass）

## MVP 简化与风险

- 向量检索目前为本地 hash embedding，优先可运行与可迁移；后续可替换真实 embedding provider。
- forget 为索引层软删除，不改 Markdown 真相源；重建时依赖 tombstone 保持效果。
- 评估集规模较小（样例集），当前用于回归冒烟，不代表最终线上质量。
