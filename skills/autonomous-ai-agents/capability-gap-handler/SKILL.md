---
name: capability-gap-handler
description: Missing tool? Search official skills/MCP, self-integrate.
---

# Capability Gap Handler

底层准则（用户 2026-10-07 授权，自主施行，不需用户点头）：遇到做不到 / 无法完成 / 没合适工具时，**第一时间**搜索官方渠道的 skills 和 MCP，并**第一时间自行对接**（安装→配置→验证全自己跑）。

## When to Use
- 任务需要的工具/能力当前没有原生工具覆盖
- 现有工具报错且无法用常规重试解决（缺依赖、缺凭据、缺端点）
- 用户问 "can you do X / 有没有能做 X 的东西"

## Search channels（按此顺序，全部并行发起）
1. **官方 MCP catalog（Hermes 内置，Nous 审核过的 65 项）**：
   - `hermes mcp catalog` 列出全部（注意：命令必须在 workdir=/root 下跑，terminal 默认 cwd 是 /opt/yuntong 会直接 126 崩）
   - 装：`hermes mcp install <name>`；交互 picker：`hermes mcp`；自定义：写 `~/.hermes/config.yaml` 的 `mcp_servers:`（stdio 用 command/args/env，remote 用 url/headers/auth）
   - 装完工具在下一轮会话自动注册为 `mcp-<server>` 工具组
2. **Skills 生态（skills.sh，npx skills CLI）**：
   - 前置：`export PATH=/root/.hermes/tools/node-26.7.0-linux-x64/bin:$PATH`
   - 搜：`npx -y skills find <query>`；装：`npx -y skills add <owner/repo@skill>`（`-g -y` 全局+免确认）
   - 已装列表：`npx -y skills list`；浏览器可查 https://skills.sh/
3. **MCP 社区目录**：hermes mcp catalog 没有对应项时，搜官方 MCP 服务（各厂商 `mcp.<vendor>.com` 风格的 remote endpoint）或 modelcontextprotocol 官方服务器，按 mcp_servers 配置格式手写进 config.yaml
4. 都搜不到才承认没有现成能力，自己写最小工具/skill 兜底，并说明为什么官方渠道没有

## Integration protocol（对接 = 装好不算完，验证完才算完）
1. 安装/写入配置
2. 凭据：API key 写 `~/.hermes/.env`（catalog install 会引导）；OAuth 走 hermes 引导或浏览器标签（用户 TUI 环境习惯浏览器授权）
3. 验证工具真的暴露：重启/新会话后确认 `mcp-<server>` 工具组出现在可用工具里，实际调用一次读操作
4. 全程回执给用户：装了什么、验证结果、还差什么

## Guardrails
- 交易/支付/破坏性写操作类 MCP（stripe、paypal、robinhood 等）：接入后默认只用读类工具，写/钱相关调用先确认
- 不装与任务无关的多余 server；装前先看 catalog 里 description 对不对口
- 本地 skill 安装进 /root/.hermes/skills/，发现 YAML frontmatter 坏掉的顺手修掉（description 含冒号要加引号）

## Known pitfalls
- terminal 工具默认 cwd=/opt/yuntong（不存在）→ 所有命令显式 `workdir=/root`
- node/npx 不在默认 PATH → 先 export 上面的 node bin 目录
- `hermes mcp catalog` 输出里 `available` = 可装未装，`enabled` = 已装已开
