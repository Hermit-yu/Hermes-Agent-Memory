# Round 05-5｜稳态推进：synthetic 隔离闸门验证与口径修正

## 0) 运行前检查（承接上次进度）
上次未完成清单（R04 收官项）复核：
- [x] 结构化字段接入方案
- [x] strict 回归样本模板
- [x] 周报 strict 接入
- [x] R04 收官总结

结论：R04 未完成项=0，继续 R05。

## 1) 本次仅做 2 个可验证增量

### 增量 A（已完成）
**追加最小 synthetic 样本，验证默认隔离差异**
- 命令：
  `powershell -ExecutionPolicy Bypass -File projects/智妍的自我提升计划/scripts/apply-r05-2-regression.ps1 -PairCount 1 -Force`
- 结果：向审计日志追加 2 条 `synthetic=true` 结构化样本（preflight+execute 成对）。

### 增量 B（已完成）
**修正指标脚本口径：auditTotal 跟随 synthetic 过滤**
- 文件：`scripts/collect-round-metrics.ps1`
- 变更：
  1. 新增 `analysisRecords`（按 `-IncludeSynthetic` 过滤后的分析集合）
  2. `auditTotal` 与完整率计算改为基于 `analysisRecords`
  3. `metrics.sourceTotal` 新增源总量，便于核对“原始量 vs 分析量”

## 2) 双口径回放结果（同一窗口）

### 默认口径（不含 synthetic）
- 命令：
  `powershell -ExecutionPolicy Bypass -File projects/智妍的自我提升计划/scripts/collect-round-metrics.ps1 -RoundId R05-5`
- 产物：`reports/metrics/round-metrics-R05-5.json`
- 关键值：
  - sourceTotal: 18
  - auditTotal: 16
  - highRiskCount: 14
  - strictPreflightCoverage: 1.0

### 包含 synthetic 口径
- 命令：
  `powershell -ExecutionPolicy Bypass -File projects/智妍的自我提升计划/scripts/collect-round-metrics.ps1 -RoundId R05-5-includeSynthetic -IncludeSynthetic`
- 产物：`reports/metrics/round-metrics-R05-5-includeSynthetic.json`
- 关键值：
  - sourceTotal: 18
  - auditTotal: 18
  - highRiskCount: 16
  - strictPreflightCoverage: 1.0

结论：默认隔离闸门已可观测生效（默认口径与 include 口径出现预期差异）。

## 3) 阻塞与解法
### 阻塞
无硬阻塞。

### 已消除的潜在偏差
此前 `auditTotal` 未随 synthetic 过滤，容易误判真实流量规模；本轮已修正为“分析口径一致”。

## 4) 下一步（R05-6 候选）
- 仅做 1 个增量：在真实上游审计写入链路中抽取“无 synthetic 纯生产窗口”复跑，作为稳态验收基线。