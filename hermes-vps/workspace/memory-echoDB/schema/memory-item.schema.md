# EchoDB MemoryItem Schema (v0)

目的：定义“文件型真相源”进入检索引擎（可选）的最小字段集合。

## MemoryItem

- `id`：string（稳定 ID，可用 hash 或 uuid）
- `scope`：string（例如：`global` / `agent:main` / `project:host-perf-optimizer` / `user:hermit`）
- `type`：string（`daily` | `long-term` | `note`）
- `title`：string（可选）
- `content`：string（正文）
- `sourcePath`：string（来源文件路径，如 `memory-echoDB/daily/2026-02-22.md`）
- `createdAt`：ISO8601（从文件日期/元信息推断）
- `updatedAt`：ISO8601（可选）
- `tags`：string[]（可选）
- `importance`：0..1（可选，默认 0.5）

## Scopes 约定（v0）

- 默认 scope：`global`
- 与 agent 强绑定：`agent:<id>`
- 与项目绑定：`project:<name>`（避免跨项目串味）

> 说明：真相源仍然是 markdown 文件；schema 只是为了未来索引一致。
