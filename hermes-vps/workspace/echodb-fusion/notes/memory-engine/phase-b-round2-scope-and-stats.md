# Phase B Round2：作用域检索与 stats 增强（B-2）

日期：2026-02-25

## 变更点

1) `search` 增加作用域过滤参数 `--scope`
- 支持值：`all`（默认）、`global`、`agent:main`
- 过滤依据：`memory-items` 归一化后的 `scope`
- 输出展示：每条命中结果打印 `[scope=...]`

2) `stats` 可观测性增强
- 在已有 `docs / terms / avgdl / sources / indexCreatedAt` 上增加：
  - `scopes`：各 scope 文档数
  - `types`：各 type 文档数（如 `daily-note` / `long-term-note`）

3) `reindex` 稳定性小增强
- 当 `daily/` + `long-term/` 均无 markdown 时，给出明确错误
- 当 `memory-items.jsonl` 为空或不可读时，给出明确错误
- `stats` 在索引缺失、items 缺失/为空时，给出友好提示
- 保持“可再生产物”原则：仅重建 indexes 下产物，不改写真相源 markdown

4) 数据结构透传
- 建索引时把 `scope` / `type` 写入 index docs，便于检索过滤与统计

## 示例命令

```bash
echodb memory reindex
echodb memory search "EchoDB" --topK 20
echodb memory search "EchoDB" --topK 20 --scope global
echodb memory stats
```

## 风险与兼容性

- 默认 `--scope=all`，兼容旧调用 `echodb memory search <query> --topK 20`
- 新增字段 `scope/type` 到索引文档，属于向后兼容扩展
- 若用户传入非法 scope，CLI 直接报错并提示允许值

## 验收结果

已执行并通过：

1. `echodb memory reindex` ✅
- 输出：`Reindex done: memoryItems=5, docs=5, avgdl=151.40, ...`

2. `echodb memory search "EchoDB" --topK 20` ✅
- 输出包含：`Found 1 result(s) (scope=all)`
- 每条命中展示：`[scope=global]`

3. `echodb memory search "EchoDB" --topK 20 --scope global` ✅
- 输出包含：`Found 1 result(s) (scope=global)`

4. `echodb memory stats` ✅
- 输出包含新增字段：
  - `scopes: {"agent:main":4,"global":1}`
  - `types: {"daily-note":4,"long-term-note":1}`