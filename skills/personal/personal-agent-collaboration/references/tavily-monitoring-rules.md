---
name: tavily-monitoring-rules
references_for: personal-agent-collaboration
---
# Tavily 积分监控规则（本轮验证后写入）

## 适用场景
每周六 09:00 自动检测 Tavily API 积分余额，绝对上限 1000 积分。

## 规则（硬性）
- 上限：积分用量绝对不能超过 1000 积分。
- 数据来源：用户提供的截图 / dashboard 数字为权威；脚本无法独立提取精确余额（无计费端点访问权）。
- 脱敏：真实 Key 只写在 `.env`，脚本只读取不输出完整值。

## 脚本位置
`/root/.hermes/Hermes-Agent-Memory/Workspace/honcho-local/scripts/check_tavily_credits.sh`
- 读取 `/root/.hermes/.env` 中 `TAVILY_API_KEY`
- 执行 `curl` 状态检查（返回状态码，非完整响应）
- 日志写入 `/workspace/reports/tavily_cron.log`

## 定时任务
`crontab` 行：`0 9 * * 6 /.../check_tavily_credits.sh >> /workspace/reports/tavily_cron.log 2>&1`

## 关键教训（本轮修正）
- 之前 `/etc/tavily/api_key` 已清理，改为 `/root/.hermes/.env` 管理（更可控）。
- `hermes` PATH 修复：复制正确二进制（7,544 B，内嵌解释器）而非小包装脚本（262 B，缺模块）。
- 无法获取实时精确余额时，直接告知用户依赖截图验证，不编造数字。
