# LEARNINGS

## [LRN-20260306-001] best_practice

**Logged**: 2026-03-06T19:24:52+08:00
**Priority**: high
**Status**: pending
**Area**: config

### Summary
Telegram 通道工具集被 `tools.profile=messaging` 限制时，skills “已安装/已启用”也不会暴露为可调用工具；需切到 `tools.profile=full`（或更高权限 profile）才能拿到 exec/tmux 等能力。

### Details
现象：weather skill 显示 ready、WebUI 里也启用，但会话里始终只有 message/sessions_* 等工具，无法调用 weather 或执行本地命令。
根因：`~/.openclaw/openclaw.json` 中 `tools.profile` 设为 `messaging`，会限制工具白名单，导致能力不会被暴露到模型工具列表。

### Suggested Action
- 需要“能执行命令/读写文件/运行 skills”时，将 `tools.profile` 调整为 `full`（或按实际需要选择 profile）。
- 用 schema 验证 profile 枚举：`minimal|coding|messaging|full`。

### Metadata
- Source: conversation
- Related Files: ~/.openclaw/openclaw.json
- Tags: tools-profile, telegram, permissions
- Pattern-Key: openclaw.tools_profile.misconfigured
- Recurrence-Count: 1
- First-Seen: 2026-03-06
- Last-Seen: 2026-03-06

---
## [LRN-20260306-002] best_practice

**Logged**: 2026-03-06T19:24:52+08:00
**Priority**: high
**Status**: pending
**Area**: config

### Summary
启用 `tools.exec.security=allowlist` 时，需要用 `safeBins`/`safeBinTrustedDirs`（可选 `safeBinProfiles`）放行具体脚本，否则会报 `exec denied: allowlist miss`。

### Details
现象：exec 工具已可用，但执行 `/opt/OpenClaw/zhiyan-workspace/skills/weather-cn/weather-cn.sh` 失败，报错：`exec denied: allowlist miss`。
原因：配置里只设置了 `security=allowlist`，未配置任何 allowlist 规则；在该版本 schema 中 allowlist 通过 `safeBins` 等字段表达。

### Suggested Action
- 最小放行：
  - `safeBins`: 精确允许脚本路径
  - `safeBinTrustedDirs`: 限定脚本所在可信目录
  - `safeBinProfiles`: 限制位置参数数量/禁用危险 flag（可选）
- 如果要“全放行”，改 `security=full`，并建议将 `ask` 至少设为 `on-miss` 或 `always`。

### Metadata
- Source: error
- Related Files: ~/.openclaw/openclaw.json
- Tags: exec, allowlist, safeBins
- Pattern-Key: openclaw.exec.allowlist.safeBins
- Recurrence-Count: 1
- First-Seen: 2026-03-06
- Last-Seen: 2026-03-06

---
## [LRN-20260306-003] best_practice

**Logged**: 2026-03-06T19:24:52+08:00
**Priority**: medium
**Status**: pending
**Area**: infra

### Summary
当用户用截图提供 CLI 输出时，易丢失关键字段；优先让用户粘贴纯文本或直接发送配置文件（脱敏后）。

### Details
排查 tools/profile/exec 时，截图无法稳定提取完整字段，导致定位慢。
用户后来直接提供 openclaw.json（包含 agents/tools/bindings/channels），定位立即收敛。

### Suggested Action
- 默认引导：用 `jq`/`cat` 输出纯文本粘贴。
- 如必须截图：要求截取命令+完整输出，并说明可能导致误判。

### Metadata
- Source: simplify-and-harden
- Tags: troubleshooting, observability
- Pattern-Key: ops.prefer_text_over_screenshots
- Recurrence-Count: 1
- First-Seen: 2026-03-06
- Last-Seen: 2026-03-06

---
