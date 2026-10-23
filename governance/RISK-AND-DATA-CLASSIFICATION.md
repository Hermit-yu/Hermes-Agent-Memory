# RISK-AND-DATA-CLASSIFICATION.md — 风险等级与数据分级权威定义

> 状态：Active
> 生效：2026-10-05
> 权威仓库：`Hermit-yu/Hermes-Agent-Memory`
> 单一权威声明：**风险等级（L0–L3）与数据分级（D0–D3）的完整定义只在本文件维护。** `ziyan-governance`、`personal-agent-collaboration`、MEMORY 摘要、项目文档等位置只允许**引用**本文件或保留一句话摘要，**不得复制完整表格**。

---

## 1. 风险等级 / Risk levels (L0–L3)

| 等级 | 典型操作 / Examples | 授权要求 / Authorization | 所需证据 / Evidence |
|---|---|---|---|
| **L0** | 纯对话、解释、只读查询、状态检查 / Q&A, explanation, read-only queries, status checks | 无需批准 / No approval needed | 命令与输出摘要 / Command and output summary |
| **L1** | 工作区内可回滚改动、草稿、本地测试 / Reversible in-workspace changes, drafts, local tests | 由任务级单次授权覆盖 / Covered by the single task-level authorization | 前后对比 diff / Before/after diff |
| **L2** | 对外可见但可回滚的改动、重启服务、升级依赖、仓库写入 / Externally visible but rollback-capable changes, service restarts, dependency upgrades, repo writes | 在任务授权内执行，**且**必须有经验证的回收路径 / Under task authorization **and** only with a tested rollback path | 回滚演练结果 / Rollback drill result |
| **L3** | 不可逆生产变更、破坏性删除、凭据或安全策略变更、付款、公开发布、敏感数据披露 / Irreversible production changes, destructive deletion, credential or security-policy changes, payment, public release, sensitive-data disclosure | **逐项单独二次确认**，不得批量授权 / **Separate second confirmation, one item at a time** — no batch authorization | 用户逐字确认 / Verbatim user confirmation |

**执行规则 / Operational rules**

1. 风险等级**不因**角色切换、同伴离线或时间压力而下调（不变量 I1）。
2. 双脑处于 **UNKNOWN** 状态时，风险等级**上调一级**（L1→L2 时需用户确认），并采用更保守路径。
3. 等级升级等同于**范围扩大**：立即停止，重新声明范围并重新取得授权。
4. 不得为了让流程顺畅而启用永久免审批模式；硬性安全阻断与凭据脱敏始终保留。

---

## 2. 数据分级 / Data classification (D0–D3)

| 等级 | 内容 / Content | 处理规则 / Handling rule |
|---|---|---|
| **D0** | 公开信息 / Public information | 可自由引用 / May be quoted freely |
| **D1** | 内部信息（本地路径、项目结构、非敏感配置名）/ Internal (local paths, project structure, non-sensitive config names) | 可引用；不主动外发 / May be quoted; do not proactively send outward |
| **D2** | 敏感信息（配置内容、token 片段、内部地址、个人数据）/ Sensitive (config contents, token fragments, internal addresses, personal data) | 脱敏后引用；跨智能体传递时最小化字段 / Quote only after redaction; minimize fields when crossing to another brain |
| **D3** | 机密（私钥、密码、一次性验证码、支付凭据、完整凭据、CVC）/ Secret (private keys, passwords, one-time codes, payment credentials, full credentials, CVC) | ⛔ **禁止**出现在对话正文、日志、记忆、交接包、提交信息和跨智能体载荷中；只用变量名或占位符（如 `sk-***`），在目标环境本地解析 / ⛔ **Forbidden** in conversation text, logs, memory, handoff packages, commit messages, and cross-brain payloads; use only variable names or placeholders, resolved locally in the target environment |

### 2.1 外发前脱敏自检 / Pre-outbound redaction self-check

- **触发 / Trigger**：写入输出、日志、交接包、提交信息或记忆之前。
- **动作 / Action**：扫描 D3 明文与未脱敏的 D2 片段；命中即替换为占位符。
- **证据 / Evidence**：自检结论；若已发生泄漏，立即停止一切出站动作、告知用户，并建议轮换该凭据。

---

## 3. 引用方式 / How to reference this file

| 位置 / Location | 允许的做法 / What is allowed |
|---|---|
| `ziyan-governance` | 在「定义风险等级」步骤**引用**本文件（路径 + 等级名），不复制表格 |
| `personal-agent-collaboration` | 在授权与数据分类章节**引用**本文件，不复制表格 |
| MEMORY | 最多保留一句摘要 |
| 项目文档 | 可引用等级名与本文件路径；需要完整定义时链接本文件 |

发现任何位置出现重复的完整定义时，**必须收敛到本文件**，其他位置改为引用。

---

## 4. 变更流程 / Change process

本文件属于长期规则，修改走 `governance/SOURCE-OF-TRUTH.md` 的变更流程：用户确认 → 备份 → 小批次修改 → 检查冲突与敏感信息 → 验证引用一致 → 提交并同步仓库 → 报告证据与回滚方式。
