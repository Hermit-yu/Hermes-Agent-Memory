# EchoDB Memory Engine Phase B 第一轮实现记录

日期：2026-02-25

## 本轮变更

1. **B-1 数据规范化落地**
   - 新增 `memory-items.jsonl` 产物生成流程：
     - 输入：`memory-echoDB/daily/*.md`、`memory-echoDB/long-term/*.md`
     - 输出：`memory-echoDB/indexes/memory-items.jsonl`
   - 每个 Markdown 文件规范化为一条 `MemoryItem`（v0）
   - 字段覆盖：`id, scope, type, title, content, sourcePath, createdAt, updatedAt(optional), importance`
   - `importance` 默认 `0.5`
   - 作用域策略 v0：
     - `long-term/*` => `global`
     - `daily/*` => `agent:main`

2. **BM25 对接调整**
   - `echodb memory reindex` 改为两段式：
     1) 生成 `memory-items.jsonl`
     2) 从 `memory-items.jsonl` 构建 `bm25-index.json`

3. **新增命令**
   - `echodb memory stats`
   - 输出指标：`docs`、`terms`、`avgdl`、`sources`、`indexCreatedAt`

4. **文档更新**
   - `mvp-bm25/README.md`
   - `mvp-bm25/docs/USAGE.md`

## 风险与限制

- 当前 v0 规范化粒度为“每个文件一条 MemoryItem”，未做段落级切分；长文档召回精度可能受影响。
- `createdAt` 对 daily 文件优先使用文件名日期（`YYYY-MM-DD`），其他文件使用文件系统时间；跨系统迁移时元数据时间可能有轻微差异。
- `tags` 暂未自动抽取（字段预留）。

## 验收建议

- 运行 `echodb memory reindex`，确认同时生成：
  - `memory-echoDB/indexes/memory-items.jsonl`
  - `memory-echoDB/indexes/bm25-index.json`
- 运行 `echodb memory search "<query>" --topK 20` 有有效结果。
- 运行 `echodb memory stats` 能输出约定统计项。
