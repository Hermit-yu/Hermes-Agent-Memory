# EchoDB Fusion (配置融合区)

宝贝，这个目录专门用来**引入别人配置/脚本并与我们自己的配置融合**，目的是：
- 保持 EchoDB 干净
- 可回滚、可审计
- 一次只合并一个模块，避免“配置垃圾场”

## 目录约定

- `upstream/`：第三方原版（只读备份，不在这里直接改）
- `ours/`：我们自己的稳定版（作为基线）
- `merged/`：融合后的最终版本（真正准备落地生效的）
- `notes/`：融合记录（来源、版本、冲突点、取舍理由、风险）
- `templates/`：清单/记录模板

## 使用流程（建议）

1) 把第三方配置快照放进 `upstream/<source>/`（并记录 commit、文件清单、LICENSE 信息）
2) 把我们的对应配置放进 `ours/<module>/`
3) 在 `notes/` 追加融合记录（来源、差异、风险、下一步）
4) 产物输出到 `merged/<module>/`，跑验证后再考虑迁入正式目录

### 当前示例

- 上游快照：`upstream/memory-lancedb-pro/`
- 我方映射：`ours/memory-engine/UPSTREAM_FEATURE_MAP.md`
- 我方任务分解：`ours/memory-engine/INTEGRATION_BACKLOG.md`
- 记录日志：`notes/memory-engine/merge-checklist-INIT.md`

### 新增融合（edict）

- 上游快照：`upstream/edict/`（README/README_EN/LICENSE/清单/元信息）
- 我方治理设计：`ours/edict-governance/`（含 roles SOUL 体系、DAILY_OPERATION_GUIDE）
- 可执行融合产物：`merged/edict-governance/`（POLICY_EFFECTIVE / APPROVAL_MATRIX / AUDIT_SCHEMA / RUNBOOK / ROLLBACK_PLAYBOOK）
- 本轮记录：
  - `notes/edict-integration-round1.md`
  - `notes/edict-integration-round2-completion.md`

> 备注：原则上不把运行态目录（logs/state/runtime）塞进来。
