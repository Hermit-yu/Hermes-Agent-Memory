# EchoDB 仓库结构说明（中文）

宝贝，这份文件用来保证仓库越长越大也不会乱。

## 1) 真相源（你写的内容，最重要）

- `SOUL.md`
  - 人格与行为脊梁（evolving spine）
- `USER.md` / `TOOLS.md`
  - 你的偏好 & 本地工具笔记
- `memory-echoDB/`
  - 记忆数据库（文件型真相源 + 可再生索引）
  - `long-term/`
    - 长期精炼记忆（如 `MEMORY.md`）
  - `daily/`
    - 每日记忆日志（原始记录）
  - `schema/`
    - 记忆数据模型/作用域约定（给未来索引/检索一致口径）
  - `indexes/`
    - 可再生索引（默认不进 Git，仅保留目录）

## 2) 融合区（防止 EchoDB 变垃圾场）

- `echodb-fusion/`
  - 专门用来引入第三方配置/脚本，并进行“可审计融合”
  - `upstream/`：第三方原版只读快照（示例：`upstream/memory-lancedb-pro/`，含 README/README_CN/plugin 清单与 LICENSE 记录）
  - `ours/`：我们自己的设计与实现（示例：`ours/memory-engine/UPSTREAM_FEATURE_MAP.md`、`INTEGRATION_BACKLOG.md`）
  - `merged/`：融合后的可落地版本（准备迁入正式目录时使用）
  - `notes/`：每次融合记录（来源/差异/取舍/风险/验证）
  - `templates/`：融合清单模板

## 3) 自动化脚本

- `automation/`
  - 放自动化脚本（同步、构建索引、治理执行等）
  - `automation/echodb/sync.ps1`：双边同步（pull--rebase → commit → push）
  - `automation/edict/preflight-check.ps1`：执行前风险判定（allow/deny）
  - `automation/edict/audit-log.ps1`：审计日志追加（JSONL）
  - `automation/edict/simulate-flow.ps1`：三类流程模拟（外发/批改/cron）

## 4) edict 治理融合（新增）

- `echodb-fusion/ours/edict-governance/roles/`
  - 三省六部+都察院角色 SOUL（共 9 份）
- `echodb-fusion/merged/edict-governance/`
  - 可执行治理包（策略、审批矩阵、审计结构、runbook、回滚手册）
- `echodb-fusion/notes/edict-integration-round2-completion.md`
  - round2 差异、风险、后续路线

> 原则：运行态日志/大文件（logs/state/runtime/音频）默认忽略，不进入 EchoDB。
