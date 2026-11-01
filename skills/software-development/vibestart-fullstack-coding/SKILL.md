---
name: vibestart-fullstack-coding
description: "Use when building a full-stack TypeScript project."
version: 1.0.0
author: Zhiyan (Hermes agent)
license: MIT
metadata:
  hermes:
    tags: [fullstack, typescript, vibestart, viteplus, hono, orpc, drizzle, coding-workflow]
    related_skills: [engineering-framework, test-driven-development, service-e2e-shell]
---

# Skill: Vibestart Full-Stack Coding (专为我编码而生)

深度通读 vibestart 官方文档 (vibestart.net/docs, 24 页 × 中英双版全量) 后沉淀的编码工作流。核心信条来自官方 **why** 页: **好代码生好代码** — agent 在规约清晰、类型端到端、秒级报错的代码库里写代码, 质量会随规模上升而不是腐烂。本 skill 就是我 (agent) 在全栈项目里编码的完整纪律, 也是官方 agent skill 的自研超集 (环境事实+踩坑+验收清单已本机实装验证)。

## When to use

- 哥哥要我新建一个全栈应用 / API 服务 / 桌面应用 / 移动端应用 (或维护已有 vibestart 项目)
- 需要带鉴权 (Better Auth)、数据库 (Drizzle+SQLite/Postgres/MySQL/Mongo)、端到端测试的 TS 项目
- 维护任务: 加能力 (Knip/Ultracite/Docker/Void)、模板升级、项目体检

## 环境事实 (本机已实装验证, 2026-10-26)

| 项 | 值 |
|---|---|
| Node | `/root/.hermes/tools/node-26.7.0-linux-x64/bin` (v26.7.0, vp 自带 v24 runtime) |
| pnpm | 同目录 (vp 依赖); 无 bun |
| docker | /usr/bin/docker (Postgres/MySQL/Mongo 组合才需要) |
| 全栈工具箱 (Vite+/vp) | 已装: `/root/.local/share/vite-plus/bin/vp`; 每 shell 先 `. /root/.config/vite-plus/env` 或 `export PATH=$HOME/.local/share/vite-plus/bin:$PATH` |
| vibestart-cli | `npx -y vibestart-cli` (0.1.2), 无需全局安装 |
| 官方 agent skill | `npx skills add VinkyDev/vibestart --skill vibestart` (项目级; 需要完整教程时再装) |

安装全栈工具箱 Vite+ 工具链 (只需一次): `curl -fsSL https://vite.plus | VP_NODE_MANAGER=no bash`。

## 编码工作流 (5 步, 全绿才收工)

1. **选栈** — 按应用类型定组合 (决策表见下), 冲突时 CLI 会解释并给最小修复。可用 `npx vibestart-cli --list --json` 拉全部合法组合。
2. **生成** — `npx vibestart-cli <dir> --framework X --backend Y --api Z --database D --auth A --no-interactive --json` (非交互, 永远带 `--json` 读结果)。生成物 = 应用代码 + 测试 + `AGENTS.md` 规约 + `vibestart.jsonc` 配方, 无运行时对 vibestart 的依赖。
3. **读 AGENTS.md 再动手** — 这是项目写给 agent 的指令文件: 每类改动落在哪个目录、需要哪些测试、何时算完成。编码前必读, 改动后照它验收。目录职责 (以 Hono+oRPC+SQLite 为例):
   - 页面/路由 → `apps/web/src/routes/` (登录态页面在 `_authenticated/`)
   - API 操作 → `packages/api/src/routers/` (在 `packages/api/src/index.ts` 注册)
   - 表 → `packages/db/src/schema/` + 生成 migration
   - 服务器配置 → `apps/server/src/env.ts` + README Environment 节
   - 共享组件 → `packages/ui`; 测试 → `apps/web/tests/e2e/` 或 `packages/api/tests/integration/`
4. **贯穿所有层做改动 (数据往外走)** — 加字段的标准顺序: ① schema 加列 (TS only) → ② `vp run db:generate` 生成 migration, **先读 SQL 再提交** → ③ `vp run db:migrate` 应用到本地 → ④ API 接受新字段 (Zod 校验) → ⑤ 页面加字段 (类型检查器自动报错) → ⑥ 钉行为测试 → ⑦ `vp run ready` 全绿。每步靠上一步的类型, 错了秒级报出。
5. **质量门** — 提交前 `vp run ready` 必须全绿 (格式+lint+类型+单测+集成测+e2e+生产构建)。迭代中跑最窄检查 (`vp check` / `vp test <file>`), 收工前跑全门。

## 选栈决策表 (官方 by-kind)

| 在做什么 | 组合 | 原因 |
|---|---|---|
| 内部工具 / dashboard | `spa` + `hono` + `orpc` + `sqlite` | 好部署, 类型化 API, 无独立数据库服务 |
| 页面要可被搜索 | `next` 或 `tanstack-start` | SSR, 内容随首个响应到达 |
| 给别的客户端用的 API | `--frontend none` + `hono` + `openapi` | 标准 REST + 自动文档 |
| 桌面应用 | `spa` + `--desktop electron` | Electron 包 SPA 成桌面窗口 |
| iOS/Android | `--mobile expo` (+ hono+sqlite 做账号) | 独立或旁挂 web+server |
| 多并发写 | `--database postgres` | 独立数据库服务扛并发 |

