# EchoDB Memory Engine 融合规划（不改变现有习惯版）

目标：在**不改变当前文件型记忆习惯**（`memory-echoDB/daily` + `memory-echoDB/long-term`）的前提下，逐步引入 `memory-lancedb-pro` 的可学习架构：
- Hybrid Retrieval（Vector + BM25）
- Rerank（Cross-Encoder，可选）
- Multi-scope isolation（global/agent/project/user）
- Noise filtering + Adaptive retrieval
- 可运维 CLI（list/search/stats/forget/export/reindex）

同时强约束：
- EchoDB 不变成垃圾场（目录分层、来源可追溯、可回滚）
- 全流程**双边同步**：每次操作都 `pull --rebase` → 变更 → commit → push

---

## 0) 当前基线（必须保持）

**真相源（Source of Truth）**：
- `memory-echoDB/daily/`：每日原始日志
- `memory-echoDB/long-term/MEMORY.md`：长期精炼记忆

原则：任何“数据库/索引/检索优化”都是可再生的衍生产物，不反向污染真相源。

---

## 1) 目录与职责（防乱核心）

- `echodb-fusion/upstream/memory-lancedb-pro/`：第三方原版参考（只读备份，不直接改）
- `echodb-fusion/ours/memory-engine/`：我们的设计文档 + 脚手架 + 自动化脚本
- `echodb-fusion/merged/memory-engine/`：融合后的可落地版本（准备上生产时才放这里）
- `echodb-fusion/notes/memory-engine/`：每次融合记录（来源、差异、风险、验证）

- `memory-echoDB/indexes/`：本地数据库/索引存放处（可再生、可删除、可重建）
- `memory-echoDB/schema/`：记忆数据模型/作用域约定

---

## 2) 分阶段路线图（一步一步自动化迁移）

### Phase A — 只搭骨架，不引入重依赖（1-2 次提交）
产出：
1. `memory-echoDB/schema/`：定义 MemoryItem 结构、scope 规则（最小版）
2. `memory-echoDB/indexes/.gitkeep` + 说明：索引可再生
3. `automation/echodb/sync.ps1`：标准化双边同步脚本（pull→commit→push）
4. `automation/echodb/build-index.ps1`：空壳（占位），先能跑通参数与日志

验证：
- 不影响现有 `daily/` 写入与 `MEMORY.md` 维护
- 仓库结构清晰，没有新增大文件/运行态垃圾

### Phase B — 建立“离线索引”最小可用版本（MVP）（2-4 次提交）
目标：先实现**可用**检索，不追求最强。

实现顺序（推荐）：
1) 文本索引：BM25（可用 SQLite FTS5 或纯 JS/Python 简化版）
2) 向量索引：可选（等 embedding key/检索链路稳定再上）
3) 简单融合：先并集 + 简单加权，再逐步进化到 RRF

验证：
- 给定 query，能返回 5-10 条候选记忆
- 支持 scope 过滤（至少 global + agent + project）

### Phase C — 引入“检索治理”（3-6 次提交）
1) Adaptive Retrieval：不该搜的就跳过（寒暄/表情/确认句）
2) Noise Filter：不该存的不入库（重复、空洞、系统提示、心跳等）
3) Recency/Decay/LengthNorm/MMR：逐项引入，逐项开关

验证：
- 结果更干净、重复更少、相关性更稳

### Phase D — 形成 CLI 与可运维流程（持续）
- `echodb memory search|list|stats|forget|export|reindex`
- 备份与回滚：index 可重建；真相源不动

---

## 3) 自动化执行规则（严格双边同步）

所有自动化脚本统一遵守：
1) `git pull --rebase`
2) 执行变更
3) `git status` 检查
4) `git commit -m "chore: ..."`
5) `git push`

若遇到冲突：停止并输出冲突文件/区段，等待你选择。

---

## 4) 风险边界（你最在乎的我也最在乎）

- 不上传敏感信息（token/key/个人隐私）
- 不上传运行态目录（logs/state/runtime）
- 大文件一律忽略（音频/视频/压缩包）
- 第三方内容必须记录来源与 license

---

## 下一步（现在就做）

我将立刻执行 Phase A：
- 建 `schema/`、`indexes/`
- 加入 `automation/echodb/sync.ps1`
- 写一份融合记录模板（notes）

你不用改任何习惯，仍然照旧写 daily 和 MEMORY.md。
