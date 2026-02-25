# EchoDB Memory Engine · MVP(BM25)

这是 EchoDB 的最小可用检索引擎（Node/JS 实现，TS 风格结构）。

## 已实现能力

- 数据源：
  - `memory-echoDB/daily/*.md`
  - `memory-echoDB/long-term/MEMORY.md`
- 索引输出：
  - `memory-echoDB/indexes/bm25-index.json`
- 命令：
  - `echodb memory reindex`
  - `echodb memory search <query> --topK 20`

## 目录

- `src/bm25.js`：分词、建索引、BM25 检索
- `src/memory-store.js`：记忆文件读写、索引落盘
- `src/cli.js`：命令解析与执行逻辑
- `bin/echodb-memory.js`：Node 入口
- `docs/USAGE.md`：中文使用说明

## 两种调用方式

### 1) Node 直接调用

```bash
node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory reindex
node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory search "关键词" --topK 20
```

### 2) 系统包装命令（Windows）

已提供：
- `automation/echodb/echodb.ps1`
- `automation/echodb/echodb.cmd`

如果将 `automation/echodb` 加入 PATH，即可直接执行：

```bash
echodb memory reindex
echodb memory search "关键词" --topK 20
```

## 说明

- 索引属于可再生产物，不应作为真相源。
- 真相源永远是 `memory-echoDB` 下 Markdown 文件。
