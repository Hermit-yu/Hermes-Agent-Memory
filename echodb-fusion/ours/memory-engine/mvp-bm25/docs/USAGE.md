# EchoDB Memory Engine 使用说明（MVP+）

## 命令

```bash
echodb memory reindex [--disable-noise-filter]
echodb memory search "<query>" --topK 20 [--scope all|global|agent:main] [--mode hybrid|bm25|vector]
                    [--fusion rrf|weighted] [--bm25Weight 0.6] [--vectorWeight 0.4] [--force] [--mmr] [--json]
echodb memory list [--scope ...] [--type ...] [--limit 20] [--json]
echodb memory stats [--json]
echodb memory export --out <file> [--scope ...] [--type ...]
echodb memory forget --id <id>
```

## 核心能力

- **向量检索接入（B3）**：输出 `memory-echoDB/indexes/vector-index.json`。
  - 默认 provider=`local-hash`（无 key 也可运行）
  - 若设置 `ECHODB_EMBED_PROVIDER + ECHODB_EMBED_API_KEY`，当前版本仅记录 provider 标识（MVP）
- **Hybrid 融合（B4）**：支持 `rrf` 与 `weighted`
  - `--bm25Weight/--vectorWeight`
  - 返回 `debug` 子分数（bm25/vector/recency/lengthNorm）
- **Adaptive Retrieval（C1）**：寒暄/确认句默认跳过检索（如“你好”）
  - `--force` 可强制检索
- **Noise Filter（C2）**：reindex 时默认去空/模板噪声/重复
  - `--disable-noise-filter` 可关闭
- **打分治理（C3）**：融合后叠加 recency 衰减 + length norm
  - `--mmr` 可启用简单 MMR 去冗余
- **CLI 完整性（D1）**：新增 `list`，`search/stats/list` 支持 `--json`
- **forget/export（D2）**：
  - forget 采用 tombstone（`forget-tombstones.json`）
  - 审计日志：`audit-log.jsonl`
- **灾备（D3）**：`echodb memory reindex` 一键重建 `memory-items/bm25/vector`

## 回归测试（C4）

```bash
node echodb-fusion/ours/memory-engine/mvp-bm25/scripts/regression.js
# 或
echodb memory regress
```

数据集：`datasets/regression-zh.json`

输出指标：
- `totalQueries`
- `hitRate`
- `top1Rate`
- `adaptiveSkipPass`

## stats 输出字段（当前）

- `docs`
- `terms`
- `avgdl`
- `sources`
- `indexCreatedAt`
- `vectorIndexCreatedAt`
- `vectorProvider`
- `forgotten`
- `scopes`
- `types`

## 灾备步骤

1. 保留真相源：`memory-echoDB/daily` + `memory-echoDB/long-term`
2. 若索引损坏，删除/忽略 `memory-echoDB/indexes/*`
3. 运行 `echodb memory reindex`
4. 用 `echodb memory stats` 验证重建结果
