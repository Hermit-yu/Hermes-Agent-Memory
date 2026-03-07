# EchoDB Memory Engine 使用说明（MVP+）

## 命令清单
```bash
echodb memory reindex [--disable-noise-filter]
echodb memory search "<query>" [--topK 20] [--scope all|global|agent:main]
                    [--mode hybrid|bm25|vector] [--fusion rrf|weighted]
                    [--bm25Weight 0.6] [--vectorWeight 0.4] [--halfLifeDays 30]
                    [--mmr] [--force] [--json]
echodb memory regress [--dataset <file>]
echodb memory tune [--dataset <file>] [--apply]
echodb memory feedback --query "..." --id <id> --label up|down [--scope ...]
echodb memory selflearn --once
echodb memory stats [--json]
echodb memory list [--scope ...] [--type ...] [--limit 20] [--json]
echodb memory export --out <file> [--scope ...] [--type ...]
echodb memory forget --id <id>
```

## 质量评估与调参
- 评估集：`datasets/regression-zh.json`
- 回归脚本：`scripts/regression.js`
- 调参脚本：`scripts/tune.js`
- 报告输出：`memory-echoDB/indexes/regression-report.json`
- 调参产物：`config/retrieval-profile.json`

### regression 输出指标
- `total`
- `evaluated`
- `hitRate`
- `top1Rate`
- `top3Rate`
- `adaptiveSkipPass`（含 pass/total/rate）
- `byType`（按 query type 分组）

## 默认检索配置
`search` 会默认读取 `config/retrieval-profile.json`：
- `fusion`
- `bm25Weight/vectorWeight`
- `mmr`
- `recencyHalfLifeDays`

CLI 参数优先级更高（可覆盖 profile）。

## 兼容说明
- 保持 `reindex/search/stats/list/export/forget/regress` 可用
- 无 API key 时自动降级 `local-hash`
- `forget` 继续 tombstone，不改 Markdown 真相源
