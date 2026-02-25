# Phase Q+SL Round4（质量强化 + 自学习）

日期：2026-02-25

## 本轮交付
1. 扩展中文评估集（27条）：事实召回、近期事件、作用域过滤、寒暄跳过、模糊语义、同义词
2. 回归脚本增强：
   - 输出 total/evaluated/hitRate/top1Rate/top3Rate/adaptiveSkipPass
   - 支持 byType 分组
   - 写 machine-readable 报告到 `memory-echoDB/indexes/regression-report.json`
3. 新增自动调参 `scripts/tune.js`：
   - 网格搜索 fusion/weight/mmr/recencyHalfLifeDays
   - 用 top1/top3/hit/skip + 反馈拟合评分选择最优
   - 写入 `config/retrieval-profile.json`
4. search 默认读取 profile，CLI 参数可覆盖
5. 新增反馈命令：`echodb memory feedback`
6. 新增自学习命令：`echodb memory selflearn --once`
   - 读取 feedback + regression
   - 调参并更新 profile
   - 写 audit-log summary
7. 补充后台方案文档与脚本：`docs/SELF_LEARNING.md` + `automation/echodb/selflearn.ps1`

## 兼容性
- 保留 reindex/search/stats/list/export/forget/regress
- 无 API key 继续 local-hash 降级
- forget 继续 tombstone
