# EchoDB Memory Engine · MVP(BM25)

这是 EchoDB 的最小可用检索引擎（Node/JS 实现，TS 风格结构）。

## 已实现能力

- 数据规范化（Phase B-1）：
  - 输入：`memory-echoDB/daily/*.md`、`memory-echoDB/long-term/*.md`
  - 输出：`memory-echoDB/indexes/memory-items.jsonl`（可再生产物）
  - 作用域策略 v0：
    - `long-term/*` => `scope=global`
    - `daily/*` => `scope=agent:main`
- BM25 索引：
  - 输入：`memory-items.jsonl`
  - 输出：`memory-echoDB/indexes/bm25-index.json`
- 命令：
  - `echodb memory reindex`
  - `echodb memory search <query> --topK 20`
  - `echodb memory stats`

## 目录

- `src/bm25.js`：分词、建索引、BM25 检索
- `src/memory-store.js`：记忆文件解析、MemoryItem 规范化、索引读写
- `src/cli.js`：命令解析与执行逻辑（含 stats）
- `bin/echodb-memory.js`：Node 入口
- `docs/USAGE.md`：中文使用说明

## 两种调用方式

### 1) Node 直接调用

```bash
node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory reindex
node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory search "关键词" --topK 20
node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory stats
```

### 2) 系统包装命令（Windows）

已提供：
- `automation/echodb/echodb.ps1`
- `automation/echodb/echodb.cmd`

如果将 `automation/echodb` 加入 PATH，即可直接执行：

```bash
echodb memory reindex
echodb memory search "关键词" --topK 20
echodb memory stats
```

## 说明

- `memory-items.jsonl` 与 `bm25-index.json` 都是可再生产物，不应作为真相源。
- 真相源永远是 `memory-echoDB` 下 Markdown 文件。