**兼容性硬规则**: Electron 要求 SPA (不能配 Next); 框架自托管 server 要求 Next/TanStack Start; OpenAPI 要求 Hono; Docker 要求有 web 或 server; Bun runtime 仅适用 Hono。`--package-manager` 与 `--runtime` 相互独立 (Bun 装包 + Node 跑 Hono 也合法)。

## 命令速查

| 任务 | 命令 |
|---|---|
| 交互建项目 | `npx vibestart-cli` (无 flag 时逐步询问, 每步只列兼容选项) |
| 预览将写哪些文件 | `npx vibestart-cli <dir> --dry-run` |
| 全量合法组合 | `npx vibestart-cli --list` (`--json` 给脚本) |
| 配方复用 | `npx vibestart-cli new --recipe <dir|file|url>` (flags 覆盖 recipe) |
| 启动应用 | `vp run dev` (移动端另开终端 `vp run dev:mobile`) |
| 生成/应用 migration | `vp run db:generate` / `vp run db:migrate` |
| 格式+lint+类型 | `vp check` (自动修复 `vp check --fix`) |
| 单测+集成测 | `vp test` (单文件 `vp test <path>`; `--project unit|integration` 过滤) |
| 浏览器 e2e | `vp run test:e2e` |
| 收工全门 | `vp run ready` |
| 加能力 | `npx vibestart-cli add knip ultracite docker --dry-run` 预览, `--yes` 应用 |
| 体检 (只读) | `npx vibestart-cli doctor --offline --json` |
| 模板升级 | `npx vibestart-cli upgrade --check / --dry-run / --yes` (写操作需干净 git worktree; 冲突写进文件 marker; `git restore . && git clean -fd` 可撤销) |

## 测试三层纪律 (测试要挣得其所)

- **e2e** (Playwright 或 TesterArmy e2e): 真浏览器走完整用户旅程 (注册→建 todo→刷新还在)。判定产品是否 work。
- **integration**: 走真实 API 校验+鉴权+真实数据库, 每个操作测输入/输出/错误码/权限。每个受保护操作**必须用匿名调用 + 另一个已登录用户测两边** (防越权泄漏)。
- **unit**: 只给有真实分支的逻辑 (计价/权限规则/状态机/解析器)。不批量造 mock 型单测 — 那是 AI 时代最大的测试反模式。

原则: 用真的 (真库真浏览器); 修 bug 前先写一个失败的复现测试; 测行为不测实现 (重构后仍过)。

## 坑 (本机实测踩过, 全部已验证)

1. **Playwright 浏览器要在 `apps/web` 子目录装**: 项目根 `vp exec playwright install chromium` 报 `Command 'playwright' not found`; `cd apps/web && vp exec playwright install chromium` 才成功。第一次 e2e 前先装。
2. **`vp` 不在默认 PATH**: 每个新 shell 先 `. /root/.config/vite-plus/env` 或手动加 `export PATH=$HOME/.local/share/vite-plus/bin:$PATH` (实际装点在 `~/.local/share/vite-plus/bin`)。
3. **viteplus 安装器会交互问 Node 管理**: 带 `VP_NODE_MANAGER=no` 跑, 否则 CI/非 tty 挂起。
4. **`vp <cmd>` vs `vp run <cmd>` 是两回事**: 前者是 Vite+ 内置命令 (check/test/fmt), 后者是项目脚本/task。混淆会报 command not found — 先看 `package.json` 和 `vite.config.ts`。
5. **跑脚本用 `vpx`**, 别引入 tsx/ts-node (AGENTS.md 明确禁止)。
6. **`.env` 含密钥永不进 git**: CLI 生成带随机 auth secret; 新 clone 按 README 示例重建, secret 用 `openssl rand -base64 32`。新增配置项写进 README, 不写真值。
7. **CLI JSON 错误码**: `illegal-stack` 带 `violations`+`fixes` (按 fixes 改 flags 重试); `incomplete-stack` 带 `open` (哪些 kind 没定); `directory-not-empty` / `invalid-recipe` / `step-failed` (带最后 40 行输出)。exit: 0 成功 / 1 失败 / 2 参数错 / 130 取消。`--json` 保证恰好一个 JSON 对象、永不 prompt。
8. **升级永不迁移数据库**: 生产数据备份+手动 migration 是自己的事; `vibestart.jsonc` 的 name/version 字段必须保持 CLI 原样 (它是升级三方合并的基准), 提交它。
9. **验证记录只覆盖生成瞬间**: 创建时 CLI 报的 "verified N days ago" 指纹匹配当前输出; 我改完代码后, 以我自己的 `vp run ready` 为准。

## 我作为 agent 交差时的验收清单 (官方 develop 页 agent 节)

agent (我) 报告完成时, 重点人工复核: ① **migrations** — 应用真实数据前读一遍生成的 SQL; ② **数据访问** — 每个读写用户数据的 API 操作都受保护且限定当前用户; ③ **测试** — 新行为必须配新测试, 被删/削弱的测试要反问而不是放行; ④ **最终检查** — `vp run ready` 我自己跑一遍 (或核对我贴的输出), 全绿才算 done。

## 参考

- 官方文档全文: `https://vibestart.net/docs` (24 页; 源在 github.com/VinkyDev/vibestart `apps/web/content/docs/`)
- 官方 agent skill (项目级安装): `npx skills add VinkyDev/vibestart --skill vibestart`
- 生成物规约: 每个项目的 `AGENTS.md` (随栈生成, 编码前必读)
