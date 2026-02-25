# EchoDB Memory Engine · MVP(BM25)（方案A：Node/TS 路线）

宝贝，这个模块是我们在 **不改变现有记忆写法** 的前提下，先把“可检索记忆”做出来的第一步。

## 目标
- 读取真相源：
  - `memory-echoDB/daily/*.md`
  - `memory-echoDB/long-term/MEMORY.md`
- 生成可再生索引：写入 `memory-echoDB/indexes/`（**默认不进 Git**）
- 提供命令：`echodb memory search <query>`
  - 默认 `topK=20`
  - 返回：命中摘要 + 来源路径

## 为什么先做 BM25
- 不需要 embedding key（环境更稳）
- 关键词命中直观、可解释
- 后续可平滑升级到：Hybrid(Vector+BM25) + rerank

## 目录说明（中文标注）
- `src/`
  - 源码（TypeScript）。
- `bin/`
  - CLI 入口（后续会放 `echodb` 命令封装）。
- `docs/`
  - 使用说明、FAQ、调参说明。
- `out/`
  - 构建产物（可删除，可重建）。

> 注意：本模块目前先搭脚手架与规划，确保仓库结构清晰、不影响你现有习惯；实现会按 Phase B 逐步补齐。
