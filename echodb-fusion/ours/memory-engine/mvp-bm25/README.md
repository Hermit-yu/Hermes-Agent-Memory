# EchoDB Memory Engine · MVP+（质量强化 + 自学习）

本轮增强目标：**可量化质量提升 + 可后台持续优化**。

## 新增能力
- 更完整中文评估集（`datasets/regression-zh.json`，覆盖事实召回/近期事件/作用域/寒暄跳过/模糊语义/同义词）
- 回归评分增强：`total/evaluated/hitRate/top1Rate/top3Rate/adaptiveSkipPass` + `byType`
- 机器可读报告：`memory-echoDB/indexes/regression-report.json`
- 自动调参：`scripts/tune.js` 网格搜索（fusion、权重、MMR、recency half-life）
- 默认检索配置：`config/retrieval-profile.json`，`search` 自动读取，CLI 参数可覆盖
- 反馈机制：`echodb memory feedback --query ... --id ... --label up|down`
- 自学习：`echodb memory selflearn --once`（读取 feedback + regression，更新 profile，写审计）

## 快速命令
```bash
echodb memory reindex
echodb memory regress
echodb memory tune
echodb memory search "混合检索" --json
echodb memory feedback --query "混合检索" --id <id> --label up
echodb memory selflearn --once
```

详见：
- `docs/USAGE.md`
- `docs/操作手册-中文.md`
- `docs/SELF_LEARNING.md`
