# R05-12 steady progress: latest vs real-window strict 字段差异短报

## 0) Pre-check（上次进度与未完成清单）
- 复核 `reports/rounds/R04-closeout-stability-checklist-2026-02-26.md`：R04 收官未完成项仍为 **0/4**。
- 承接 `R05-11` 下一步：补一份 `latest-round-metrics.json` 与 `round-metrics-R05-8.json` 的 strict 字段差异短报，盯防口径漂移。

## 1) Increment A（可验证）
新增 strict 字段差异证据文件：
- `reports/metrics/strict-diff-latest-vs-R05-8.json`

对比字段：
- strictPreflightCoverage
- strictMode
- compatFallbackRatio
- unknownEventTypeCount
- strictStructuredRecords
- strictFallbackRecords

结论：`allEqual = true`，本轮未发现 strict 口径漂移。

## 2) Increment B（可验证）
完成本轮短报沉淀（本文件），固定“先对比 latest 与真实窗口，再判断是否漂移”的稳态步骤，供后续轮次复用。

快速验证命令：

```powershell
Get-Content reports/metrics/strict-diff-latest-vs-R05-8.json | ConvertFrom-Json | Select-Object allEqual,latestRoundId,realWindowRoundId
```

## 3) Blocking status
无阻塞。

## 4) Next step（稳态优先）
下轮仅做 1 个小增量：
- 新增一份真实窗口周报（W05），并再次执行 strict gate + latest/real-window 差异复核。
