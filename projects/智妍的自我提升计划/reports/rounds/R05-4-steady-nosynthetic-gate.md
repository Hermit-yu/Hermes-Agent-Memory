# Round 05-4｜稳态推进：非注入样本默认隔离闸门

## 0) 运行前检查（承接上次进度）
上次未完成清单（R04 收官项）复核：
- [x] 结构化字段接入方案
- [x] strict 回归样本模板
- [x] 周报 strict 接入
- [x] R04 收官总结

结论：R04 未完成项仍为 0，继续推进 R05。

## 1) 本次仅做 2 个可验证增量

### 增量 A（已完成）
**指标脚本新增“默认排除 synthetic 样本”机制**
- 文件：`scripts/collect-round-metrics.ps1`
- 变更：
  1. 新增参数：`-IncludeSynthetic`（默认不传 = 排除 synthetic=true 记录）
  2. strict 统计前增加 synthetic 过滤分支
  3. assumptions 新增 `syntheticRule` 说明
  4. metricsVersion 升级为 `v3.1-round05-structured-first-nosynth-default`

### 增量 B（已完成）
**执行 R05-4 回放并落盘最新指标**
- 命令：
  `powershell -ExecutionPolicy Bypass -File projects/智妍的自我提升计划/scripts/collect-round-metrics.ps1 -RoundId R05-4`
- 产物：
  - `reports/metrics/round-metrics-R05-4.json`
  - `reports/metrics/latest-round-metrics.json`

## 2) 本次结果（R05-4）
来源：`reports/metrics/round-metrics-R05-4.json`

- metricsVersion: `v3.1-round05-structured-first-nosynth-default`
- auditTotal: 16
- highRiskCount: 14
- uniqueHighRiskOps: 5
- uniquePreflightOps: 5
- strictHighRiskPreflightIntersectOps: 5
- strictPreflightCoverage: 1.0
- compatFallbackRatio: 0.0

## 3) 阻塞与解法
### 阻塞
现有审计日志中的回归注入记录缺少 `synthetic=true` 标记（历史数据已写入，无法被默认过滤分支识别），导致“默认隔离 synthetic”机制暂时未体现为指标变化。

### 解法
1. 后续所有回归注入必须强制包含 `synthetic=true`；
2. 如需验证隔离效果，追加一批带 `synthetic=true` 的样本并复跑（同窗口对比 `-IncludeSynthetic` 与默认模式）；
3. 真实生产审计流量完成结构化字段实装后，再做“无注入窗口”复测并作为稳定性验收基线。

## 4) 下一步（R05-5 候选）
- 仅做 1 个增量：追加“带 synthetic 标记”的最小样本集并跑双口径对比，确认默认隔离生效。
