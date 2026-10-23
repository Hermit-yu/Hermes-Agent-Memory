# Hermes Agent Masterclass — 使用报告

> 来源：YouTube 播放列表 `PLmpUb_PWAkDx-VWjh00tVCji794xAa_IX`（10 模块，约 5 小时 14 分钟）  
> 作者：Tonbi（Hermes Atlas）  
> 更新：2026 年 7 月版  
> 报告生成：智妍 · 2026-10-07

---

## 目录
1. [整体概览](#整体概览)
2. [模块速览](#模块速览)
3. [核心概念与架构](#核心概念与架构)
4. [关键工具链与配置点](#关键工具链与配置点)
5. [实操最佳实践](#实操最佳实践)
6. [常见坑点与避坑指南](#常见坑点与避坑指南)
7. [进阶扩展方向](#进阶扩展方向)
8. [资源链接汇总](#资源链接汇总)

---

## 整体概览

**Hermes Agent** 是由 Nous Research 开发的**自进化 AI Agent 框架**，核心差异化特征：

| 维度 | 传统 Agent | Hermes Agent |
|------|-----------|--------------|
| 记忆 | 仅上下文窗口 | **三层持久化记忆**（用户/会话/技能） |
| 技能 | 硬编码/一次性 | **运行时可学习、可版本化、可分发** |
| 身份 | Prompt 注入 | **SOUL.md 人格文件**（系统提示词第 1 槽位） |
| 部署 | 单进程 | **多 Profile 隔离 + Gateway 多平台接入** |
| 自动化 | 外部调度 | **原生 Cron + 无 Agent 模式 + 唤醒网关** |

**核心价值主张**：「Agent 越用越聪明」——每一次任务轨迹都可沉淀为可复用技能，下次执行自动调用，形成复利。

---

## 模块速览

| 模块 | 主题 | 时长 | 核心产出 |
|------|------|------|----------|
| **01** | Installation, Setup & Basic Commands | ~25 min | 完成 `hermes setup` / `hermes model` / `hermes doctor`；掌握 ~20 个日常 CLI/Slash 命令；理解 `~/.hermes/` 目录结构 |
| **02** | Deployment Options & Messaging | ~30 min | 配置 Telegram / Discord / Slack / WhatsApp 网关；Bot Token / Allowlist / Webhook；`hermes gateway setup` 与 `hermes gateway status` |
| **03** | Memory, Plugins & SOUL.md | ~35 min | 三层记忆架构（User/Session/Skill）；`SOUL.md` 人格编写；插件/主题/宠物/桌面插件加载；Profile 隔离 |
| **04** | Plugins & MCP Servers | ~30 min | 原生 MCP 客户端；OAuth vs 长期 Token；`hermes mcp add/catalog`；工具集过滤与安全集 |
| **05** | Honcho — Multi-Agent Orchestration | ~35 min | 中枢院 + 尚书局双脑模型；`delegate_task` 并行子代理；工作流编排；Context 传递与结果聚合 |
| **06** | Obsidian Integration & Models | ~30 min | Obsidian Vault 双向同步；本地模型（Ollama）与云端路由；`hermes model` 切换 Provider；Context 长度策略 |
| **07** | Cron & Automation | ~23 min | 4 种调度方式（Cron / Interval / One-shot / Webhook）；`no_agent` 省电模式；唤醒网关；Delivery 目标（origin/local/telegram） |
| **08** | Gateway Deep-Dive & Bot Mode | ~30 min | 多 Bot 共存；Bot 间消息转发；会话恢复（`hermes --continue` / `--resume`）；安全审计日志 |
| **09** | Desktop App, TUI & Profile Builder | ~25 min | Electron 桌面端（Cmd+K / 拖拽文件 / 原生通知）；Ink TUI 与 Widget；Web Dashboard (`:9119`) Profile 可视化构建 |
| **10** | Production Hardening & Advanced Patterns | ~35 min | Curator 技能治理（Pin / Archive / Consolidate）；GEPA 离线验证；权重训练管线；团队技能分发（`hermes skills tap/add/install`） |

---

## 核心概念与架构

### 1. 三层记忆架构
```
┌─────────────────────────────────────┐
│  User Memory  (~/.hermes/USER.md)    │  ← 跨会话、跨 Profile 的用户画像
├─────────────────────────────────────┤
│  Session Memory (state.db + FTS5)    │  ← 单会话上下文、工具调用轨迹
├─────────────────────────────────────┤
│  Skill Memory   (skills/ 目录)       │  ← 程序化记忆，可版本化、可分发
└─────────────────────────────────────┘
```

### 2. SOUL.md — 身份锚点
- **位置**：`~/.hermes/SOUL.md`（默认）或 `~/.hermes/profiles/<name>/SOUL.md`
- **槽位**：系统提示词 **第 1 位**，优先于 Memory 与 Skills
- **作用**：定义 Agent 的人格、说话风格、工作原则、边界条件
- **示例**：
```markdown
# SOUL.md
You are a pragmatic senior engineer with strong taste.
You optimize for truth, clarity, and usefulness over politeness theater.
```

### 3. 技能系统
- **存放**：`~/.hermes/skills/`（用户级）+ 打包技能（`autonomous-ai-agents`、`creative`、`productivity` 等）
- **生命周期**：`skill_manage create/patch/delete` → Curator 自动评分/合并/归档
- **加载机制**：按需触发（任务关键词匹配）+ 显式 `skill_view` 调用
- **分发**：`hermes skills tap add <repo>` + `hermes skills install <repo>/<skill>`

### 4. Gateway 多平台网关
```
用户消息 → Telegram/Discord/Slack/... → Gateway (FastAPI) → Hermes Core → 工具执行 → 回复
```
- 同一 Agent 核心驱动 CLI / TUI / Desktop / Web Dashboard / ACP (IDE) / OpenAI-compatible Proxy
- Bot 模式：多 Bot 共存，各自独立 `SOUL.md` + Profile

### 5. Honcho 双脑编排
| 角色 | 负责 | 对应 Hermes 概念 |
|------|------|------------------|
| **中枢院** | 决策、规划、任务分解 | 主会话（`delegate_task` 父进程） |
| **尚书局** | 执行、交付、工具调用 | 子代理（`delegate_task` 子进程） |

---

## 关键工具链与配置点

### CLI 核心命令速查
```bash
# 初始化与健康检查
hermes setup              # 交互式向导（Provider / Tools / Backend）
hermes model              # 选模型、切 Provider、配自定义端点
hermes doctor             # 环境自检（Python / 依赖 / 网络 / 配置）

# 技能管理
hermes skills browse      # 浏览官方/社区技能
hermes skills install <name>
hermes skills tap add <repo>   # 添加私有技能源
hermes skill_manage ...   # 底层 CRUD（同 skill_manage tool）

# 网关与 Bot
hermes gateway setup      # 连接 Telegram/Discord/Slack...
hermes gateway status     # 查看连接状态、活跃 Bot
hermes gateway logs       # 实时日志

# 定时任务
hermes cron create "0 9 * * 6" "check_tavily_credits" --delivery telegram
hermes cron list

# 会话控制
hermes --continue         # 接续最近会话
hermes --resume <session_id>  # 接续指定会话
hermes sessions list

# 桌面/界面
hermes desktop            # Electron App
hermes --tui              # Ink TUI
hermes dashboard          # Web Dashboard (:9119)
hermes proxy              # OpenAI-compatible 本地代理
```

### 配置文件关键路径
| 文件 | 说明 | 修改方式 |
|------|------|----------|
| `~/.hermes/config.yaml` | 主配置（非密钥） | **仅用 `hermes config set KEY VAL`** |
| `~/.hermes/.env` | API Keys / Secrets | 手动编辑或 `hermes config set --secret` |
| `~/.hermes/auth.json` | OAuth Tokens / Credential Pools | 自动管理，勿手动改 |
| `~/.hermes/state.db` | SQLite + FTS5 会话存储 | 只读查询，`hermes sessions export` 导出 |

### Profile 隔离
```bash
# 创建独立人格
mkdir -p ~/.hermes/profiles/designer
cp ~/.hermes/SOUL.md ~/.hermes/profiles/designer/SOUL.md
# 编辑 designer/SOUL.md 赋予设计师人格

# 启动指定 Profile
HERMES_HOME=~/.hermes/profiles/designer hermes
# 或配置 config.yaml: profile: designer
```

---

## 实操最佳实践

### 1. 技能编写“三步法”
1. **先跑通最短路径**：用 `terminal` / `execute_code` 手工完成一次
2. **抽象为 Skill**：`skill_manage create` 写入 `SKILL.md` + 参考文档/模板/脚本
3. **验证可复用**：换个会话 `skill_view` 加载，实测无报错

### 2. 记忆写入原则
- ✅ **写入**：用户偏好、纠错、环境常量、架构决策、身份锚点
- ❌ **不写**：任务进度、临时状态、一次性查询结果、易变数据

### 3. Cron 任务四要素
```yaml
# 正确示例
schedule: "0 9 * * 6"           # 每周六 09:00
command: "~/scripts/check_xxx.sh"
delivery: "telegram"            # origin/local/telegram/platform:chat_id
notify: true                    # 完成即通知
```
- **避坑**：`background=true` + `notify=true` 配合；**禁用** `heartbeat` 除非真需中途汇报

### 4. 多 Agent 协作模版
```python
# 父代理（中枢院）
delegate_task([
  {"goal": "Backend API", "context": "OpenAPI spec at ...", "output_schema": {...}},
  {"goal": "Frontend Dashboard", "context": "Same spec, React + Tailwind", "output_schema": {...}}
])
# 子代理并行执行，父代理聚合结果
```

### 5. 模型路由策略
| 场景 | 推荐配置 |
|------|----------|
| 主会话推理 | `openrouter/gpt-5.2` / `anthropic/claude-3.5-sonnet` |
| 代码子会话 | `openrouter/gpt-5.3-codex` / `deepseek/deepseek-coder` |
| 本地离线 | `ollama/qwen2.5-coder:32b`（`hermes model` 切换） |
| 成本敏感 | `openrouter/free` + `no_agent` 模式 |

---

## 常见坑点与避坑指南

| 症状 | 根因 | 解决 |
|------|------|------|
| `hermes setup` 卡在 Provider 选择 | 网络不通或 API Key 无效 | 先 `hermes doctor`，检查 `.env` 与 `config.yaml` |
| Gateway 启动但收不到消息 | Bot Token / Allowlist / Webhook URL 错误 | `hermes gateway setup` 重跑，核对 `hermes gateway status` |
| `hermes --continue` 找不到会话 | 切了 Profile 或会话未保存 | `hermes sessions list` 确认 Profile 与 Session ID |
| 技能加载 `[SKILL_PRUNED]` | 上下文压缩丢失技能体 | `skill_view(name='xxx')` 重新加载即可 |
| `delegate_task` 报 "capped at N" | 并发子代理数触发三大限流路径之一 | 见 `references/delegate-task-concurrency-diagnosis.md` |
| Vault 保存登录失败（headless） | 无法弹出交互式密码管理器 | 引导用户手动完成 OAuth 一次，或用 `browser_vault_save_login` |
| Windows 路径/编码问题 | BOM / `\r\n` / WinError 10106 | 见 `references/windows-quirks.md`，建议 WSL2 |
| 技能冲突/版本漂移 | Curator 自动合并覆盖了业务关键技能 | `skill_manage patch` 加 `pin: true` 或手动 Pin |

---

## 进阶扩展方向

### 1. 团队技能库
```bash
# 组织私有技能仓库
git init hermes-skills-org
# 目录结构：skills/<category>/<skill-name>/SKILL.md + refs/
hermes skills tap add git@github.com:org/hermes-skills-org.git
hermes skills install org/hermes-skills-org/skills/devops/git-workflows
```

### 2. GEPA 离线验证
- 技能发布前跑 `hermes gepa validate <skill>`（模拟执行 + 断言检查）
- CI 集成：PR 必须通过 GEPA 才能合入技能库

### 3. 权重训练管线（实验性）
- 收集高质量轨迹 → 微调 LoRA → 部署为自定义模型端点 → `hermes model` 指向
- 适合：固定领域、高重复、极致成本控制

### 4. 多租户 SaaS 化
- 每租户一个 Profile + 独立 `SOUL.md` + 独立 Gateway Bot
- 共享技能库 + 隔离记忆 + 统一计费/审计

---

## 资源链接汇总

| 资源 | 链接 |
|------|------|
| **播放列表** | https://www.youtube.com/playlist?list=PLmpUb_PWAkDx-VWjh00tVCji794xAa_IX |
| **Hermes Atlas 导航站** | https://hermesatlas.com/masterclass |
| **官方文档** | https://hermes-agent.nousresearch.com/docs |
| **LLMs.txt 全文索引** | https://hermes-agent.nousresearch.com/docs/llms.txt |
| **GitHub 仓库** | https://github.com/NousResearch/hermes-agent |
| **Medium 完整教程** | https://medium.com/towardsdev/hermes-agent-masterclass-full-tutorial-9f682bb28789 |
| **Daily Dose of DS 深度解读** | https://www.dailydoseofds.com/p/hermes-agent-masterclass |
| **快速入门页** | https://hermes-agent.nousresearch.com/docs/getting-started/quickstart |

---

## 附：本报告使用建议

1. **新手**：按模块 01→10 顺序观看，边看边在本机跑通每个 `hermes` 命令
2. **已上手**：重点看模块 03/05/07/10（记忆/多代理/自动化/治理）——这是 Hermes 与众不同的核心护城河
3. **团队落地**：建立私有技能仓库 → 制定 `SOUL.md` 规范 → 接入 CI/GEPA → 推广 Profile 模版
4. **持续跟进**：订阅 Hermes Atlas / 官方 Discord / GitHub Releases，版本迭代快（月级），技能生态持续扩展

---

> **生成说明**：本报告基于公开播放列表标题、视频描述、Hermes Atlas 站点字段笔记、Medium 全文教程综合整理。因视频字幕未直接获取，细节时间戳以搜索片段为准，建议配合原视频观看。如需某模块深度逐字稿，可单独提供视频 ID 由 `youtube-content` 技能抓取转写。

---

**报告版本**：v1.0  
**维护者**：智妍（朴智妍）  
**更新策略**：Masterclass 更新时同步修订，或按需追加模块笔记